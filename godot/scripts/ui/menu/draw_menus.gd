extends RefCounted
const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")
const MenuModelScript = preload("res://scripts/ui/menu/MenuModel.gd")
## 1:1 canvas ports of HTML drawOutfits / drawEmblems / drawNgSelect / drawArsenal / drawLeaderboard.

var ctx
var model
var bobina
var combat_fx  # drawCombatFx for pose_params / pose props
var bobina_cache = null  # BobinaDrawCache Node (Phase 1)
var tick: int = 0
var W: float = 960.0
var H: float = 540.0
## Use texture cache for large previews (outfit stage ×4.7); live vector fallback if miss
const CACHE_SCALE_MIN := 2.0

func setup(c, m, bob = null, cache = null) -> void:
	ctx = c
	model = m
	bobina = bob
	bobina_cache = cache
	W = Config.W
	H = Config.H
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	combat_fx.setup(ctx)

func set_tick(t: int) -> void:
	tick = t
	if combat_fx and combat_fx.has_method("set_tick"):
		combat_fx.set_tick(t)

func _bg(c0: String, c1: String) -> void:
	MenuHelpers.fill_bg(ctx, c0, c1, W, H)

func _back_btn(label: String = "") -> Dictionary:
	var bw = 180.0
	var bh = 30.0
	var bx = 20.0
	var by = H - 42.0
	var b = {"x": bx, "y": by, "w": bw, "h": bh}
	ctx.fill_style("rgba(30,16,40,0.85)")
	ctx.begin_path()
	ctx.round_rect(bx, by, bw, bh, 8)
	ctx.fill()
	ctx.stroke_style("#8fd0ff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.text_align("center")
	var txt = label if label != "" else ("⌂ BACK  [" + MenuHelpers.kb("shoot") + "]")
	ctx.fill_text(txt, bx + bw / 2.0, by + 20.0)
	ctx.text_align("left")
	return b

func _draw_bobina_at(x: float, y: float, scale: float, outfit: String, extras: Dictionary = {}) -> void:
	var st = {
		"x": 0, "y": 0, "iframe": 0, "focus": false, "walk": 0, "bombFx": 0,
		"face": float(extras.get("face", -PI / 2.0)),
		"vx": float(extras.get("vx", 0)), "vy": float(extras.get("vy", 0)),
		"outfit": outfit, "tick": tick,
	}
	if extras.has("expr"):
		st["expr"] = extras["expr"]
	if extras.has("lean"):
		st["lean"] = extras["lean"]
	if extras.has("hold"):
		st["hold"] = extras["hold"]
	# Phase 1: large previews use BobinaDrawCache (full drawBobina bake)
	var pose_i := int(extras.get("pose", model.outfit_pose if model else 0))
	var expr = extras.get("expr", null)
	if bobina_cache and scale >= CACHE_SCALE_MIN and bobina_cache.has_method("get_texture"):
		var tex: Texture2D = bobina_cache.get_texture(outfit, expr, pose_i, tick, scale, st)
		if tex != null and ctx.has_method("draw_image"):
			var tw := float(tex.get_width())
			var th := float(tex.get_height())
			ctx.draw_image(tex, x - tw * 0.5, y - th * 0.5, tw, th)
			return
		# miss: fall through to live draw while bake queues
	if bobina == null:
		return
	ctx.save()
	ctx.translate(x, y)
	ctx.scale(scale, scale)
	if bobina.has_method("set_outfit"):
		bobina.set_outfit(outfit)
	if bobina.has_method("set_tick"):
		bobina.set_tick(tick)
	bobina.drawBobina(st)
	ctx.restore()

func _draw_posed_figure(cx: float, cy: float, scale: float, pose: int, outfit: String, expr_override = null) -> void:
	## HTML drawPosedFigure / drawOutfitFigure — full poseParams + drawBobina + pose prop
	var t := float(tick)
	var P := {"vx": 0.0, "vy": 0.0, "lean": 0.0, "expr": "smile", "rot": 0.0, "bounce": 0.0, "sway": 0.0, "sq": 1.0}
	if combat_fx and combat_fx.has_method("poseParams"):
		P = combat_fx.poseParams(pose, t)
	var expr = expr_override if expr_override != null else P.get("expr", "smile")
	var face := -PI / 2.0
	# Spin about body centre (HTML: 16px up along facing)
	var rr := face + PI / 2.0
	var pcx := -sin(rr) * 16.0
	var pcy := -16.0 + cos(rr) * 16.0
	var ms := 1.0
	var extras := {
		"vx": float(P.get("vx", 0)),
		"vy": float(P.get("vy", 0)),
		"lean": float(P.get("lean", 0)),
		"expr": expr,
		"face": face,
		"pose": pose,
	}
	if pose == 5 and combat_fx and combat_fx.has_method("coffeeHold"):
		extras["hold"] = combat_fx.coffeeHold(t)
	# Phase 1: bake full drawBobina at outer scale (outfit stage is ×4.7) — pose prop still live
	if bobina_cache and scale >= CACHE_SCALE_MIN and bobina_cache.has_method("get_texture"):
		var tex: Texture2D = bobina_cache.get_texture(outfit, expr, pose, tick, scale, extras)
		if tex != null and ctx.has_method("draw_image"):
			var tw := float(tex.get_width())
			var th := float(tex.get_height())
			ctx.save()
			ctx.translate(cx + float(P.get("sway", 0)) * ms, cy - float(P.get("bounce", 0)) * ms)
			var sq := float(P.get("sq", 1.0))
			if absf(sq - 1.0) > 0.001:
				ctx.scale(1.0, sq)
			# Approximate body-centre spin for texture blit
			var rot := float(P.get("rot", 0))
			if absf(rot) > 0.001:
				ctx.translate(0, -16.0 * scale)
				ctx.rotate(rot)
				ctx.translate(0, 16.0 * scale)
			ctx.draw_image(tex, -tw * 0.5, -th * 0.5, tw, th)
			ctx.scale(scale, scale)
			if combat_fx and combat_fx.has_method("drawPoseProp"):
				combat_fx.drawPoseProp(pose, t)
			ctx.restore()
			return
	ctx.save()
	ctx.translate(cx + float(P.get("sway", 0)) * ms, cy - float(P.get("bounce", 0)) * ms)
	ctx.scale(scale, scale * float(P.get("sq", 1.0)))
	ctx.translate(pcx, pcy)
	ctx.rotate(float(P.get("rot", 0)))
	ctx.translate(-pcx, -pcy)
	_draw_bobina_at(0, 0, 1.0, outfit, extras)
	if combat_fx and combat_fx.has_method("drawPoseProp"):
		combat_fx.drawPoseProp(pose, t)
	ctx.restore()

# ───────────────────────── OUTFITS ─────────────────────────
func drawOutfits() -> void:
	model.outfit_tiles.clear()
	model.outfit_pose_btn = null
	model.outfit_back_btn = null
	model.face_btn = null
	model.outfit_anim_t += 1
	_bg("#1a0e26", "#28121e")
	var unlocked_n = 0
	for o in DataRegistry.outfits:
		if ProgressStore.outfit_unlocked(str(o.get("key"))):
			unlocked_n += 1
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ff9ecb")
	ctx.shadow_blur(16)
	ctx.fill_style("#ffd6ea")
	ctx.font("900 32px Trebuchet MS")
	ctx.fill_text("👗 OUTFITS", W / 2.0, 40)
	ctx.restore()
	ctx.fill_style("#c8b0d0")
	ctx.font("12px monospace")
	ctx.fill_text("Wardrobe · %d / %d unlocked · tap a skin to equip · unlock more via 🏅 Emblems" % [unlocked_n, DataRegistry.outfits.size()], W / 2.0, 60)
	# preview stage (right) — HTML drawOutfits: gradient panel + clip + radial spotlight + ×4.7 figure
	var pvX = W - 330.0
	var pvY = 78.0
	var pvW = 310.0
	var pvH = H - 78.0 - 16.0
	var pg = ctx.create_linear_gradient(0, pvY, 0, pvY + pvH)
	pg.addColorStop(0, "#241033")
	pg.addColorStop(1, "#140a1c")
	ctx.fill_style(pg)
	ctx.begin_path()
	ctx.round_rect(pvX, pvY, pvW, pvH, 14)
	ctx.fill()
	ctx.stroke_style("rgba(255,150,205,0.45)")
	ctx.line_width(2)
	ctx.stroke()
	# HTML: clip figure + notes inside rounded stage
	ctx.save()
	ctx.begin_path()
	ctx.round_rect(pvX, pvY, pvW, pvH, 14)
	ctx.clip()
	var pcx = pvX + pvW / 2.0
	var t = float(tick)
	# spotlight cone (HTML radial gradient fill of cone poly)
	var spot = ctx.create_radial_gradient(pcx, pvY + 40.0, 10.0, pcx, pvY + 220.0, 220.0)
	spot.addColorStop(0, "rgba(255,190,235,0.26)")
	spot.addColorStop(1, "rgba(255,190,235,0)")
	ctx.fill_style(spot)
	ctx.begin_path()
	ctx.move_to(pcx - 40, pvY + 10)
	ctx.line_to(pcx + 40, pvY + 10)
	ctx.line_to(pcx + 150, pvY + pvH)
	ctx.line_to(pcx - 150, pvY + pvH)
	ctx.close_path()
	ctx.fill()
	# HTML fixed figScale=4.7 — outfit menu is the dual surface for wardrobe/pose/face
	var fig_cy = pvY + pvH * 0.47
	var fig_scale = 4.7
	var feet_y = fig_cy + fig_scale * 22.0
	ctx.fill_style("rgba(255,120,190,0.16)")
	ctx.begin_path()
	ctx.ellipse(pcx, feet_y, 90, 18, 0, 0, TAU)
	ctx.fill()
	var notes = ["♪", "♫", "♥", "✦", "♬"]
	var ncols = ["#ff9ecb", "#ffd27a", "#8fd0ff", "#b8f08a"]
	for i in range(8):
		var base = t * 0.7 + float(i) * 80.0
		var ny = pvY + 20.0 + fposmod(base, pvH - 70.0)
		var nx = pcx + sin(t * 0.03 + float(i) * 1.3) * (60.0 + float(i) * 9.0)
		ctx.global_alpha(0.45 + 0.3 * sin(t * 0.1 + float(i)))
		ctx.fill_style(ncols[i % 4])
		ctx.font("bold %dpx monospace" % (14 + (i % 3) * 4))
		ctx.text_align("center")
		ctx.fill_text(notes[i % 5], nx, ny)
	ctx.global_alpha(1.0)
	# HTML drawOutfitFigure → drawPosedFigure(pose, outfitPreview, VICTORY_FACES[face].expr)
	var pose_i = clampi(model.outfit_pose, 0, MenuHelpers.OUTFIT_POSES.size() - 1)
	var face_i = clampi(model.victory_face, 0, MenuHelpers.VICTORY_FACES.size() - 1)
	var expr = MenuHelpers.VICTORY_FACES[face_i].get("expr")
	_draw_posed_figure(pcx, fig_cy, fig_scale, pose_i, model.outfit_preview, expr)
	ctx.restore()  # end stage clip
	# labels (HTML draws these outside clip)
	var po_name = model.outfit_preview
	for o in DataRegistry.outfits:
		if str(o.get("key")) == model.outfit_preview:
			po_name = str(o.get("name", model.outfit_preview))
			break
	var p_unl = ProgressStore.outfit_unlocked(model.outfit_preview)
	ctx.text_align("center")
	ctx.fill_style("#fff")
	ctx.font("900 22px Trebuchet MS")
	ctx.fill_text(MenuHelpers.outfit_emoji(model.outfit_preview) + " " + po_name, pcx, pvY + 34)
	var equipped = model.outfit_preview == GameState.selected_outfit
	ctx.font("bold 12px monospace")
	ctx.fill_style("#8fd0a0" if equipped else ("#ffd27a" if p_unl else "#ff7a9a"))
	ctx.fill_text("✓ EQUIPPED" if equipped else ("tap tile to equip" if p_unl else "🔒 locked — earn its Emblem"), pcx, pvY + 52)
	# face / pose buttons
	var bw = 204.0
	var bh = 27.0
	var bx = pcx - bw / 2.0
	var byF = pvY + pvH - 77.0
	var byP = pvY + pvH - 42.0
	ctx.fill_style("#c8b0d0")
	ctx.font("9px monospace")
	ctx.fill_text("★ YOUR STAGE-CLEAR VICTORY POSE", pcx, byF - 7)
	model.face_btn = {"x": bx, "y": byF, "w": bw, "h": bh}
	ctx.fill_style("rgba(140,200,255,0.14)")
	ctx.begin_path()
	ctx.round_rect(bx, byF, bw, bh, 9)
	ctx.fill()
	ctx.stroke_style("#8fd0ff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#d8ecff")
	ctx.font("bold 12px Trebuchet MS")
	ctx.fill_text("☺ FACE:  " + str(MenuHelpers.VICTORY_FACES[face_i]["name"]), pcx, byF + 18)
	model.outfit_pose_btn = {"x": bx, "y": byP, "w": bw, "h": bh}
	ctx.fill_style("rgba(255,140,200,0.16)")
	ctx.begin_path()
	ctx.round_rect(bx, byP, bw, bh, 9)
	ctx.fill()
	ctx.stroke_style("#ff9ecb")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#ffd6ea")
	ctx.font("bold 12px Trebuchet MS")
	ctx.fill_text("↻ POSE:  " + str(MenuHelpers.OUTFIT_POSES[pose_i]["name"]), pcx, byP + 18)
	# grid left
	var cols = 4
	var gx = 20.0
	var gyTop = 80.0
	var gap = 8.0
	var gridW = W - 360.0
	var cellW = (gridW - float(cols - 1) * gap) / float(cols)
	var rows = int(ceili(float(DataRegistry.outfits.size()) / float(cols)))
	var botY = H - 52.0
	var cellH = minf(66.0, (botY - gyTop - float(rows - 1) * gap) / float(maxi(1, rows)))
	for i in range(DataRegistry.outfits.size()):
		var o: Dictionary = DataRegistry.outfits[i]
		var key = str(o.get("key"))
		var unl = ProgressStore.outfit_unlocked(key)
		var sel = key == GameState.selected_outfit
		var prev = key == model.outfit_preview
		var cx = gx + float(i % cols) * (cellW + gap)
		var cy = gyTop + float(i / cols) * (cellH + gap)
		ctx.fill_style("rgba(143,208,160,0.16)" if sel else ("rgba(255,255,255,0.04)" if unl else "rgba(255,255,255,0.02)"))
		ctx.begin_path()
		ctx.round_rect(cx, cy, cellW, cellH, 10)
		ctx.fill()
		ctx.stroke_style("#fff" if prev else ("rgba(143,208,160,0.7)" if sel else ("rgba(255,180,215,0.28)" if unl else "rgba(255,255,255,0.07)")))
		ctx.line_width(2.4 if prev else 1.3)
		ctx.stroke()
		ctx.text_align("left")
		# HTML: 24px serif for emoji / 🔒 — use Trebuchet+emoji fallbacks (serif chain lacks emoji)
		ctx.global_alpha(1.0 if unl else 0.4)
		ctx.font("24px \"Trebuchet MS\"")
		ctx.fill_text(MenuHelpers.outfit_emoji(key) if unl else "🔒", cx + 10, cy + cellH / 2.0 + 8)
		ctx.global_alpha(1.0)
		ctx.fill_style("#bff0cc" if sel else ("#f0dce8" if unl else "#8a7a92"))
		ctx.font("bold 12px Trebuchet MS")
		var tile_name := str(o.get("name", key))
		# HTML o.name.slice(0,13) — Cabal includes skull in name already when present
		ctx.fill_text(tile_name.substr(0, 13), cx + 42, cy + cellH / 2.0 - 2)
		ctx.fill_style("#8fd0a0" if sel else ("#a894b2" if unl else "#6a5a72"))
		ctx.font("9px monospace")
		ctx.fill_text("EQUIPPED" if sel else ("tap to wear" if unl else "locked"), cx + 42, cy + cellH / 2.0 + 12)
		model.outfit_tiles.append({"x": cx, "y": cy, "w": cellW, "h": cellH, "key": key, "unlocked": unl})
	model.outfit_back_btn = _back_btn()

# ───────────────────────── EMBLEMS ─────────────────────────
func drawEmblems() -> void:
	model.em_prev_btn = null
	model.em_next_btn = null
	_bg("#1a0e26", "#2a1020")
	var got_n = MenuHelpers.emblem_count()
	var total = DataRegistry.emblems.size()
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(18)
	ctx.fill_style("#ffe08a")
	ctx.font("900 34px Trebuchet MS")
	ctx.fill_text("🏅 EMBLEMS", W / 2.0, 44)
	ctx.restore()
	ctx.fill_style("#c8b0d0")
	ctx.font("12px monospace")
	ctx.fill_text("Achievements · %d / %d unlocked · some grant skins" % [got_n, total], W / 2.0, 64)
	var pbw = 460.0
	var pbx = W / 2.0 - pbw / 2.0
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(pbx, 72, pbw, 7, 3)
	ctx.fill()
	ctx.fill_style("#ffd27a")
	ctx.begin_path()
	ctx.round_rect(pbx, 72, pbw * (float(got_n) / float(maxi(1, total))), 7, 3)
	ctx.fill()
	if model.em_page >= MenuHelpers.em_page_count():
		model.em_page = MenuHelpers.em_page_count() - 1
	var cols = 4
	var rows = 3
	var gap = 8.0
	var gy = 90.0
	var botY = H - 56.0
	var gx = 24.0
	var cw = (W - 2.0 * gx) / float(cols)
	var ch = minf(92.0, (botY - gy - float(rows - 1) * gap) / float(rows))
	var start = model.em_page * MenuHelpers.EM_PER_PAGE
	var page_items: Array = DataRegistry.emblems.slice(start, start + MenuHelpers.EM_PER_PAGE)
	for i in range(page_items.size()):
		var e: Dictionary = page_items[i]
		var got = ProgressStore.has_emblem(str(e.get("id")))
		var secret = bool(e.get("secret", false)) and not got
		var cx = gx + float(i % cols) * cw
		var cy = gy + float(i / cols) * (ch + gap)
		ctx.fill_style("rgba(255,210,120,0.12)" if got else "rgba(255,255,255,0.03)")
		ctx.begin_path()
		ctx.round_rect(cx + 3, cy, cw - 6, ch, 10)
		ctx.fill()
		ctx.stroke_style("rgba(255,210,120,0.55)" if got else "rgba(255,255,255,0.08)")
		ctx.line_width(1.3)
		ctx.stroke()
		ctx.text_align("center")
		ctx.global_alpha(1.0 if got else 0.35)
		ctx.font("26px serif")
		ctx.fill_text(str(e.get("icon", "🏅")) if got else "🔒", cx + 27, cy + 30)
		ctx.global_alpha(1.0)
		ctx.fill_style("#ffe08a" if got else "#8a7a92")
		ctx.font("bold 12px Trebuchet MS")
		ctx.text_align("left")
		var nm = "???" if secret else str(e.get("name", ""))
		ctx.fill_text(nm.substr(0, 20), cx + 46, cy + 20)
		ctx.fill_style("#d0c0da" if got else "#6a5a72")
		ctx.font("9px monospace")
		var desc = "Hidden — keep playing." if secret else str(e.get("desc", ""))
		MenuHelpers.wrap_text(ctx, desc, cx + 46, cy + 34, cw - 54, 10, 3)
		if e.get("outfit") and not secret:
			var sn = str(e.get("outfit"))
			for o in DataRegistry.outfits:
				if str(o.get("key")) == sn:
					sn = str(o.get("name", sn))
					break
			ctx.fill_style("#8fd0a0" if got else "#6a7a6a")
			ctx.font("bold 9px monospace")
			ctx.fill_text("👗 " + sn, cx + 46, cy + ch - 8)
	var pc = MenuHelpers.em_page_count()
	if pc > 1:
		var ny = H - 46.0
		var nbw = 94.0
		var nbh = 28.0
		model.em_prev_btn = {"x": W / 2.0 - 150.0, "y": ny, "w": nbw, "h": nbh}
		model.em_next_btn = {"x": W / 2.0 + 56.0, "y": ny, "w": nbw, "h": nbh}
		_nav_btn(model.em_prev_btn, "◀ PREV", model.em_page > 0)
		_nav_btn(model.em_next_btn, "NEXT ▶", model.em_page < pc - 1)
		ctx.text_align("center")
		ctx.fill_style("#c8b0d0")
		ctx.font("bold 13px monospace")
		ctx.fill_text("Page %d / %d" % [model.em_page + 1, pc], W / 2.0, H - 28)
	ctx.text_align("center")
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 30.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 13px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP EMPTY AREA TO RETURN", W / 2.0, H - 8)
	ctx.text_align("left")

func _nav_btn(b: Dictionary, label: String, on: bool) -> void:
	ctx.fill_style("rgba(40,20,50,0.9)" if on else "rgba(30,18,38,0.4)")
	ctx.begin_path()
	ctx.round_rect(float(b.x), float(b.y), float(b.w), float(b.h), 7)
	ctx.fill()
	ctx.stroke_style("#ff8ac0" if on else "rgba(255,140,200,0.25)")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#ffd6ea" if on else "#6a5a72")
	ctx.font("bold 13px monospace")
	ctx.text_align("center")
	ctx.fill_text(label, float(b.x) + float(b.w) / 2.0, float(b.y) + 18.0)
	ctx.text_align("left")

# ───────────────────────── NG+ ─────────────────────────
func drawNgSelect() -> void:
	model.ng_tiles.clear()
	model.ng_back_btn = null
	_bg("#1a1226", "#241018")
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(16)
	ctx.fill_style("#ffe6b0")
	ctx.font("900 30px Trebuchet MS")
	ctx.fill_text("🔁 NEW GAME+", W / 2.0, 38)
	ctx.restore()
	ctx.fill_style("#c8b0a0")
	ctx.font("12px monospace")
	ctx.fill_text("Pick your cycle — higher levels mean tougher Mumus & bigger score. Unlocked up to Lv%d of %d." % [ProgressStore.ng_unlocked, MenuHelpers.MAX_NG], W / 2.0, 58)
	ctx.fill_style("#9a8aa2")
	ctx.font("11px monospace")
	ctx.fill_text("★ Milestone wins unlock skins:  25 🍌 Banana · 50 🐿️ Squirrely · 75 🍯 Honeypot · 100 👑 Empress", W / 2.0, 76)
	var mile = {25: "🍌", 50: "🐿️", 75: "🍯", 100: "👑"}
	var cols = 10
	var gx = 40.0
	var gyTop = 94.0
	var gap = 6.0
	var cellW = (W - 2.0 * gx - float(cols - 1) * gap) / float(cols)
	var cellH = 29.0
	var rg = 5.0
	for L in range(MenuHelpers.MAX_NG + 1):
		var col = L % cols
		var row = int(L / cols)
		var cx = gx + float(col) * (cellW + gap)
		var cy = gyTop + float(row) * (cellH + rg)
		var unl = L <= ProgressStore.ng_unlocked
		var sel = L == GameState.ng_plus
		var m = mile.get(L, null)
		ctx.fill_style("rgba(255,210,120,0.24)" if sel else ("rgba(255,255,255,0.05)" if unl else "rgba(255,255,255,0.02)"))
		ctx.begin_path()
		ctx.round_rect(cx, cy, cellW, cellH, 7)
		ctx.fill()
		ctx.stroke_style("#ffd27a" if sel else (("#ff9ecb" if m != null and unl else ("rgba(255,210,150,0.3)" if unl else "rgba(255,255,255,0.07)"))))
		ctx.line_width(2.4 if sel else (1.6 if m != null else 1.0))
		ctx.stroke()
		ctx.fill_style("#ffe6b0" if sel else (("#ffd0e4" if unl and m != null else ("#e6d8c8" if unl else "#6a5a72"))))
		ctx.font("bold 12px monospace")
		ctx.text_align("center")
		ctx.fill_text("OFF" if L == 0 else str(L), cx + cellW / 2.0, cy + cellH / 2.0 + 4)
		if m != null:
			ctx.font("10px serif")
			ctx.fill_text(str(m), cx + cellW - 9, cy + 11)
		elif not unl:
			ctx.font("9px serif")
			ctx.fill_text("🔒", cx + 9, cy + 11)
		model.ng_tiles.append({"x": cx, "y": cy, "w": cellW, "h": cellH, "lvl": L, "unlocked": unl})
	var iy = gyTop + 11.0 * (cellH + rg) + 14.0
	ctx.text_align("center")
	ctx.font("bold 13px monospace")
	ctx.fill_style("#ffd27a")
	if GameState.ng_plus > 0:
		ctx.fill_text("▶ Selected: NG+ Lv%d   ·   ×%d base score   ·   +%d%% threat" % [GameState.ng_plus, 1 + GameState.ng_plus, GameState.ng_plus * 16], W / 2.0, iy)
	else:
		ctx.fill_text("▶ Selected: NG+ OFF   ·   standard run", W / 2.0, iy)
	ctx.fill_style("#7a6a82")
	ctx.font("10px monospace")
	ctx.fill_text("tap a level to select · " + MenuHelpers.kb("shoot") + " / BACK returns to the menu", W / 2.0, iy + 16)
	model.ng_back_btn = _back_btn()

# ───────────────────────── ARSENAL ─────────────────────────
func drawArsenal() -> void:
	model.arsenal_tiles.clear()
	_bg("#101828", "#1a1020")
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#7fdfff")
	ctx.shadow_blur(14)
	ctx.fill_style("#bff0ff")
	ctx.font("900 24px Trebuchet MS")
	ctx.fill_text("🎒 ARSENAL", W / 2.0, 30)
	ctx.restore()
	var tabs = [
		["w", "WEAPONS", "#ff8ac0", "[" + MenuHelpers.kb("swap") + "] cycles these in a run"],
		["s", "SPECIALS", "#b98cff", "[" + MenuHelpers.kb("special") + "] use · cycle swaps"],
		["m", "MELEE", "#ff8a6a", "[" + MenuHelpers.kb("melee") + "] swipe"],
		["i", "ITEMS", "#ffd27a", "switch / hold to use consumables"],
	]
	var tabW = 142.0
	var tabGap = 10.0
	var tabsW = float(tabs.size()) * tabW + float(tabs.size() - 1) * tabGap
	var tabX0 = W / 2.0 - tabsW / 2.0
	var tabY = 42.0
	var tabH = 30.0
	for i in range(tabs.size()):
		var tk: String = tabs[i][0]
		var tlabel: String = tabs[i][1]
		var tcol: String = tabs[i][2]
		var tx = tabX0 + float(i) * (tabW + tabGap)
		var on = model.ars_tab == tk
		var arr = model.ars_arr(tk)
		var cap: int = int(MenuHelpers.ARS_CAP[tk])
		ctx.fill_style(tcol if on else "rgba(255,255,255,0.05)")
		ctx.begin_path()
		ctx.round_rect(tx, tabY, tabW, tabH, 9)
		ctx.fill()
		ctx.stroke_style("#fff" if on else "rgba(255,255,255,0.16)")
		ctx.line_width(2 if on else 1)
		ctx.stroke()
		ctx.fill_style("#141018" if on else "#c8b0d0")
		ctx.font("bold 13px Trebuchet MS")
		ctx.text_align("center")
		ctx.fill_text("%s  %d/%d" % [tlabel, arr.size(), cap], tx + tabW / 2.0, tabY + 20)
		model.arsenal_tiles.append({"x": tx, "y": tabY, "w": tabW, "h": tabH, "tab": tk})
	var type = model.ars_tab
	var arr2 = model.ars_arr(type)
	var cap2: int = int(MenuHelpers.ARS_CAP[type])
	var accent = "#ff8ac0"
	if type == "s":
		accent = "#b98cff"
	elif type == "m":
		accent = "#ff8a6a"
	elif type == "i":
		accent = "#ffd27a"
	var hint = ""
	for t in tabs:
		if t[0] == type:
			hint = t[3]
			break
	ctx.text_align("center")
	ctx.fill_style(accent)
	ctx.font("bold 12px monospace")
	ctx.fill_text("YOUR LOADOUT  ·  drag/tap to equip & order  ·  " + hint, W / 2.0, 92)
	var slotW = minf(130.0, (W - 100.0 - float(cap2 - 1) * 14.0) / float(cap2))
	var slotH = 66.0
	var sTotW = float(cap2) * slotW + float(cap2 - 1) * 14.0
	var sX0 = W / 2.0 - sTotW / 2.0
	var sY = 104.0
	var drag = model.ars_drag
	for i in range(cap2):
		var sx = sX0 + float(i) * (slotW + 14.0)
		var key = arr2[i] if i < arr2.size() else null
		var over = false
		if drag and typeof(drag) == TYPE_DICTIONARY and bool(drag.get("moved", false)):
			over = MenuHelpers.in_btn(Vector2(float(drag.get("x", 0)), float(drag.get("y", 0))), {"x": sx, "y": sY, "w": slotW, "h": slotH})
		ctx.fill_style("rgba(255,255,255,0.035)")
		ctx.begin_path()
		ctx.round_rect(sx, sY, slotW, slotH, 11)
		ctx.fill()
		ctx.stroke_style("#fff" if over else "rgba(255,255,255,0.2)")
		ctx.line_width(2.6 if over else 1.4)
		ctx.stroke()
		ctx.fill_style(accent)
		ctx.font("bold 9px monospace")
		ctx.text_align("left")
		ctx.fill_text("#%d" % (i + 1), sx + 7, sY + 13)
		if key != null:
			var it = model.ars_item_by_key(type, str(key))
			if not it.is_empty():
				var ghost = drag and str(drag.get("key")) == str(key) and str(drag.get("from", "")) == "hotbar" and bool(drag.get("moved", false))
				ctx.global_alpha(0.3 if ghost else 1.0)
				ctx.fill_style("rgba(255,210,120,0.12)")
				ctx.begin_path()
				ctx.round_rect(sx + 2, sY + 2, slotW - 4, slotH - 4, 9)
				ctx.fill()
				ctx.stroke_style(str(it.get("col", accent)))
				ctx.line_width(2)
				ctx.begin_path()
				ctx.round_rect(sx + 2, sY + 2, slotW - 4, slotH - 4, 9)
				ctx.stroke()
				ctx.fill_style("#fff")
				ctx.font("26px serif")
				ctx.text_align("center")
				ctx.fill_text(str(it.get("icon", "?")), sx + slotW / 2.0, sY + 34)
				ctx.fill_style("#ffe6b0")
				ctx.font("bold 10px Trebuchet MS")
				ctx.fill_text(str(it.get("name", key)).substr(0, 12), sx + slotW / 2.0, sY + 52)
				if type == "i":
					ctx.fill_style("#9fe0a4")
					ctx.font("900 9px monospace")
					ctx.text_align("right")
					ctx.fill_text("×%d" % MenuHelpers.consum_qty(str(key)), sx + slotW - 6, sY + 14)
				ctx.global_alpha(1.0)
				model.arsenal_tiles.append({"x": sx, "y": sY, "w": slotW, "h": slotH, "type": type, "key": str(key), "hotbarSlot": i, "fromHot": true})
		else:
			ctx.fill_style("#46566a")
			ctx.font("26px monospace")
			ctx.text_align("center")
			ctx.fill_text("+", sx + slotW / 2.0, sY + slotH / 2.0 + 10)
			model.arsenal_tiles.append({"x": sx, "y": sY, "w": slotW, "h": slotH, "type": type, "hotbarSlot": i, "emptySlot": true})
	# pool
	ctx.text_align("left")
	ctx.fill_style("#c8b0d0")
	ctx.font("bold 11px monospace")
	ctx.fill_text("AVAILABLE  —  tap or drag into a slot above", 40, sY + slotH + 26)
	var pool = model.ars_pool(type)
	var pCols = 4 if type == "s" else 5
	var pGap = 8.0
	var pX0 = 30.0
	var pTW = (W - 60.0 - float(pCols - 1) * pGap) / float(pCols)
	var pY0 = sY + slotH + 34.0
	var pTH = 82.0 if type == "s" else 86.0
	var pRG = 9.0
	for i in range(pool.size()):
		var it: Dictionary = pool[i]
		var r = int(i / pCols)
		var c = i % pCols
		var px = pX0 + float(c) * (pTW + pGap)
		var py = pY0 + float(r) * (pTH + pRG)
		var sel = arr2.has(str(it.get("key")))
		var locked = bool(it.get("locked", false))
		var ghost2 = drag and str(drag.get("key")) == str(it.get("key")) and str(drag.get("from", "")) == "pool" and bool(drag.get("moved", false))
		ctx.global_alpha(0.3 if ghost2 else (0.5 if locked else 1.0))
		ctx.fill_style("rgba(255,210,120,0.14)" if sel else "rgba(255,255,255,0.04)")
		ctx.begin_path()
		ctx.round_rect(px, py, pTW, pTH, 9)
		ctx.fill()
		ctx.stroke_style(str(it.get("col", accent)) if sel else "rgba(255,255,255,0.14)")
		ctx.line_width(2.2 if sel else 1.1)
		ctx.stroke()
		ctx.fill_style("#fff")
		ctx.font("20px serif")
		ctx.text_align("left")
		ctx.fill_text(str(it.get("icon", "?")), px + 9, py + 24)
		ctx.fill_style("#ffe08a" if sel else "#e6d8f0")
		ctx.font("bold 11px Trebuchet MS")
		ctx.fill_text(str(it.get("name", "")).substr(0, 14), px + 37, py + 18)
		ctx.fill_style("#b8a8c8")
		ctx.font("8.5px monospace")
		MenuHelpers.wrap_text(ctx, str(it.get("desc", "")), px + 10, py + 34, pTW - 18, 9, 3)
		if sel:
			ctx.fill_style(str(it.get("col", accent)))
			ctx.text_align("right")
			ctx.font("bold 14px monospace")
			ctx.fill_text("✓", px + pTW - 8, py + 18)
		if locked:
			ctx.global_alpha(1.0)
			ctx.fill_style("rgba(10,6,16,0.45)")
			ctx.begin_path()
			ctx.round_rect(px, py, pTW, pTH, 10)
			ctx.fill()
			ctx.font("18px serif")
			ctx.text_align("center")
			ctx.fill_text("🔒", px + pTW - 15, py + 21)
			ctx.fill_style("#ffd27a")
			ctx.font("bold 9px monospace")
			ctx.fill_text("💀 %d · SHOP" % MenuHelpers.lock_cost(type, str(it.get("key"))), px + pTW / 2.0, py + pTH - 6)
		if type == "i":
			ctx.global_alpha(1.0)
			ctx.fill_style("#9fe0a4")
			ctx.font("900 10px monospace")
			ctx.text_align("right")
			ctx.fill_text("×%d" % MenuHelpers.consum_qty(str(it.get("key"))), px + pTW - 8, py + pTH - 7)
		ctx.global_alpha(1.0)
		model.arsenal_tiles.append({"x": px, "y": py, "w": pTW, "h": pTH, "type": type, "key": str(it.get("key")), "pool": true, "locked": locked})
	# drag ghost
	if drag and typeof(drag) == TYPE_DICTIONARY and bool(drag.get("moved", false)) and drag.get("key"):
		var git = model.ars_item_by_key(type, str(drag.get("key")))
		if not git.is_empty():
			ctx.save()
			ctx.global_alpha(0.92)
			ctx.fill_style("rgba(34,22,50,0.96)")
			ctx.stroke_style("#fff")
			ctx.line_width(2)
			ctx.begin_path()
			ctx.round_rect(float(drag.x) - 30, float(drag.y) - 19, 60, 38, 9)
			ctx.fill()
			ctx.stroke()
			ctx.fill_style("#fff")
			ctx.font("24px serif")
			ctx.text_align("center")
			ctx.fill_text(str(git.get("icon", "?")), float(drag.x), float(drag.y) + 8)
			ctx.restore()
	if model.ars_msg != null and typeof(model.ars_msg) == TYPE_DICTIONARY:
		model.ars_msg["t"] = int(model.ars_msg.get("t", 0)) - 1
		ctx.save()
		ctx.global_alpha(minf(1.0, float(model.ars_msg["t"]) / 24.0))
		ctx.text_align("center")
		ctx.fill_style("#ff9aa8")
		ctx.font("bold 14px Trebuchet MS")
		ctx.fill_text(str(model.ars_msg.get("txt", "")), W / 2.0, H - 26)
		ctx.restore()
		if int(model.ars_msg["t"]) <= 0:
			model.ars_msg = null
	ctx.text_align("center")
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 30.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 13px monospace")
	var ret = "RESUME" if model.arsenal_return == "stageclear" else "RETURN"
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP EMPTY AREA TO " + ret, W / 2.0, H - 8)
	ctx.text_align("left")

# ───────────────────────── LEADERBOARD ─────────────────────────
func drawLeaderboard() -> void:
	model.lb_rows.clear()
	model.lb_prev_btn = null
	model.lb_next_btn = null
	_bg("#1a0e26", "#2a1020")
	var P = Config.portrait
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(20)
	ctx.fill_style("#ffe08a")
	ctx.font("900 %dpx Trebuchet MS" % (24 if P else 40))
	ctx.fill_text("🏆 GLOBAL LEADERBOARD", W / 2.0, 42 if P else 60)
	ctx.restore()
	ctx.fill_style("#c8b0d0")
	ctx.font("%dpx monospace" % (10 if P else 12))
	ctx.fill_text("Top Mumu Slayers worldwide · Powered by Emblem Vault", W / 2.0, 60 if P else 82)
	var list: Array = model.lb_cache
	var x0 = 14.0 if P else W / 2.0 - 292.0
	var y = 90.0 if P else 116.0
	var oFit = 20.0 if P else 26.0
	var oHandle = 50.0 if P else 58.0
	var oIcon = 28.0 if P else 34.0
	var oScore = 300.0 if P else 330.0
	var oMumus = 388.0 if P else 430.0
	var oRank = 446.0 if P else 500.0
	var oMode = 512.0 if P else 584.0
	var rowH = 23.0 if P else 25.0
	var rf = 12 if P else 14
	ctx.text_align("left")
	ctx.fill_style("#8fd0ff")
	ctx.font("bold %dpx monospace" % (10 if P else 12))
	ctx.fill_text("#", x0, y)
	ctx.fill_text("FIT", x0 + oFit, y)
	ctx.fill_text("PLAYER", x0 + oHandle, y)
	ctx.text_align("right")
	ctx.fill_text("SCORE", x0 + oScore, y)
	ctx.fill_text("MUMUS", x0 + oMumus, y)
	ctx.fill_text("RANK", x0 + oRank, y)
	ctx.fill_text("MODE", x0 + oMode, y)
	ctx.text_align("left")
	ctx.stroke_style("rgba(255,255,255,0.15)")
	ctx.begin_path()
	ctx.move_to(x0, y + 7)
	ctx.line_to(x0 + oMode, y + 7)
	ctx.stroke()
	y += 26
	if model.lb_state == "loading" and list.is_empty():
		ctx.text_align("center")
		ctx.fill_style("#9a7c96")
		ctx.font("16px Trebuchet MS")
		ctx.fill_text("Loading global scores" + ".".repeat(1 + int(floorf(float(tick) / 20.0)) % 3), W / 2.0, y + 50)
	elif model.lb_state == "error":
		ctx.text_align("center")
		ctx.fill_style("#ff8a8a")
		ctx.font("15px Trebuchet MS")
		ctx.fill_text("Couldn’t reach the leaderboard server. Try again.", W / 2.0, y + 50)
	elif list.is_empty():
		ctx.text_align("center")
		ctx.fill_style("#9a7c96")
		ctx.font("16px Trebuchet MS")
		ctx.fill_text("No scores yet — be the first to exterminate some Mumus!", W / 2.0, y + 50)
	else:
		if model.lb_page >= model.lb_page_count():
			model.lb_page = model.lb_page_count() - 1
		var start = model.lb_page * MenuHelpers.LB_PER_PAGE
		var page_items: Array = list.slice(start, start + MenuHelpers.LB_PER_PAGE)
		for i in range(page_items.size()):
			var e: Dictionary = page_items[i]
			var rank = start + i
			var hot = _lb_is_mine(e)
			if hot:
				ctx.fill_style("rgba(255,90,140,0.2)")
				ctx.fill_rect(x0 - 6, y - 15, (W - 16.0) if P else 616.0, 23)
			var _fontw1 = ("bold " if hot else "") + str(rf) + "px monospace"
			ctx.font(_fontw1)
			if hot:
				ctx.fill_style("#fff")
			elif rank < 3:
				ctx.fill_style(["#ffd700", "#c8ccd4", "#cd7f32"][rank])
			else:
				ctx.fill_style("#c8b0c4")
			ctx.text_align("left")
			ctx.fill_text(str(rank + 1), x0, y)
			var fit = str(e.get("outfit", "og"))
			var known = false
			for o in DataRegistry.outfits:
				if str(o.get("key")) == fit:
					known = true
					break
			if not known:
				fit = "og"
			_draw_bobina_at(x0 + oIcon, y - 3.5, 0.42 if P else 0.46, fit)
			var _fontw2 = ("bold " if hot else "") + str(rf) + "px monospace"
			ctx.font(_fontw2)
			var linked = (e.get("bcId") != null and str(e.get("bcId")) != "") or e.get("linked") == true
			var disp = ""
			if linked:
				disp = str(e.get("name", ""))
				if disp == "" and e.get("bobinaUsername"):
					disp = "@" + str(e.get("bobinaUsername"))
				if disp == "":
					disp = "Bobina"
			else:
				if e.get("handle"):
					disp = "@" + str(e.get("handle"))
				else:
					disp = str(e.get("name", "Anon"))
			disp = disp.substr(0, 13 if P else 16)
			var purl = e.get("profileUrl")
			if purl == null or str(purl) == "":
				if e.get("bobinaUsername"):
					purl = "https://bobina.moe/" + str(e.get("bobinaUsername"))
				elif e.get("handle"):
					purl = "https://x.com/" + str(e.get("handle"))
				else:
					purl = null
			if purl != null:
				ctx.fill_style("#ff9ecb" if linked else "#7ec8ff")
				ctx.fill_text(disp, x0 + oHandle, y)
				var tw: float = float(ctx.measure_text(disp).get("width", 80))
				ctx.stroke_style("rgba(255,158,203,0.55)" if linked else "rgba(126,200,255,0.5)")
				ctx.line_width(1)
				ctx.begin_path()
				ctx.move_to(x0 + oHandle, y + 2)
				ctx.line_to(x0 + oHandle + tw, y + 2)
				ctx.stroke()
				model.lb_rows.append({"x": x0 + oHandle - 6, "y": y - 13, "w": tw + 12, "h": 19, "profileUrl": str(purl)})
			else:
				ctx.fill_text(disp, x0 + oHandle, y)
			ctx.text_align("right")
			ctx.fill_style("#fff" if hot else "#c8b0c4")
			ctx.fill_text(MenuHelpers.fmt_score(e.get("score", 0)), x0 + oScore, y)
			ctx.fill_text(MenuHelpers.fmt_score(e.get("kills", 0)), x0 + oMumus, y)
			ctx.fill_text(str(e.get("rank", "-")), x0 + oRank, y)
			var md = str(e.get("mode", "NORMAL"))
			if md.begins_with("HELL"):
				ctx.fill_style("#ff2a2a")
			elif md.begins_with("HARD"):
				ctx.fill_style("#ff5b6e")
			else:
				ctx.fill_style("#fff" if hot else "#8fd0a0")
			var _fontw3 = ("bold " if hot else "") + str(11 if P else 13) + "px monospace"
			ctx.font(_fontw3)
			ctx.fill_text(md, x0 + oMode, y)
			ctx.text_align("left")
			y += rowH
		var pc = model.lb_page_count()
		if pc > 1:
			var ny = H - 58.0
			var nbw = 94.0
			var nbh = 28.0
			model.lb_prev_btn = {"x": W / 2.0 - 150.0, "y": ny, "w": nbw, "h": nbh}
			model.lb_next_btn = {"x": W / 2.0 + 56.0, "y": ny, "w": nbw, "h": nbh}
			_nav_btn(model.lb_prev_btn, "◀ PREV", model.lb_page > 0)
			_nav_btn(model.lb_next_btn, "NEXT ▶", model.lb_page < pc - 1)
			ctx.text_align("center")
			ctx.fill_style("#c8b0d0")
			ctx.font("bold 13px monospace")
			ctx.fill_text("Page %d / %d" % [model.lb_page + 1, pc], W / 2.0, H - 40)
	if model.lb_state == "ok" and model.last_submit != null:
		ctx.text_align("center")
		ctx.fill_style("#ff9ecb")
		ctx.font("italic 12px Trebuchet MS")
		ctx.fill_text("★ your run is highlighted — flex it on X!", W / 2.0, H - 72)
	ctx.text_align("center")
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 30.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 15px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP EMPTY AREA TO RETURN", W / 2.0, H - 16)
	ctx.text_align("left")

func _lb_is_mine(e: Dictionary) -> bool:
	## HTML lbIsMine via lastSubmit, plus auth fallback
	if P2Meta and P2Meta.lb_is_mine(e):
		return true
	if not ApiClient.authenticated:
		return false
	var me_user = str(ApiClient.me.get("username", ""))
	if me_user != "" and str(e.get("bobinaUsername", "")) == me_user:
		return true
	if e.get("bcId") != null and str(e.get("bcId")) == str(ApiClient.me.get("bcId", "")):
		return true
	return false
