extends RefCounted
## 1:1 HTML drawPanel + playfield overlays (toasts, veil, slowmo, boss ambience).

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx
var tick: int = 0
var W: float = 960.0
var H: float = 540.0
var _stage_bg_drawer = null

func setup(c) -> void:
	ctx = c
	W = Config.W
	H = Config.H
	_stage_bg_drawer = null

func set_tick(t: int) -> void:
	tick = t

func _hex_a(h, a) -> String:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return "rgba(%d,%d,%d,%s)" % [(n >> 16) & 255, (n >> 8) & 255, n & 255, str(a)]

func _rgb_hue(r: float, g: float, b: float) -> float:
	r /= 255.0
	g /= 255.0
	b /= 255.0
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var d := mx - mn
	if d < 0.0001:
		return 0.0
	var hh := 0.0
	if is_equal_approx(mx, r):
		hh = fmod(((g - b) / d), 6.0)
	elif is_equal_approx(mx, g):
		hh = (b - r) / d + 2.0
	else:
		hh = (r - g) / d + 4.0
	return hh * 60.0

func draw_stage_bg() -> void:
	## HTML drawStageBg — prefer full drawer (gradient + motifs + drawStageBgFx)
	if _stage_bg_drawer == null:
		var sc = load("res://scripts/render/drawers/drawStageBg.gd")
		if sc:
			_stage_bg_drawer = sc.new()
			if _stage_bg_drawer.has_method("setup"):
				_stage_bg_drawer.setup(ctx)
	if _stage_bg_drawer:
		if _stage_bg_drawer.has_method("set_tick"):
			_stage_bg_drawer.set_tick(tick)
		if _stage_bg_drawer.has_method("drawStageBg"):
			_stage_bg_drawer.drawStageBg()
			# border
			var pf: Rect2 = Config.PLAYFIELD
			ctx.stroke_style("rgba(255,120,190,0.35)")
			ctx.line_width(2)
			ctx.begin_path()
			ctx.round_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y, 4)
			ctx.stroke()
			return
	# fallback solid gradient halves
	var s := GameState.stage_index
	var top := "#0b2412"
	var bot := "#193f1f"
	match s:
		1:
			top = "#0b1a30"
			bot = "#1c3f60"
		2:
			top = "#0d200d"
			bot = "#1f501c"
		3:
			top = "#150826"
			bot = "#2c1648"
		4:
			top = "#241808"
			bot = "#3f2c0d"
		5:
			top = "#0a0a1e"
			bot = "#1b1746"
		6:
			top = "#240812"
			bot = "#4e1019"
	var pf2: Rect2 = Config.PLAYFIELD
	ctx.fill_style(top)
	ctx.fill_rect(pf2.position.x, pf2.position.y, pf2.size.x, pf2.size.y * 0.55)
	ctx.fill_style(bot)
	ctx.fill_rect(pf2.position.x, pf2.position.y + pf2.size.y * 0.45, pf2.size.x, pf2.size.y * 0.55)
	draw_stage_bg_fx(s)
	ctx.stroke_style("rgba(255,120,190,0.35)")
	ctx.line_width(2)
	ctx.begin_path()
	ctx.round_rect(pf2.position.x, pf2.position.y, pf2.size.x, pf2.size.y, 4)
	ctx.stroke()

