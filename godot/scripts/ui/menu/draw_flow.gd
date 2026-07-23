extends RefCounted
## Canvas drawers: intro, stage clear, clear gate, shop, dialog.

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx
var tick: int = 0
var W: float = 960.0
var H: float = 540.0
var shop_btns: Array = []
var badger = null  # drawHoneyBadger optional
var ported = null  # PortedDraw for 1:1 portrait bust

func setup(c) -> void:
	ctx = c
	W = Config.W
	H = Config.H
	badger = load("res://scripts/render/drawers/drawHoneyBadger.gd").new()
	badger.setup(c)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(c)

func set_tick(t: int) -> void:
	tick = t
	W = Config.W
	H = Config.H
	if badger and badger.has_method("set_tick"):
		badger.set_tick(t)
	if ported and ported.has_method("set_tick"):
		ported.set_tick(t)

func _hex_a(h, a) -> String:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return "rgba(%d,%d,%d,%s)" % [(n >> 16) & 255, (n >> 8) & 255, n & 255, str(a)]

func draw_intro() -> void:
	## HTML drawIntro
	ctx.fill_style("rgba(6,4,10,0.82)")
	ctx.fill_rect(0, 0, W, H)
	var s: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	if s.is_empty() and DataRegistry.stages.size() > GameState.stage_index:
		s = DataRegistry.stages[GameState.stage_index]
	var accent := str(s.get("accent", "#ff9ecb"))
	ctx.text_align("center")
	ctx.fill_style(accent)
	ctx.font("bold 20px monospace")
	ctx.fill_text(str(s.get("title", "STAGE")), W / 2.0, H / 2.0 - 40.0)
	ctx.save()
	ctx.shadow_color(accent)
	ctx.shadow_blur(20)
	ctx.fill_style("#fff")
	ctx.font("900 40px Trebuchet MS")
	ctx.fill_text(str(s.get("name", "")), W / 2.0, H / 2.0)
	ctx.restore()
	ctx.fill_style("#c8b0c4")
	ctx.font("14px Trebuchet MS")
	ctx.fill_text("The Mumus must be exterminated.", W / 2.0, H / 2.0 + 34.0)
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 26.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 16px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP TO BEGIN", W / 2.0, H / 2.0 + 72.0)
	ctx.text_align("left")