func draw_stage_bg_fx(s: int) -> void:
	## HTML drawStageBgFx — simplified geometric psychedelic layers
	var t := float(tick)
	var pf: Rect2 = Config.PLAYFIELD
	var cx := pf.position.x + pf.size.x * 0.5
	var cy := pf.position.y + pf.size.y * 0.42
	var Hpf := pf.size.y
	ctx.save()
	# clip playfield
	var bi := 0.5
	var boss := _boss()
	if boss and not bool(boss.get("dead")):
		var intro_v2 = boss.get("intro")
		if intro_v2 == null or float(intro_v2) <= 0.0:
			var rage := 0.8
			var st2 = boss.get("special_t")
			if st2 != null and float(st2) > 0.0:
				rage += 0.4
			var mhp2 = boss.get("max_hp")
			var hp2 = boss.get("hp")
			if mhp2 != null and hp2 != null and float(mhp2) > 0.0:
				rage += (1.0 - float(hp2) / float(mhp2)) * 0.35
			bi = minf(1.4, rage)
	match s:
		0:  # jungle rings
			for L in range(4):
				var rr := (0.2 + float(L) * 0.2) * Hpf
				ctx.stroke_style("hsla(%d,55%%,%d%%,%s)" % [140 + L * 16, 18 + L * 5, str(0.13 + 0.07 * bi)])
				ctx.line_width(2.4)
				ctx.begin_path()
				ctx.arc(cx, cy, rr * (1.0 + sin(t * 0.01 + float(L)) * 0.05), 0, TAU)
				ctx.stroke()
		1:  # ice hex lattice
			ctx.stroke_style("hsla(200,60%,30%,%s)" % str(0.12 + 0.08 * bi))
			ctx.line_width(1.5)
			for i in range(8):
				var a0 := t * 0.004 + float(i) * 0.4
				ctx.begin_path()
				for k in range(7):
					var a := a0 + float(k) / 6.0 * TAU
					var r := 40.0 + float(i) * 18.0
					var px := cx + cos(a) * r
					var py := cy + sin(a) * r * 0.7
					if k == 0:
						ctx.move_to(px, py)
					else:
						ctx.line_to(px, py)
				ctx.stroke()
		3, 5:  # cosmic / akashic rings
			for L in range(5):
				ctx.stroke_style("hsla(%d,70%%,40%%,%s)" % [270 + L * 12, str(0.1 + 0.08 * bi)])
				ctx.line_width(1.8)
				ctx.begin_path()
				ctx.arc(cx, cy, 30 + float(L) * 22 + sin(t * 0.02 + float(L)) * 4, 0, TAU)
				ctx.stroke()
		_:
			for L in range(3):
				ctx.stroke_style("hsla(%d,50%%,25%%,%s)" % [s * 40 + L * 20, str(0.1 + 0.06 * bi)])
				ctx.line_width(2)
				ctx.begin_path()
				ctx.arc(cx, cy + float(L) * 10, 50 + float(L) * 30, 0, TAU)
				ctx.stroke()
	ctx.restore()

func draw_boss_ambience() -> void:
	## HTML drawBossAmbience
	var boss := _boss()
	if boss == null:
		return
	if bool(boss.get("dead")):
		return
	var intro_v = boss.get("intro")
	if intro_v != null and float(intro_v) > 0.0:
		return
	var col_s := "#ff5b6e"
	var data = boss.get("data")
	if data is Dictionary:
		col_s = str(data.get("color", col_s))
	elif boss.get("color") != null:
		var c: Color = boss.color
		col_s = "#%02x%02x%02x" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
	var cr := _hex_rgb(col_s)
	var bh := _rgb_hue(float(cr[0]), float(cr[1]), float(cr[2]))
	var pf: Rect2 = Config.PLAYFIELD
	var cx := pf.position.x + pf.size.x * 0.5
	var cy := pf.position.y + pf.size.y * 0.42
	var rage := 0.6
	var st = boss.get("special_t")
	if st != null and float(st) > 0.0:
		rage += 0.5
	var mhp = boss.get("max_hp")
	var hp = boss.get("hp")
	if mhp != null and hp != null and float(mhp) > 0.0:
		rage += (1.0 - float(hp) / float(mhp)) * 0.5
	rage = minf(1.6, rage)
	ctx.save()
	ctx.fill_style("hsla(%d,60%%,5%%,%s)" % [int(bh), str(0.26 + 0.14 * rage)])
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	ctx.fill_style("rgba(3,1,6,%s)" % str(0.1 + 0.12 * rage))
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	# rotating mandala
	var t := float(tick)
	ctx.global_composite_operation("lighter")
	for L in range(4):
		ctx.stroke_style("hsla(%d,80%%,55%%,%s)" % [int(bh + float(L) * 18.0), str(0.08 + 0.06 * rage)])
		ctx.line_width(1.5)
		ctx.begin_path()
		var N := 6 + L
		var a0 := t * 0.01 * (1.0 if L % 2 == 0 else -1.0)
		var rr := 40.0 + float(L) * 28.0
		for i in range(N + 1):
			var a := a0 + float(i) / float(N) * TAU
			var px := cx + cos(a) * rr
			var py := cy + sin(a) * rr * 0.75
			if i == 0:
				ctx.move_to(px, py)
			else:
				ctx.line_to(px, py)
		ctx.stroke()
	ctx.restore()

func draw_panel() -> void:
	## HTML drawPanel landscape
	var x := Config.PANEL.position.x
	var y := Config.PANEL.position.y
	var w := Config.PANEL.size.x
	var ph := Config.PANEL.size.y
	ctx.fill_style("rgba(18,10,24,0.6)")
	ctx.begin_path()
	ctx.round_rect(x, y, w, ph, 10)
	ctx.fill()
	ctx.stroke_style("rgba(255,120,190,0.25)")
	ctx.line_width(1)
	ctx.stroke()
	var cy := y + 24.0
	ctx.text_align("left")
	ctx.fill_style("#ff7ab5")
	ctx.font("900 18px Trebuchet MS")
	ctx.fill_text("KILL ALL", x + 16, cy)
	cy += 19
	ctx.fill_style("#ffd27a")
	ctx.fill_text("MUMUS!!", x + 16, cy)
	cy += 6
	ctx.stroke_style("rgba(255,255,255,0.12)")
	ctx.begin_path()
	ctx.move_to(x + 14, cy)
	ctx.line_to(x + w - 14, cy)
	ctx.stroke()
	cy += 20
	if GameState.state == GameState.State.TITLE:
		return
	var st: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 11px monospace")
	ctx.fill_text("%s — %s" % [st.get("title", ""), st.get("name", "")], x + 16, cy)
	cy += 20
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("SCORE", x + 16, cy)
	ctx.text_align("right")
	ctx.fill_style("#fff")
	ctx.font("bold 15px monospace")
	ctx.fill_text(MenuHelpers.fmt_score(GameState.session_score), x + w - 16, cy)
	ctx.text_align("left")
	cy += 22
	# mumus box
	ctx.fill_style("rgba(255,90,120,0.14)")
	ctx.begin_path()
	ctx.round_rect(x + 12, cy - 13, w - 24, 44, 8)
	ctx.fill()
	ctx.fill_style("#ff9ab0")
	ctx.font("bold 10px monospace")
	ctx.fill_text("MUMUS EXTERMINATED", x + 22, cy - 1)
	ctx.fill_style("#fff")
	ctx.font("900 24px Trebuchet MS")
	ctx.fill_text(str(GameState.total_kills), x + 22, cy + 22)
	ctx.text_align("right")
	ctx.fill_style("#ffd27a")
	ctx.font("900 24px Trebuchet MS")
	ctx.fill_text(GameState.rank_letter(), x + w - 22, cy + 18)
	ctx.fill_style("#c8b0c4")
	ctx.font("9px monospace")
	ctx.fill_text("x%.1f" % GameState.score_mul(), x + w - 22, cy + 29)
	ctx.text_align("left")
	var to_next := CombatHelpers.KILL_EXTEND - (GameState.total_kills % CombatHelpers.KILL_EXTEND)
	ctx.fill_style("#9fe0a4")
	ctx.font("8px monospace")
	ctx.fill_text("♥ 1UP in %d" % to_next, x + w * 0.5 - 6, cy + 22)
	cy += 48
	# power — HTML: label + Lv/MAX% on same row, gradient bar
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("POWER", x + 16, cy)
	var pfrac := clampf((GameState.power - 1.0) / 5.0, 0.0, 1.0)
	var lv := CombatHelpers.shot_level()
	ctx.fill_style("#ffd27a")
	ctx.font("bold 12px monospace")
	ctx.text_align("right")
	var lvtxt := "Lv%d MAX" % lv if lv >= 5 else "Lv%d  %d%%" % [lv, int(round(pfrac * 100))]
	ctx.fill_text(lvtxt, x + w - 16, cy)
	ctx.text_align("left")
	cy += 8
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, w - 32, 10, 4)
	ctx.fill()
	var pw := (w - 32) * pfrac
	if pw > 0.5:
		var pg = ctx.create_linear_gradient(x + 16, 0, x + w - 16, 0)
		pg.addColorStop(0, "#ff6ec7")
		pg.addColorStop(1, "#ffd27a")
		ctx.fill_style(pg)
		ctx.begin_path()
		ctx.round_rect(x + 16, cy, pw, 10, 4)
		ctx.fill()
	cy += 28
	# lives / bombs
	ctx.fill_style("#ff6ec7")
	ctx.font("bold 14px monospace")
	ctx.fill_text("❤ ×%d" % maxi(0, GameState.lives), x + 16, cy)
	ctx.fill_style("#ffd27a")
	ctx.fill_text("✸ ×%d" % GameState.bombs, x + w * 0.5, cy)
	cy += 24
	# special meter
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("SPECIAL", x + 16, cy)
	cy += 8
	var sfrac := clampf(GameState.special_meter / 100.0, 0.0, 1.0)
	ctx.fill_style("#1a2030")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, w - 32, 10, 4)
	ctx.fill()
	ctx.fill_style("#b98cff" if sfrac < 1.0 else "#ffe08a")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, (w - 32) * sfrac, 10, 4)
	ctx.fill()
	# HTML READY — tap ★ when special full
	if sfrac >= 1.0:
		ctx.fill_style("#fff" if (int(floorf(float(tick) / 8.0)) % 2) != 0 else "#1a0e14")
		ctx.font("bold 8px monospace")
		ctx.text_align("center")
		ctx.fill_text("READY — tap ★", x + w / 2.0, cy + 19)
		ctx.text_align("left")
	cy += 26
	# weapon chip
	ctx.fill_style("#ff8ac0")
	ctx.font("bold 10px monospace")
	var wpn := GameState.current_weapon
	var wname := wpn
	if DataRegistry.weapons.has(wpn):
		wname = str(DataRegistry.weapons[wpn].get("name", wpn))
	ctx.fill_text("WPN  " + wname, x + 16, cy)
	cy += 16
	ctx.fill_style("#b98cff")
	var spn := "—"
	if GameState.specials.size():
		var sk := str(GameState.specials[0])
		for s in DataRegistry.specials:
			if str(s.get("key")) == sk:
				spn = str(s.get("name", sk))
				break
	ctx.fill_text("SPEC " + spn, x + 16, cy)
	cy += 16
	# HTML 🦍 MONKE rapid-fire badge
	var player = _player()
	if player and float(player.get("rapid_t")) > 0.0:
		var bx := x + 16.0
		ctx.fill_style("rgba(255,225,74,0.95)")
		ctx.begin_path()
		ctx.round_rect(bx, cy - 9, 84, 14, 4)
		ctx.fill()
		ctx.fill_style("#2a2200")
		ctx.font("bold 9px monospace")
		ctx.fill_text("🦍 MONKE %ds" % int(ceili(float(player.get("rapid_t")) / 60.0)), bx + 5, cy + 1)
		cy += 16
	ctx.fill_style("#c8b0d0")
	ctx.font("10px monospace")
	ctx.fill_text("MODE " + GameState.mode_tag(), x + 16, cy)
	cy += 18
	# heads
	ctx.fill_style("#ffd27a")
	ctx.font("bold 12px monospace")
	ctx.fill_text("💀 %d" % int(ProgressStore.progress.get("heads", 0)), x + 16, cy)
	# consumable chips row (HTML ITEMS)
	cy += 18
	_draw_item_chips(x + 16, cy, w - 32)
	# portrait strip bottom of panel
	cy = y + ph - 90
	ctx.fill_style("rgba(0,0,0,0.25)")
	ctx.begin_path()
	ctx.round_rect(x + 12, cy, w - 24, 78, 8)
	ctx.fill()
	var tex = null
	if AssetBank:
		tex = AssetBank.get_tex("portrait")
		if tex == null:
			tex = AssetBank.get_tex("peephole")
	if tex:
		ctx.draw_image(tex, x + 20, cy + 8, 62, 62)
	ctx.fill_style("#ff9ecb")
	ctx.font("bold 12px Trebuchet MS")
	ctx.fill_text("Bobina", x + 92, cy + 28)
	ctx.fill_style("#c8b0d0")
	ctx.font("10px monospace")
	ctx.fill_text(str(GameState.selected_outfit).to_upper(), x + 92, cy + 46)