func draw_stage_clear(info: Dictionary) -> void:
	## HTML drawStageClear
	ctx.fill_style("rgba(6,4,10,0.92)")
	ctx.fill_rect(0, 0, W, H)
	ctx.text_align("center")
	var stage_i := int(info.get("stage", 0))
	var img = AssetBank.get_tex("clear%d" % clampi(stage_i, 0, 5)) if AssetBank else null
	var bw := 460.0
	var bh := roundf(bw * 440.0 / 1000.0)
	var bx := W / 2.0 - bw / 2.0
	var byy := 18.0
	if img:
		ctx.draw_image(img, bx, byy, bw, bh)
		ctx.stroke_style("rgba(255,210,120,0.7)")
		ctx.line_width(3)
		ctx.begin_path()
		ctx.round_rect(bx, byy, bw, bh, 14)
		ctx.stroke()
	else:
		ctx.save()
		ctx.shadow_color("#ffd27a")
		ctx.shadow_blur(22)
		ctx.fill_style("#ffe08a")
		ctx.font("900 42px Trebuchet MS")
		ctx.fill_text("★ STAGE CLEAR ★", W / 2.0, 110)
		ctx.restore()
	var yb := byy + bh + 16.0
	# HTML leek-spin celebration GIF (native #leek overlay → canvas frames)
	var leek = AssetBank.get_tex("leek") if AssetBank else null
	if leek:
		var lh := 100.0
		var lw := roundf(lh * float(leek.get_width()) / maxf(1.0, float(leek.get_height())))
		ctx.save()
		ctx.shadow_color("rgba(255,150,200,0.55)")
		ctx.shadow_blur(18)
		ctx.begin_path()
		ctx.round_rect(W / 2.0 - lw / 2.0, yb, lw, lh, 10)
		ctx.clip()
		ctx.draw_image(leek, W / 2.0 - lw / 2.0, yb, lw, lh)
		ctx.restore()
		ctx.stroke_style("#ff9ecb")
		ctx.line_width(2)
		ctx.begin_path()
		ctx.round_rect(W / 2.0 - lw / 2.0, yb, lw, lh, 10)
		ctx.stroke()
		yb += lh + 36.0
	else:
		yb += 8.0
	ctx.fill_style("#ff9ecb")
	ctx.font("bold 22px Trebuchet MS")
	ctx.fill_text("%d MUMUS ELIMINATED" % int(info.get("killsThisStage", 0)), W / 2.0, yb)
	yb += 24
	ctx.fill_style("#e8d6f0")
	ctx.font("13px monospace")
	ctx.fill_text("Total %d  ·  Rank %s  ·  Score %s" % [
		int(info.get("total", GameState.total_kills)),
		GameState.rank_letter(),
		MenuHelpers.fmt_score(GameState.session_score),
	], W / 2.0, yb)
	yb += 28
	var ems: Array = info.get("emblems", [])
	if ems.size():
		ctx.fill_style("#ffd27a")
		ctx.font("bold 14px monospace")
		ctx.fill_text("🏅 NEW EMBLEMS", W / 2.0, yb)
		yb += 18
		for em in ems:
			if em is Dictionary:
				ctx.fill_style("#8fd0ff")
				ctx.font("12px monospace")
				ctx.fill_text("%s %s" % [em.get("icon", "★"), em.get("name", "")], W / 2.0, yb)
				yb += 16
	ctx.fill_style("#8fd0a0")
	ctx.font("bold 13px monospace")
	ctx.fill_text("💀 +15 heads for the boss bounty", W / 2.0, yb + 8)
	# HTML 🎒 EDIT ARSENAL button
	var aw := 224.0
	var ah := 30.0
	var ax := W / 2.0 - aw / 2.0
	var ay := H - 86.0
	ctx.fill_style("rgba(20,40,58,0.85)")
	ctx.begin_path()
	ctx.round_rect(ax, ay, aw, ah, 8)
	ctx.fill()
	ctx.stroke_style("#7fdfff")
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style("#bff0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.fill_text("🎒 EDIT ARSENAL", W / 2.0, ay + 20)
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 26.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 16px monospace")
	ctx.fill_text("PRESS " + MenuHelpers.kb("shoot") + " / TAP TO CONTINUE", W / 2.0, H - 28)
	ctx.text_align("left")

func draw_clear_gate(portal, shop, msg_t: float) -> void:
	## HTML drawClearGate — field portal + shop marker
	if portal == null:
		return
	var t := float(tick)
	var px := float(portal.get("x", 0))
	var py := float(portal.get("y", 0))
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	var bc := str(stage.get("accent", "#9a6cff"))
	ctx.save()
	ctx.translate(px, py)
	# aura
	ctx.fill_style(_hex_a(bc, 0.45))
	ctx.begin_path()
	ctx.ellipse(0, 2, 66, 58, 0, 0, TAU)
	ctx.fill()
	# tendrils
	ctx.stroke_style(_hex_a("#05030a", 0.65))
	ctx.line_width(3)
	ctx.line_cap("round")
	for a in range(7):
		var an := float(a) / 7.0 * TAU + t * 0.004
		ctx.begin_path()
		ctx.move_to(cos(an) * 20, sin(an) * 17)
		ctx.quadratic_curve_to(cos(an + 0.2) * 40, sin(an + 0.2) * 34, cos(an + 0.4) * 56, sin(an + 0.4) * 48)
		ctx.stroke()
	# vortex rings
	ctx.global_composite_operation("lighter")
	for a2 in range(5):
		ctx.stroke_style(_hex_a(bc, 0.55))
		ctx.line_width(2.6)
		ctx.begin_path()
		var first := true
		var s := 0.0
		while s <= 1.0:
			var rr := s * 38.0
			var an2 := t * 0.055 + float(a2) * 1.25 + s * 4.0
			var x := cos(an2) * rr
			var y := sin(an2) * rr * 0.85
			if first:
				ctx.move_to(x, y)
				first = false
			else:
				ctx.line_to(x, y)
			s += 0.045
		ctx.stroke()
	ctx.global_composite_operation("source-over")
	# core
	ctx.fill_style(_hex_a("#0a0612", 0.9))
	ctx.begin_path()
	ctx.ellipse(0, 0, 18, 15, 0, 0, TAU)
	ctx.fill()
	ctx.stroke_style(_hex_a(bc, 0.9))
	ctx.line_width(2)
	ctx.stroke()
	ctx.restore()
	# label
	ctx.text_align("center")
	ctx.fill_style("#ffe08a")
	ctx.font("bold 12px monospace")
	var next_s: Dictionary = DataRegistry.get_stage(GameState.stage_index + 1)
	var next_name := str(next_s.get("name", "NEXT"))
	ctx.fill_text("▸ PORTAL — " + next_name, px, py - 70)
	if msg_t > 0.0:
		ctx.fill_style("#ff9ecb")
		ctx.font("bold 14px Trebuchet MS")
		ctx.fill_text("BOSS DEFEATED — open the portal or visit the shop", Config.playfield().get_center().x, Config.playfield().position.y + 40)
	# shop marker
	if shop != null:
		var sx := float(shop.get("x", 0))
		var sy := float(shop.get("y", 0))
		ctx.fill_style("rgba(255,210,120,0.2)")
		ctx.begin_path()
		ctx.arc(sx, sy, 28, 0, TAU)
		ctx.fill()
		ctx.stroke_style("#ffd27a")
		ctx.line_width(2)
		ctx.stroke()
		if badger:
			badger.drawHoneyBadger(sx, sy + 8, 0.55)
		ctx.fill_style("#ffd27a")
		ctx.font("bold 11px monospace")
		ctx.fill_text("🛍 SHOP", sx, sy - 36)
	ctx.text_align("left")

func draw_shop(tab: String, sel: int, msg: String, msg_t: float) -> void:
	## HTML drawShop (grid + tabs + heads + badger)
	shop_btns = []
	ctx.fill_style("#2a1c12")
	ctx.fill_rect(0, 0, W, H * 0.55)
	ctx.fill_style("#150d07")
	ctx.fill_rect(0, H * 0.45, W, H * 0.55)
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(12)
	ctx.fill_style("#ffe08a")
	ctx.font("900 24px Trebuchet MS")
	ctx.fill_text("HONEY BADGER'S SHOP", W / 2.0, 30)
	ctx.restore()
	# heads badge
	ctx.fill_style("#241810")
	ctx.begin_path()
	ctx.round_rect(W - 176, 10, 158, 24, 8)
	ctx.fill()
	ctx.stroke_style("#ffd27a")
	ctx.line_width(1.4)
	ctx.stroke()
	ctx.fill_style("#ffd27a")
	ctx.font("bold 14px monospace")
	ctx.text_align("left")
	ctx.fill_text("💀 %d HEADS" % int(ProgressStore.progress.get("heads", 0)), W - 166, 27)
	# tabs
	var tabs := [["w", "WEAPONS", "#ff8ac0"], ["s", "SPECIALS", "#b98cff"], ["m", "MELEE", "#ff8a6a"], ["i", "ITEMS", "#ffd27a"]]
	var tw := 150.0
	var tg := 10.0
	var tot := float(tabs.size()) * tw + float(tabs.size() - 1) * tg
	var tx0 := W / 2.0 - tot / 2.0
	var ty := 42.0
	var thh := 28.0
	for i in range(tabs.size()):
		var tk: String = tabs[i][0]
		var tl: String = tabs[i][1]
		var tc: String = tabs[i][2]
		var tx := tx0 + float(i) * (tw + tg)
		var on := tab == tk
		ctx.fill_style(tc if on else "rgba(255,255,255,0.05)")
		ctx.begin_path()
		ctx.round_rect(tx, ty, tw, thh, 8)
		ctx.fill()
		ctx.stroke_style("#fff" if on else "rgba(255,255,255,0.16)")
		ctx.line_width(2 if on else 1)
		ctx.stroke()
		ctx.fill_style("#141018" if on else "#c8b0d0")
		ctx.font("bold 13px Trebuchet MS")
		ctx.text_align("center")
		ctx.fill_text(tl, tx + tw / 2.0, ty + 19)
		shop_btns.append({"x": tx, "y": ty, "w": tw, "h": thh, "tab": tk})
	# list
	var list := _shop_list(tab)
	var cols := 4 if tab == "s" else (6 if tab == "i" else 5)
	var gap := 8.0
	var gx := 18.0
	var tW := (W - 2.0 * gx - float(cols - 1) * gap) / float(cols)
	var gy := 80.0
	var rg := 9.0
	var tH := 78.0 if tab != "i" else 104.0
	var heads := int(ProgressStore.progress.get("heads", 0))
	for i in range(list.size()):
		var it: Dictionary = list[i]
		var c := i % cols
		var r := int(i / cols)
		var cx := gx + float(c) * (tW + gap)
		var cy := gy + float(r) * (tH + rg)
		var is_sel := i == sel
		var owned := bool(it.get("owned", false))
		var cost := int(it.get("cost", 0))
		var afford := heads >= cost
		ctx.global_alpha(0.55 if owned else 1.0)
		ctx.fill_style("rgba(255,210,120,0.16)" if is_sel else "rgba(255,255,255,0.045)")
		ctx.begin_path()
		ctx.round_rect(cx, cy, tW, tH, 9)
		ctx.fill()
		ctx.stroke_style("#ffd27a" if is_sel else "rgba(255,255,255,0.14)")
		ctx.line_width(2.2 if is_sel else 1.1)
		ctx.stroke()
		ctx.fill_style("#fff")
		ctx.font("20px serif")
		ctx.text_align("left")
		ctx.fill_text(str(it.get("icon", "•")), cx + 9, cy + 24)
		ctx.fill_style("#ffe08a" if is_sel else "#e6d8f0")
		ctx.font("bold 11px Trebuchet MS")
		ctx.fill_text(str(it.get("name", "")).substr(0, 18), cx + 36, cy + 17)
		ctx.fill_style("#b8a8c8")
		ctx.font("8.5px monospace")
		MenuHelpers.wrap_text(ctx, str(it.get("desc", "")), cx + 10, cy + 33, tW - 16, 9, 3)
		ctx.text_align("right")
		if str(it.get("kind")) == "consumable":
			ctx.fill_style("#9fe0a4")
			ctx.font("bold 9px monospace")
			ctx.fill_text("HAVE ×%d" % int(it.get("qty", 0)), cx + tW - 9, cy + tH - 18)
			ctx.fill_style("#bff0a0" if afford else "#ff9a9a")
			ctx.font("bold 11px monospace")
			ctx.fill_text("💀 %d" % cost, cx + tW - 9, cy + tH - 6)
		elif owned:
			ctx.fill_style("#8fd0a0")
			ctx.font("bold 10px monospace")
			ctx.fill_text("✓ OWNED", cx + tW - 9, cy + tH - 7)
		elif cost > 0:
			ctx.fill_style("#bff0a0" if afford else "#ff9a9a")
			ctx.font("bold 11px monospace")
			ctx.fill_text("💀 %d" % cost, cx + tW - 9, cy + tH - 7)
		ctx.global_alpha(1.0)
		shop_btns.append({"x": cx, "y": cy, "w": tW, "h": tH, "i": i})
	# HTML bottom: Honey Badger portrait + boss-style dialogue bar
	var hb = AssetBank.get_tex("honeybadger") if AssetBank else null
	var iw := 216.0
	var ih := roundf(iw * 473.0 / 527.0)
	var ix := 4.0
	var iy := H - 4.0 - ih
	if hb:
		ctx.draw_image(hb, ix, iy, iw, ih)
	elif badger:
		badger.drawHoneyBadger(66, H - 64, 0.66)
	var dx := 230.0
	var dw := W - dx - 14.0
	var dh := 64.0
	var dy := H - 172.0
	ctx.fill_style("rgba(20,12,6,0.92)")
	ctx.begin_path()
	ctx.round_rect(dx, dy, dw, dh, 8)
	ctx.fill()
	ctx.stroke_style("#ffb347")
	ctx.line_width(2)
	ctx.save()
	ctx.shadow_color("#ff9a2a")
	ctx.shadow_blur(12)
	ctx.stroke()
	ctx.restore()
	ctx.text_align("left")
	ctx.fill_style("#ffd27a")
	ctx.font("bold 15px Trebuchet MS")
	ctx.fill_text("Honey Badger", dx + 18, dy + 24)
	ctx.fill_style("#c8a878")
	ctx.font("italic 12px Trebuchet MS")
	ctx.fill_text("Reality-Bending Merchant", dx + 18, dy + 40)
	var lines := [
		"Heads only. No refunds. No regrets. Mostly.",
		"You break it, you bought it.",
		"A honey badger fears nothing. Except a slow day. Buy.",
		"Warranty void where reality is.",
		"Discounts? For you? …No.",
		"Come back richer. Or don’t come back.",
	]
	var line_i := int(floorf(float(tick) / 220.0)) % lines.size()
	ctx.fill_style("#fff")
	ctx.font("bold 14px Trebuchet MS")
	ctx.fill_text("“" + lines[line_i] + "”", dx + 18, dy + 58)
	if msg_t > 0.0 and msg != "":
		ctx.global_alpha(minf(1.0, msg_t / 20.0))
		var bad := msg.begins_with("Not") or msg.begins_with("Already") or msg.begins_with("Earn")
		ctx.fill_style("#ff9aa8" if bad else "#9fe0a4")
		ctx.font("bold 14px Trebuchet MS")
		ctx.text_align("center")
		ctx.fill_text(msg, W * 0.63, H - 96)
		ctx.global_alpha(1.0)
	# selected hint
	if sel >= 0 and sel < list.size():
		var sit: Dictionary = list[sel]
		var hint := ""
		var act := false
		if str(sit.get("kind")) == "gear" and bool(sit.get("owned", false)):
			hint = "✓ Already owned"
		elif str(sit.get("kind")) == "gear" and int(sit.get("cost", 0)) <= 0:
			hint = "🏅 Unlock this via its Emblem"
		elif heads >= int(sit.get("cost", 0)):
			hint = "[%s] / tap again to BUY — %s" % [MenuHelpers.kb("shoot"), sit.get("name", "")]
			act = true
		else:
			hint = "need %d more heads" % (int(sit.get("cost", 0)) - heads)
		ctx.fill_style("#fff" if act and (int(floorf(float(tick) / 16.0)) % 2) != 0 else ("#ffd27a" if act else "#a07a7a"))
		ctx.font("bold 12px monospace")
		ctx.text_align("center")
		ctx.fill_text(hint, W * 0.63, H - 62)
	ctx.fill_style("#fff" if (int(floorf(float(tick) / 26.0)) % 2) != 0 else "#9a7c96")
	ctx.font("bold 12px monospace")
	ctx.text_align("center")
	ctx.fill_text("◀▶ browse  ·  [%s] switch tab  ·  [%s] buy  ·  [%s] LEAVE" % [
		MenuHelpers.kb("swap"), MenuHelpers.kb("shoot"), MenuHelpers.kb("interact"),
	], W * 0.63, H - 32)
	ctx.text_align("left")

func _shop_list(tab: String) -> Array:
	var out: Array = []
	if tab == "i":
		for c in DataRegistry.consumables:
			var k := str(c.get("key"))
			out.append({
				"kind": "consumable", "key": k, "icon": c.get("icon", "•"),
				"name": c.get("name", k), "desc": c.get("desc", ""),
				"col": c.get("col", c.get("color", "#ffd27a")),
				"cost": int(c.get("cost", 20)),
				"qty": int(ProgressStore.progress.get("consum", {}).get(k, 0)),
			})
		return out
	if tab == "w":
		var order: Array = DataRegistry.weapon_order if DataRegistry.weapon_order.size() else DataRegistry.weapons.keys()
		for k in order:
			var w: Dictionary = DataRegistry.weapons.get(str(k), {})
			var owned := MenuHelpers.content_unlocked("w", str(k))
			out.append({
				"kind": "gear", "type": "w", "key": str(k),
				"icon": w.get("icon", "•"), "name": w.get("name", k),
				"desc": w.get("desc", ""), "col": w.get("col", "#ff8ac0"),
				"owned": owned, "cost": MenuHelpers.lock_cost("w", str(k)),
			})
	elif tab == "s":
		for s in DataRegistry.specials:
			var k2 := str(s.get("key"))
			out.append({
				"kind": "gear", "type": "s", "key": k2,
				"icon": s.get("icon", "★"), "name": s.get("name", k2),
				"desc": s.get("desc", ""), "col": s.get("col", "#b98cff"),
				"owned": MenuHelpers.content_unlocked("s", k2),
				"cost": MenuHelpers.lock_cost("s", k2),
			})
	else:
		for m in DataRegistry.melee:
			var k3 := str(m.get("key"))
			out.append({
				"kind": "gear", "type": "m", "key": k3,
				"icon": m.get("icon", "🗡"), "name": m.get("name", k3),
				"desc": m.get("desc", m.get("tag", "")), "col": m.get("col", "#ff8a6a"),
				"owned": MenuHelpers.content_unlocked("m", k3),
				"cost": MenuHelpers.lock_cost("m", k3),
			})
	return out

func draw_dialog(d: Dictionary) -> void:
	## HTML drawDialog — playfield-bottom bar, per-speaker style, portrait bust, grow-up height
	if d.is_empty():
		return
	var q: Array = d.get("queue", [])
	var i := int(d.get("i", 0))
	if i < 0 or i >= q.size():
		return
	var line = q[i]
	var txt := str(line.get("t", line) if line is Dictionary else line)
	var who := int(line.get("w", 0)) if line is Dictionary else 0
	var bd: Dictionary = d.get("boss", {}) if d.get("boss") is Dictionary else {}
	var pf: Rect2 = Config.playfield()
	var x := pf.position.x + 8.0
	var w := pf.size.x - 16.0
	var lh := 16.0
	# per-speaker styling: 0 = boss, 2 = Devil, else = Bobina
	var cfg: Dictionary
	if who == 0:
		cfg = {
			"portrait": str(bd.get("portrait", "ape")),
			"pcol": str(bd.get("color", "#ff9ecb")),
			"name": str(bd.get("name", "Boss")),
			"title": str(bd.get("title", "")),
			"bg": "rgba(12,6,16,0.9)",
			"stroke": str(bd.get("color", "#ff9ecb")),
			"ncol": str(bd.get("color", "#ff9ecb")),
			"tcol": "#c8b0c4",
			"txt": "#fff",
			"glow": null,
		}
	elif who == 2:
		cfg = {
			"portrait": "devil", "pcol": "#ff3b1a", "name": "The Devil",
			"title": "Collector of Debts", "bg": "rgba(24,4,4,0.94)",
			"stroke": "#ff3b1a", "ncol": "#ff7a3a", "tcol": "#d0a0a0",
			"txt": "#ffdccc", "glow": "#ff2a00",
		}
	else:
		cfg = {
			"portrait": "bobina", "pcol": "#ff6ec7", "name": "Bobina",
			"title": "Danmaku Bear", "bg": "rgba(22,8,20,0.92)",
			"stroke": "#ff6ec7", "ncol": "#ff9ecb", "tcol": "#c8b0c4",
			"txt": "#fff", "glow": null,
		}
	var quoted := "“" + txt + "”"
	var lines: Array = _wrap_dialog_lines(quoted, w - 92.0)
	var h := maxf(88.0, 52.0 + float(lines.size()) * lh)
	var y := pf.position.y + pf.size.y - 8.0 - h
	ctx.fill_style(cfg.bg)
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 8)
	ctx.fill()
	ctx.stroke_style(cfg.stroke)
	ctx.line_width(2)
	if cfg.glow != null:
		ctx.shadow_color(str(cfg.glow))
		ctx.shadow_blur(14)
	ctx.stroke()
	ctx.shadow_blur(0)
	# HTML drawPortraitBust + manageGifOverlays talk gif for Bobina lines
	if ported:
		ported.draw_portrait_bust(x + 40.0, y + h / 2.0, 58.0, str(cfg.portrait), str(cfg.pcol))
	if who == 1 and AssetBank and AssetBank.ok("talk"):
		var talk_tex = AssetBank.get_tex("talk")
		ctx.save()
		ctx.begin_path()
		ctx.arc(x + 40.0, y + h / 2.0, 29.0, 0, TAU)
		ctx.clip()
		ctx.draw_image(talk_tex, x + 40.0 - 28.0, y + h / 2.0 - 28.0, 56.0, 56.0)
		ctx.restore()
	ctx.text_align("left")
	ctx.fill_style(cfg.ncol)
	ctx.font("bold 15px Trebuchet MS")
	ctx.fill_text(str(cfg.name), x + 80.0, y + 22.0)
	ctx.fill_style(cfg.tcol)
	ctx.font("italic 12px Trebuchet MS")
	ctx.fill_text(str(cfg.title), x + 80.0, y + 38.0)
	ctx.fill_style(cfg.txt)
	ctx.font("bold 14px Trebuchet MS")
	var ty := y + 56.0
	for ln in lines:
		ctx.fill_text(str(ln), x + 80.0, ty)
		ty += lh

func _wrap_dialog_lines(t: String, maxw: float) -> Array:
	## HTML wrapLines
	ctx.font("bold 14px Trebuchet MS")
	var words := t.split(" ")
	var line := ""
	var out: Array = []
	for wd in words:
		var trial := line + wd + " "
		var mw := 0.0
		if ctx.has_method("measure_text"):
			mw = float(ctx.measure_text(trial).get("width", 0))
		else:
			mw = float(trial.length()) * 7.5
		if mw > maxw and line != "":
			out.append(line.strip_edges())
			line = wd + " "
		else:
			line = trial
	if line.strip_edges() != "":
		out.append(line.strip_edges())
	return out