func _draw_item_chips(x: float, cy: float, max_w: float) -> void:
	## HTML consumables row in panel
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("ITEMS", x, cy)
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var ai: Array = ar.get("i", []) if ar else []
	var consum = null
	var player = _player()
	if player and player.get("consumables"):
		consum = player.consumables
	var ix := x
	var sel := int(consum.selected) if consum else 0
	for i in range(ai.size()):
		var key := str(ai[i])
		var def := {}
		for c in DataRegistry.consumables:
			if str(c.get("key")) == key:
				def = c
				break
		var qty := int(ProgressStore.progress.get("consum", {}).get(key, 0))
		var selected := i == sel
		ctx.fill_style(str(def.get("color", def.get("col", "#ffcf5a"))) if selected else "rgba(40,30,50,0.9)")
		ctx.begin_path()
		ctx.round_rect(ix, cy + 4, 30, 17, 4)
		ctx.fill()
		if selected:
			ctx.stroke_style("#fff")
			ctx.line_width(1.5)
			ctx.stroke()
		ctx.fill_style("#1a1020" if selected else "#e8d6f0")
		ctx.font("12px monospace")
		ctx.fill_text(str(def.get("icon", "•")), ix + 6, cy + 16)
		if qty > 0:
			ctx.fill_style("#ffd27a")
			ctx.font("bold 8px monospace")
			ctx.fill_text("×%d" % qty, ix + 18, cy + 10)
		ix += 34
		if ix > x + max_w - 30:
			break
	if ai.is_empty():
		ctx.fill_style("#6a5a72")
		ctx.font("9px monospace")
		ctx.fill_text("— none equipped —", x, cy + 16)

func draw_emblem_toasts() -> void:
	if ProgressStore == null:
		return
	var toasts: Array = ProgressStore.get_meta("emblem_toasts", []) if ProgressStore.has_meta("emblem_toasts") else []
	if toasts.is_empty():
		return
	var e: Dictionary = toasts[0]
	e["t"] = int(e.get("t", 0)) + 1
	toasts[0] = e
	ProgressStore.set_meta("emblem_toasts", toasts)
	var d := _emblem_def(str(e.get("id", "")))
	if d.is_empty():
		toasts.pop_front()
		ProgressStore.set_meta("emblem_toasts", toasts)
		return
	var T := int(e.get("t", 0))
	var dur := 210
	var a := 1.0
	if T < 16:
		a = float(T) / 16.0
	elif T > dur - 22:
		a = maxf(0.0, float(dur - T) / 22.0)
	var w := 308.0
	var h := 54.0
	var x := W / 2.0 - w / 2.0
	var y := 14.0
	ctx.save()
	ctx.global_alpha(a)
	ctx.fill_style("rgba(18,10,26,0.96)")
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 12)
	ctx.fill()
	ctx.stroke_style("#ffd27a")
	ctx.line_width(2)
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(14)
	ctx.stroke()
	ctx.shadow_blur(0)
	ctx.text_align("left")
	ctx.font("26px serif")
	ctx.fill_text(str(d.get("icon", "🏅")), x + 14, y + 36)
	ctx.fill_style("#ffe08a")
	ctx.font("bold 10px monospace")
	ctx.fill_text("★  EMBLEM UNLOCKED", x + 52, y + 19)
	ctx.fill_style("#fff")
	ctx.font("bold 15px Trebuchet MS")
	ctx.fill_text(str(d.get("name", "")), x + 52, y + 38)
	if d.get("outfit"):
		ctx.fill_style("#8fd0a0")
		ctx.font("bold 9px monospace")
		ctx.text_align("right")
		ctx.fill_text("👗 SKIN", x + w - 12, y + 19)
	ctx.restore()
	if T >= dur:
		toasts.pop_front()
		ProgressStore.set_meta("emblem_toasts", toasts)

func draw_phase_veil() -> void:
	var p := _player()
	if p == null or float(p.get("phase_t") if p.get("phase_t") != null else 0.0) <= 0.0:
		return
	var pf: Rect2 = Config.PLAYFIELD
	ctx.save()
	ctx.fill_style("rgba(14,4,34,0.66)")
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	ctx.fill_style("rgba(40,8,70,0.35)")
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	# drifting motes
	for i in range(12):
		var a := float(tick) * 0.05 + float(i)
		ctx.fill_style("rgba(180,120,255,0.35)")
		ctx.begin_path()
		ctx.arc(pf.position.x + fposmod(a * 40.0 + float(i) * 50.0, pf.size.x), pf.position.y + fposmod(a * 30.0 + float(i) * 37.0, pf.size.y), 2, 0, TAU)
		ctx.fill()
	ctx.restore()

func draw_slowmo_fx() -> void:
	if not GameState.has_meta("slowmo"):
		return
	var slowmo_t := float(GameState.get_meta("slowmo"))
	var a := minf(1.0, slowmo_t / 45.0) * minf(1.0, (300.0 - slowmo_t) / 16.0 + 0.25)
	var pf: Rect2 = Config.PLAYFIELD
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.global_alpha(0.09 * a)
	ctx.fill_style("#2ac6ff")
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	var p := _player()
	if p:
		ctx.global_alpha(0.4 * a)
		ctx.stroke_style("#bff0ff")
		ctx.line_width(1.6)
		for k in range(3):
			var ph := fmod(float(tick) * 0.02 + float(k) / 3.0, 1.0)
			ctx.global_alpha((1.0 - ph) * 0.4 * a)
			ctx.begin_path()
			ctx.arc(p.global_position.x, p.global_position.y, 10 + ph * 95, 0, TAU)
			ctx.stroke()
	ctx.restore()

func draw_hell_portal(b: Dictionary) -> void:
	var R := float(b.get("hellR", 0))
	if R <= 1.0:
		return
	var cx := float(b.get("x", 0))
	var cy := float(b.get("y", 0))
	if b.has("hy"):
		cy = float(b.get("hy", cy))
	ctx.save()
	ctx.translate(cx, cy)
	ctx.fill_style("#3a0008")
	ctx.begin_path()
	ctx.ellipse(0, 0, R * 1.16, R * 0.76, 0, 0, TAU)
	ctx.fill()
	var sp := float(b.get("hellT", 0)) * 0.12
	var cols := ["#ff5a1a", "#ff2a00", "#c01020", "#7a0818", "#3a0410"]
	for i in range(5):
		var rr := R * (1.0 - float(i) * 0.16)
		ctx.stroke_style(cols[i])
		ctx.line_width(3)
		ctx.global_alpha(0.9)
		ctx.begin_path()
		var a := 0.0
		var first := true
		while a <= 6.3:
			var r := rr + sin(a * 3.0 + sp + float(i)) * R * 0.05
			var px := cos(a + sp + float(i) * 0.5) * r
			var py := sin(a + sp + float(i) * 0.5) * r * 0.66
			if first:
				ctx.move_to(px, py)
				first = false
			else:
				ctx.line_to(px, py)
			a += 0.3
		ctx.close_path()
		ctx.stroke()
	ctx.global_alpha(1.0)
	ctx.fill_style("#08020a")
	ctx.begin_path()
	ctx.ellipse(0, 0, R * 0.4, R * 0.26, 0, 0, TAU)
	ctx.fill()
	ctx.restore()

func draw_pause_overlay() -> void:
	ctx.fill_style("rgba(6,4,12,0.72)")
	ctx.fill_rect(0, 0, W, H)
	ctx.text_align("center")
	ctx.fill_style("#ffe08a")
	ctx.font("900 40px Trebuchet MS")
	ctx.fill_text("⏸ PAUSED", W / 2.0, H / 2.0 - 20)
	ctx.fill_style("#c8b0d0")
	ctx.font("14px monospace")
	ctx.fill_text("PRESS ESC / P TO RESUME", W / 2.0, H / 2.0 + 20)
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.fill_text("⌂ MAIN MENU  [M]", W / 2.0, H / 2.0 + 56)
	ctx.text_align("left")

func _hex_rgb(h) -> Array:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return [(n >> 16) & 255, (n >> 8) & 255, n & 255]

func _emblem_def(id: String) -> Dictionary:
	for e in DataRegistry.emblems:
		if str(e.get("id")) == id:
			return e
	return {}

func _player() -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D

func _boss() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var bosses := tree.get_nodes_in_group("bosses")
	if bosses.is_empty():
		return null
	return bosses[0]
