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
	W = Config.W
	H = Config.H

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
			var pf: Rect2 = Config.playfield()
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
	var pf2: Rect2 = Config.playfield()
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
	var pf: Rect2 = Config.playfield()
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
	var pf: Rect2 = Config.playfield()
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
	## HTML drawPanel — portrait | touch | landscape
	if Config.portrait:
		_draw_panel_portrait()
		return
	if JoyPad and JoyPad.touch_ui_on:
		_draw_panel_touch()
		return
	_draw_panel_landscape()

func _draw_panel_portrait() -> void:
	## HTML drawPanelPortrait — top bar + bottom strip
	var pf: Rect2 = Config.playfield()
	var panel: Rect2 = Config.panel()
	var WW := Config.W
	# TOP BAR
	ctx.fill_style("rgba(16,9,22,0.82)")
	ctx.fill_rect(0, 0, WW, pf.position.y - 6.0)
	ctx.stroke_style("rgba(255,120,190,0.22)")
	ctx.line_width(1)
	ctx.begin_path()
	ctx.move_to(0, pf.position.y - 6.0)
	ctx.line_to(WW, pf.position.y - 6.0)
	ctx.stroke()
	if GameState.state == GameState.State.TITLE:
		return
	var st: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	ctx.text_align("left")
	ctx.fill_style("#e8d6f0")
	ctx.font("9px monospace")
	ctx.fill_text("SCORE", 14, 15)
	ctx.fill_style("#fff")
	ctx.font("bold 21px monospace")
	ctx.fill_text(MenuHelpers.fmt_score(GameState.session_score), 14, 37)
	ctx.fill_style("#8fd0ff")
	ctx.font("8px monospace")
	ctx.fill_text(("%s · %s" % [st.get("title", ""), st.get("name", "")]).substr(0, 34), 14, 50)
	ctx.text_align("right")
	ctx.fill_style("#ffd27a")
	ctx.font("900 24px Trebuchet MS")
	ctx.fill_text(GameState.rank_letter(), WW - 135, 30)
	ctx.fill_style("#ff9ab0")
	ctx.font("bold 10px monospace")
	ctx.fill_text("%d MUMUS  ×%.1f" % [GameState.total_kills, GameState.score_mul()], WW - 135, 47)
	ctx.text_align("left")
	ctx.fill_style("#e8d6f0")
	ctx.font("9px monospace")
	ctx.fill_text("LIVES", 14, 68)
	for i in range(maxi(0, GameState.lives)):
		_draw_heart(52 + i * 15.0, 64, 5.4)
	ctx.text_align("right")
	ctx.fill_style("#e8d6f0")
	ctx.font("9px monospace")
	ctx.fill_text("BOMBS", WW - 92, 68)
	ctx.fill_style("#ff8ad6")
	ctx.font("13px monospace")
	ctx.text_align("left")
	for i in range(GameState.bombs):
		ctx.fill_text("✸", WW - 84 + i * 15.0, 69)
	if GameState.difficulty > 0 or GameState.ng_plus > 0:
		ctx.text_align("center")
		ctx.fill_style("#ff2a2a" if GameState.difficulty >= 2 else "#ff5b6e")
		ctx.font("bold 9px monospace")
		ctx.fill_text("★" + GameState.mode_tag(), WW / 2.0, 68)
	ctx.text_align("left")
	# BOTTOM STRIP
	var x := 14.0
	var w := WW - 28.0
	var by := panel.position.y + 6.0
	var pfrac := clampf((GameState.power - 1.0) / 5.0, 0.0, 1.0)
	var lv := CombatHelpers.shot_level()
	ctx.fill_style("#e8d6f0")
	ctx.font("10px monospace")
	ctx.fill_text("POWER", x, by + 8)
	ctx.text_align("right")
	ctx.fill_style("#ffd27a")
	ctx.font("bold 11px monospace")
	var lvtxt := "Lv%d MAX" % lv if lv >= 5 else "Lv%d  %d%%" % [lv, int(round(pfrac * 100))]
	ctx.fill_text(lvtxt, x + w, by + 8)
	ctx.text_align("left")
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x, by + 12, w, 8, 3)
	ctx.fill()
	if pfrac > 0.0:
		var pg = ctx.create_linear_gradient(x, 0, x + w, 0)
		pg.addColorStop(0, "#ff6ec7")
		pg.addColorStop(1, "#ffd27a")
		ctx.fill_style(pg)
		ctx.begin_path()
		ctx.round_rect(x, by + 12, maxf(0.0, w * pfrac), 8, 3)
		ctx.fill()
	for i in range(1, 5):
		var lx := x + w * (float(i) / 5.0)
		ctx.stroke_style("rgba(0,0,0,0.4)")
		ctx.begin_path()
		ctx.move_to(lx, by + 12)
		ctx.line_to(lx, by + 20)
		ctx.stroke()
	by += 28
	# SPECIAL (HTML armedSpec)
	var sp_arm: Dictionary = _armed_spec()
	var sp_col := str(sp_arm.get("col", "#b98cff"))
	var sp_name := str(sp_arm.get("name", "None"))
	var sp_icon := str(sp_arm.get("icon", "—"))
	var ready := GameState.special_meter >= 100.0
	ctx.fill_style("#e8d6f0")
	ctx.font("10px monospace")
	ctx.fill_text("SPECIAL", x, by + 8)
	ctx.text_align("right")
	ctx.fill_style(sp_col)
	ctx.font("bold 10px monospace")
	ctx.fill_text("%s %s" % [sp_icon, sp_name], x + w, by + 8)
	ctx.text_align("left")
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x, by + 12, w, 8, 3)
	ctx.fill()
	ctx.fill_style(sp_col)
	ctx.global_alpha(1.0 if ready else 0.85)
	ctx.begin_path()
	ctx.round_rect(x, by + 12, w * clampf(GameState.special_meter / 100.0, 0.0, 1.0), 8, 3)
	ctx.fill()
	ctx.global_alpha(1.0)
	if ready:
		ctx.fill_style("#fff" if (int(floorf(float(tick) / 8.0)) % 2) != 0 else "#1a0e14")
		ctx.font("bold 8px monospace")
		ctx.text_align("center")
		ctx.fill_text("READY — tap ★", x + w / 2.0, by + 19)
		ctx.text_align("left")
	by += 28
	# weapon / melee / graze
	var wpn := GameState.current_weapon
	var wlabel := wpn
	if DataRegistry.weapons.has(wpn):
		var wd: Dictionary = DataRegistry.weapons[wpn]
		wlabel = "%s %s" % [wd.get("icon", ""), wd.get("name", wpn)]
	ctx.fill_style("#c8b0c4")
	ctx.font("10px monospace")
	ctx.fill_text(wlabel, x, by + 8)
	var mdefp: Dictionary = _current_melee_def()
	ctx.text_align("center")
	ctx.fill_style(str(mdefp.get("col", "#ff8a6a")))
	ctx.fill_text("%s %s" % [str(mdefp.get("icon", "⚔")), str(mdefp.get("name", "MELEE"))], WW / 2.0, by + 8)
	ctx.text_align("right")
	ctx.fill_style("#8fd0ff")
	ctx.fill_text("GRAZE %d" % GameState.graze, x + w, by + 8)
	ctx.text_align("left")
	by += 22
	_draw_boss_or_progress(x, by, w)

func _draw_panel_touch() -> void:
	## HTML drawPanelTouch — compact top-of-panel readout
	var panel: Rect2 = Config.panel()
	var x := panel.position.x
	var y := panel.position.y
	var w := panel.size.x
	ctx.fill_style("rgba(18,10,24,0.6)")
	ctx.begin_path()
	ctx.round_rect(x, y, w, 196, 10)
	ctx.fill()
	ctx.stroke_style("rgba(255,120,190,0.25)")
	ctx.line_width(1)
	ctx.stroke()
	if GameState.state == GameState.State.TITLE:
		return
	var st: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	var cy := y + 20.0
	ctx.text_align("left")
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 11px monospace")
	ctx.fill_text(("%s — %s" % [st.get("title", ""), st.get("name", "")]).substr(0, 30), x + 14, cy)
	cy += 20
	ctx.fill_style("#e8d6f0")
	ctx.font("10px monospace")
	ctx.fill_text("SCORE", x + 14, cy)
	ctx.text_align("right")
	ctx.fill_style("#fff")
	ctx.font("bold 17px monospace")
	ctx.fill_text(MenuHelpers.fmt_score(GameState.session_score), x + w - 14, cy + 2)
	ctx.text_align("left")
	cy += 24
	ctx.fill_style("#ff9ab0")
	ctx.font("bold 11px monospace")
	ctx.fill_text("MUMUS  %d" % GameState.total_kills, x + 14, cy)
	ctx.text_align("right")
	ctx.fill_style("#c8b0c4")
	ctx.font("9px monospace")
	ctx.fill_text("×%.1f" % GameState.score_mul(), x + w - 42, cy)
	ctx.fill_style("#ffd27a")
	ctx.font("900 22px Trebuchet MS")
	ctx.fill_text(GameState.rank_letter(), x + w - 14, cy + 3)
	ctx.text_align("left")
	cy += 22
	var pfrac := clampf((GameState.power - 1.0) / 5.0, 0.0, 1.0)
	ctx.fill_style("#e8d6f0")
	ctx.font("10px monospace")
	ctx.fill_text("POWER Lv%d" % CombatHelpers.shot_level(), x + 14, cy)
	ctx.text_align("right")
	ctx.fill_style("#8fd0ff")
	ctx.fill_text("GRAZE %d" % GameState.graze, x + w - 14, cy)
	ctx.text_align("left")
	cy += 5
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x + 14, cy, w - 28, 7, 3)
	ctx.fill()
	if pfrac > 0.0:
		var pg = ctx.create_linear_gradient(x + 14, 0, x + w - 14, 0)
		pg.addColorStop(0, "#ff6ec7")
		pg.addColorStop(1, "#ffd27a")
		ctx.fill_style(pg)
		ctx.begin_path()
		ctx.round_rect(x + 14, cy, (w - 28) * pfrac, 7, 3)
		ctx.fill()
	cy += 18
	ctx.fill_style("#e8d6f0")
	ctx.font("10px monospace")
	ctx.fill_text("LIVES", x + 14, cy)
	for i in range(maxi(0, GameState.lives)):
		_draw_heart(x + 50 + i * 14.0, cy - 4, 5)
	ctx.fill_style("#ff8ad6")
	ctx.font("12px monospace")
	ctx.text_align("right")
	var bs := ""
	for i in range(GameState.bombs):
		bs += "✸"
	ctx.fill_text(bs if bs != "" else "—", x + w - 14, cy)
	ctx.text_align("left")
	cy += 18
	_draw_boss_or_progress(x + 14, cy, w - 28)
	if GameState.difficulty > 0 or GameState.ng_plus > 0:
		ctx.fill_style("#ff2a2a" if GameState.difficulty >= 2 else "#ff5b6e")
		ctx.font("bold 9px monospace")
		ctx.text_align("right")
		ctx.fill_text("★" + GameState.mode_tag(), x + w - 14, y + 14)
		ctx.text_align("left")

func _draw_boss_or_progress(x: float, cy: float, w: float) -> void:
	var boss = _boss()
	if boss and not bool(boss.get("dead")) and float(boss.get("intro") if boss.get("intro") != null else 0) <= 0.0:
		var col := "#ff5b3c"
		var nm := "BOSS"
		if boss.get("data") is Dictionary:
			col = str(boss.data.get("color", col))
			nm = str(boss.get("hudName") if boss.get("hudName") else boss.data.get("name", "BOSS"))
		ctx.fill_style(col)
		ctx.font("bold 11px Trebuchet MS")
		ctx.fill_text(nm.substr(0, 24), x, cy)
		cy += 5
		ctx.fill_style("#3a1020")
		ctx.begin_path()
		ctx.round_rect(x, cy, w, 9, 3)
		ctx.fill()
		var hp := float(boss.get("hp") if boss.get("hp") != null else 1)
		var maxhp := maxf(1.0, float(boss.get("maxhp") if boss.get("maxhp") != null else hp))
		var g = ctx.create_linear_gradient(x, 0, x + w, 0)
		g.addColorStop(0, "#ff3b30")
		g.addColorStop(1, col)
		ctx.fill_style(g)
		ctx.begin_path()
		ctx.round_rect(x, cy, w * clampf(hp / maxhp, 0.0, 1.0), 9, 3)
		ctx.fill()
	else:
		var prog := _stage_progress()
		ctx.fill_style("#c8b0c4")
		ctx.font("10px monospace")
		ctx.fill_text("STAGE PROGRESS", x, cy)
		cy += 5
		ctx.fill_style("#2a1a30")
		ctx.begin_path()
		ctx.round_rect(x, cy, w, 6, 3)
		ctx.fill()
		ctx.fill_style("#8fd35a")
		ctx.begin_path()
		ctx.round_rect(x, cy, w * prog, 6, 3)
		ctx.fill()

func _draw_heart(cx: float, cy: float, r: float) -> void:
	## HTML drawHeart — cubic bezier heart (not circle pair)
	ctx.fill_style("#ff4d8d")
	ctx.begin_path()
	ctx.move_to(cx, cy + r * 0.3)
	ctx.bezier_curve_to(cx, cy - r * 0.5, cx - r, cy - r * 0.5, cx - r, cy + r * 0.1)
	ctx.bezier_curve_to(cx - r, cy + r * 0.7, cx, cy + r, cx, cy + r * 1.3)
	ctx.bezier_curve_to(cx, cy + r, cx + r, cy + r * 0.7, cx + r, cy + r * 0.1)
	ctx.bezier_curve_to(cx + r, cy - r * 0.5, cx, cy - r * 0.5, cx, cy + r * 0.3)
	ctx.fill()

func _draw_panel_landscape() -> void:
	## HTML drawPanel landscape — full side panel 1:1 (WEAPON/MELEE/ITEMS/GRAZE/STAGE PROGRESS)
	var panel: Rect2 = Config.panel()
	var x := panel.position.x
	var y := panel.position.y
	var w := panel.size.x
	var ph := panel.size.y
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
	# HTML: if(!run) return; after title chrome
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
	# MUMU counter box
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
	if to_next <= 0:
		to_next = CombatHelpers.KILL_EXTEND
	ctx.fill_style("#9fe0a4")
	ctx.font("8px monospace")
	ctx.fill_text("♥ 1UP in %d" % to_next, x + w * 0.5 - 6, cy + 22)
	cy += 48
	# POWER meter
	var pfrac := clampf((GameState.power - 1.0) / 5.0, 0.0, 1.0)
	var lv := CombatHelpers.shot_level()
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("POWER", x + 16, cy)
	ctx.text_align("right")
	ctx.fill_style("#ffd27a")
	ctx.font("bold 12px monospace")
	var lvtxt := "Lv%d MAX" % lv if lv >= 5 else "Lv%d  %d%%" % [lv, int(round(pfrac * 100))]
	ctx.fill_text(lvtxt, x + w - 16, cy)
	ctx.text_align("left")
	cy += 6
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, w - 32, 9, 3)
	ctx.fill()
	var pw := (w - 32) * pfrac
	if pw > 0.0:
		var pg = ctx.create_linear_gradient(x + 16, 0, x + w - 16, 0)
		pg.addColorStop(0, "#ff6ec7")
		pg.addColorStop(1, "#ffd27a")
		ctx.fill_style(pg)
		ctx.begin_path()
		ctx.round_rect(x + 16, cy, maxf(0.0, pw), 9, 3)
		ctx.fill()
	# flames lick up off the filled bar
	if pfrac > 0.04 and pw > 4.0:
		ctx.save()
		ctx.global_composite_operation("lighter")
		var nfl := maxi(1, int(floor(pw / 6.0)))
		for i in range(nfl):
			var fx := x + 18 + float(i) * 6.0
			var fh := (2.5 + pfrac * 8.0) * (0.5 + 0.5 * absf(sin(float(tick) * 0.32 + float(i) * 1.2)))
			var fg = ctx.create_linear_gradient(fx, cy, fx, cy - fh)
			var r_flame := int(170.0 - pfrac * 90.0)
			fg.addColorStop(0, "rgba(255,%d,70,%s)" % [r_flame, str(0.5 + pfrac * 0.4)])
			fg.addColorStop(1, "rgba(255,240,140,0)")
			ctx.fill_style(fg)
			ctx.begin_path()
			ctx.move_to(fx - 2.4, cy)
			ctx.quadratic_curve_to(fx, cy - fh * 0.7, fx + sin(float(tick) * 0.2 + float(i)) * 1.6, cy - fh)
			ctx.quadratic_curve_to(fx, cy - fh * 0.7, fx + 2.4, cy)
			ctx.close_path()
			ctx.fill()
		ctx.restore()
	for i in range(1, 5):
		var lx := x + 16 + (w - 32) * (float(i) / 5.0)
		ctx.stroke_style("rgba(0,0,0,0.4)")
		ctx.begin_path()
		ctx.move_to(lx, cy)
		ctx.line_to(lx, cy + 9)
		ctx.stroke()
	cy += 20
	# WEAPON row
	var wpn_key := GameState.current_weapon
	var wpn_def: Dictionary = DataRegistry.weapons.get(wpn_key, {}) if DataRegistry.weapons.has(wpn_key) else {}
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("WEAPON", x + 16, cy)
	ctx.text_align("right")
	ctx.fill_style(str(wpn_def.get("col", "#ff8ac0")))
	ctx.font("bold 10px monospace")
	ctx.fill_text(str(wpn_def.get("name", wpn_key)), x + w - 16, cy)
	ctx.text_align("left")
	cy += 6
	var wx := x + 16.0
	for wk in GameState.weapons:
		var cur := (GameState.current_weapon == str(wk))
		var wd: Dictionary = DataRegistry.weapons.get(str(wk), {}) if DataRegistry.weapons.has(str(wk)) else {}
		ctx.fill_style(str(wd.get("col", "#ff8ac0")) if cur else "#3a2a44")
		ctx.begin_path()
		ctx.round_rect(wx, cy, 30, 17, 4)
		ctx.fill()
		if cur:
			ctx.stroke_style("#fff")
			ctx.line_width(1.2)
			ctx.stroke()
		ctx.fill_style("#1a0e14" if cur else "#d8c8e0")
		ctx.font("bold 11px monospace")
		ctx.text_align("center")
		ctx.fill_text(str(wd.get("icon", "•")), wx + 15, cy + 13)
		ctx.text_align("left")
		wx += 34
	if GameState.weapons.size() > 1:
		ctx.fill_style("#6a5a72")
		ctx.font("9px monospace")
		ctx.text_align("right")
		ctx.fill_text("[%s] swap" % MenuHelpers.kb("swap"), x + w - 14, cy + 13)
		ctx.text_align("left")
	cy += 28
	# SPECIAL meter + chips
	var sp: Dictionary = _armed_spec()
	var sp_col := str(sp.get("col", "#6a5a72"))
	var ready := GameState.special_meter >= 100.0
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("SPECIAL", x + 16, cy)
	ctx.text_align("right")
	ctx.fill_style(sp_col)
	ctx.font("bold 10px monospace")
	ctx.fill_text("%s %s" % [str(sp.get("icon", "—")), str(sp.get("name", "None"))], x + w - 16, cy)
	ctx.text_align("left")
	cy += 6
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, w - 32, 9, 3)
	ctx.fill()
	ctx.fill_style(sp_col)
	ctx.global_alpha(1.0 if ready else 0.85)
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, (w - 32) * clampf(GameState.special_meter / 100.0, 0.0, 1.0), 9, 3)
	ctx.fill()
	ctx.global_alpha(1.0)
	if ready:
		ctx.fill_style("#fff" if (int(floorf(float(tick) / 8.0)) % 2) != 0 else sp_col)
		ctx.font("bold 8px monospace")
		ctx.text_align("center")
		ctx.fill_text("READY! [%s]" % MenuHelpers.kb("special"), x + 16 + (w - 32) / 2.0, cy + 7.5)
		ctx.text_align("left")
	cy += 18
	if GameState.specials.size() > 0:
		var sx := x + 16.0
		var armed_i := _armed_special_index()
		for si in range(GameState.specials.size()):
			var sk := str(GameState.specials[si])
			var s2 := _special_by_key(sk)
			if s2.is_empty():
				continue
			var scur := (si == armed_i)
			ctx.fill_style(str(s2.get("col", "#b98cff")) if scur else "#3a2a44")
			ctx.begin_path()
			ctx.round_rect(sx, cy, 30, 17, 4)
			ctx.fill()
			if scur:
				ctx.stroke_style("#fff")
				ctx.line_width(1.2)
				ctx.stroke()
			ctx.fill_style("#1a0e14" if scur else "#d8c8e0")
			ctx.font("bold 11px monospace")
			ctx.text_align("center")
			ctx.fill_text(str(s2.get("icon", "★")), sx + 15, cy + 13)
			ctx.text_align("left")
			sx += 34
		if GameState.specials.size() > 1:
			ctx.fill_style("#6a5a72")
			ctx.font("9px monospace")
			ctx.text_align("right")
			ctx.fill_text("[%s] cycle" % MenuHelpers.kb("cycle"), x + w - 14, cy + 13)
			ctx.text_align("left")
		cy += 28
	# MELEE row
	var mdef: Dictionary = _current_melee_def()
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("MELEE", x + 16, cy)
	ctx.text_align("right")
	ctx.fill_style(str(mdef.get("col", "#ff8a6a")))
	ctx.font("bold 10px monospace")
	ctx.fill_text(str(mdef.get("name", "Melee")), x + w - 16, cy)
	ctx.text_align("left")
	cy += 5
	ctx.fill_style("#2a1a30")
	ctx.begin_path()
	ctx.round_rect(x + 16, cy, w - 32, 5, 2)
	ctx.fill()
	var player = _player()
	var chg := 0.0
	if player and player.get("melee"):
		var ms = player.melee
		if ms and bool(ms.get("holding")):
			chg = float(ms.get("charge") if ms.get("charge") != null else 0.0)
	if chg > 0.0:
		ctx.fill_style("#fff" if chg >= 1.0 else str(mdef.get("col", "#ff8a6a")))
		ctx.begin_path()
		ctx.round_rect(x + 16, cy, (w - 32) * chg, 5, 2)
		ctx.fill()
	else:
		ctx.fill_style("#6a5a72")
		ctx.font("8px monospace")
		ctx.text_align("center")
		var tip := "MELEE btn: hold · MEL⇄ switch" if (JoyPad and JoyPad.touch_ui_on) else "[%s] swipe · hold · [%s] switch" % [MenuHelpers.kb("melee"), MenuHelpers.kb("meleeswap")]
		ctx.fill_text(tip, x + 16 + (w - 32) / 2.0, cy + 4.6)
		ctx.text_align("left")
	cy += 13
	var melee_idxs: Array = _melee_idx_list()
	if melee_idxs.size() > 0:
		var mx := x + 16.0
		var cur_mi := _current_melee_index()
		for mi in melee_idxs:
			var mii := int(mi)
			if mii < 0 or mii >= DataRegistry.melee.size():
				continue
			var m2: Dictionary = DataRegistry.melee[mii]
			var mcur := (mii == cur_mi)
			ctx.fill_style(str(m2.get("col", "#ff8a6a")) if mcur else "#3a2a44")
			ctx.begin_path()
			ctx.round_rect(mx, cy, 30, 17, 4)
			ctx.fill()
			if mcur:
				ctx.stroke_style("#fff")
				ctx.line_width(1.2)
				ctx.stroke()
			ctx.fill_style("#1a0e14" if mcur else "#d8c8e0")
			ctx.font("bold 11px monospace")
			ctx.text_align("center")
			ctx.fill_text(str(m2.get("icon", "🗡")), mx + 15, cy + 13)
			ctx.text_align("left")
			mx += 34
		if melee_idxs.size() > 1:
			ctx.fill_style("#6a5a72")
			ctx.font("9px monospace")
			ctx.text_align("right")
			ctx.fill_text("[%s] switch" % MenuHelpers.kb("meleeswap"), x + w - 14, cy + 13)
			ctx.text_align("left")
		cy += 28
	# ITEMS / consumables row
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {}) if ProgressStore else {}
	var arsenal_i: Array = ar.get("i", []) if ar.get("i") is Array else []
	var consum = null
	if player and player.get("consumables"):
		consum = player.consumables
	var sel := int(consum.selected) if consum else 0
	if sel >= arsenal_i.size():
		sel = 0
	var cur_c: Dictionary = {}
	if arsenal_i.size() and consum and consum.has_method("consum_by_id"):
		cur_c = consum.consum_by_id(str(arsenal_i[sel]))
	elif arsenal_i.size():
		cur_c = _consum_by_id(str(arsenal_i[sel]))
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("ITEMS", x + 16, cy)
	if not cur_c.is_empty():
		ctx.text_align("right")
		ctx.fill_style(str(cur_c.get("col", cur_c.get("color", "#ffd27a"))))
		ctx.font("bold 10px monospace")
		ctx.fill_text(str(cur_c.get("name", "")), x + w - 16, cy)
		ctx.text_align("left")
	cy += 6
	var ix := x + 16.0
	for i in range(arsenal_i.size()):
		var ckey := str(arsenal_i[i])
		var c: Dictionary = _consum_by_id(ckey)
		if c.is_empty():
			continue
		var csel := (i == sel)
		var q := 0
		if consum and consum.has_method("qty"):
			q = int(consum.qty(ckey))
		else:
			q = int(ProgressStore.progress.get("consum", {}).get(ckey, 0)) if ProgressStore else 0
		ctx.global_alpha(1.0 if q > 0 else 0.5)
		ctx.fill_style(str(c.get("col", c.get("color", "#ffd27a"))) if csel else "#3a2a44")
		ctx.begin_path()
		ctx.round_rect(ix, cy, 30, 17, 4)
		ctx.fill()
		if csel:
			ctx.stroke_style("#fff")
			ctx.line_width(1.2)
			ctx.stroke()
		ctx.fill_style("#1a0e14" if csel else "#d8c8e0")
		ctx.font("bold 11px monospace")
		ctx.text_align("center")
		ctx.fill_text(str(c.get("icon", "•")), ix + 15, cy + 13)
		ctx.fill_style("#1a0e14" if csel else "#9fe0a4")
		ctx.font("bold 8px monospace")
		ctx.text_align("right")
		ctx.fill_text(str(q), ix + 28, cy + 7)
		ctx.text_align("left")
		ctx.global_alpha(1.0)
		ix += 34
	if arsenal_i.is_empty():
		ctx.fill_style("#6a5a72")
		ctx.font("9px monospace")
		ctx.fill_text("— none equipped —", x + 16, cy + 12)
	# hold / cooldown bar under chips
	var bar_w := maxf(0.0, float(arsenal_i.size()) * 34.0 - 4.0)
	var hp := 0.0
	if consum and not cur_c.is_empty() and bool(consum.get("e_held")) and not bool(consum.get("e_used")):
		hp = minf(1.0, float(consum.get("e_t") if consum.get("e_t") != null else 0.0) / 48.0)
	if hp > 0.0 and bar_w > 0.0:
		ctx.fill_style(str(cur_c.get("col", cur_c.get("color", "#ffd27a"))))
		ctx.fill_rect(x + 16, cy + 19, bar_w * hp, 2.5)
	elif consum and float(consum.get("e_cd") if consum.get("e_cd") != null else 0.0) > 0.0 and bar_w > 0.0:
		ctx.fill_style("#6a5a72")
		ctx.fill_rect(x + 16, cy + 19, bar_w * clampf(float(consum.e_cd) / 180.0, 0.0, 1.0), 2.5)
	ctx.fill_style("#6a5a72")
	ctx.font("9px monospace")
	ctx.text_align("right")
	ctx.fill_text("[%s] switch · hold [%s]" % [MenuHelpers.kb("item_switch"), MenuHelpers.kb("item_use")], x + w - 14, cy + 13)
	ctx.text_align("left")
	cy += 30
	# LIVES + life-frag pips
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("LIVES", x + 16, cy)
	for i in range(maxi(0, GameState.lives)):
		_draw_heart(x + 56 + float(i) * 14.0, cy - 2.5, 5)
	var life_frags := 0
	if ItemSystem:
		life_frags = int(ItemSystem.life_frags)
	for i in range(5):
		ctx.fill_style("#ff6ec7" if i < life_frags else "#3a2a40")
		ctx.begin_path()
		ctx.arc(x + w - 56 + float(i) * 9.0, cy - 3.5, 2.6, 0, TAU)
		ctx.fill()
	cy += 18
	# BOMBS + bomb-frag pips
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("BOMBS", x + 16, cy)
	for i in range(GameState.bombs):
		ctx.fill_style("#ff8ad6")
		ctx.font("12px monospace")
		ctx.fill_text("✸", x + 58 + float(i) * 14.0, cy + 1)
	var bomb_frags := 0
	if ItemSystem:
		bomb_frags = int(ItemSystem.bomb_frags)
	for i in range(3):
		ctx.fill_style("#ffd27a" if i < bomb_frags else "#3a2a40")
		ctx.begin_path()
		ctx.arc(x + w - 38 + float(i) * 9.0, cy - 3.5, 2.6, 0, TAU)
		ctx.fill()
	cy += 18
	# GRAZE + HEADS
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("GRAZE", x + 16, cy)
	ctx.fill_style("#8fd0ff")
	ctx.font("bold 12px monospace")
	ctx.fill_text(str(GameState.graze), x + 58, cy)
	ctx.text_align("right")
	ctx.fill_style("#ffd27a")
	ctx.font("bold 12px monospace")
	var heads := int(ProgressStore.progress.get("heads", 0)) if ProgressStore else 0
	ctx.fill_text("💀 %d" % heads, x + w - 16, cy)
	ctx.text_align("left")
	cy += 18
	# active buff chips
	if player and (float(player.get("shield_t") if player.get("shield_t") != null else 0.0) > 0.0 or float(player.get("rapid_t") if player.get("rapid_t") != null else 0.0) > 0.0):
		var bx := x + 16.0
		ctx.font("bold 10px monospace")
		if float(player.get("shield_t") if player.get("shield_t") != null else 0.0) > 0.0:
			ctx.fill_style("rgba(232,168,96,0.95)")
			ctx.begin_path()
			ctx.round_rect(bx, cy - 9, 86, 14, 4)
			ctx.fill()
			ctx.fill_style("#2a1606")
			ctx.fill_text("🐻 BOBO %ds" % int(ceili(float(player.shield_t) / 60.0)), bx + 5, cy + 1)
			bx += 92
		if float(player.get("rapid_t") if player.get("rapid_t") != null else 0.0) > 0.0:
			ctx.fill_style("rgba(255,225,74,0.95)")
			ctx.begin_path()
			ctx.round_rect(bx, cy - 9, 84, 14, 4)
			ctx.fill()
			ctx.fill_style("#2a2200")
			ctx.fill_text("🦍 MONKE %ds" % int(ceili(float(player.rapid_t) / 60.0)), bx + 5, cy + 1)
		cy += 16
	# boss bar or stage progress (landscape sizes)
	_draw_boss_or_progress_landscape(x + 16, cy, w - 32)
	# footer control hints (HTML uses PANEL.h absolute y from top of canvas)
	ctx.fill_style("#6a5a72")
	ctx.font("10px monospace")
	var footer_y := y + ph
	if JoyPad and JoyPad.touch_ui_on:
		ctx.fill_text("Stick moves · FIRE toggles auto-shoot", x + 16, footer_y - 30)
		ctx.fill_text("MELEE · SPEC · BOMB · FOCUS (2× = dash)", x + 16, footer_y - 18)
	else:
		ctx.fill_text("Mouse/arrows move · HOLD %s fire" % MenuHelpers.kb("shoot"), x + 16, footer_y - 30)
		ctx.fill_text("SHIFT focus · %s bomb · %s swap" % [MenuHelpers.kb("bomb"), MenuHelpers.kb("swap")], x + 16, footer_y - 18)
	if GameState.difficulty > 0 or GameState.ng_plus > 0:
		ctx.fill_style("#ff2a2a" if GameState.difficulty >= 2 else "#ff5b6e")
		ctx.font("bold 10px monospace")
		ctx.fill_text("★ %s MODE" % GameState.mode_tag(), x + 16, footer_y - 44)

func _draw_boss_or_progress_landscape(x: float, cy: float, bw: float) -> void:
	## HTML landscape boss / STAGE PROGRESS block (sizes differ from touch)
	var boss = _boss()
	if boss and not bool(boss.get("dead")) and float(boss.get("intro") if boss.get("intro") != null else 0) <= 0.0:
		var col := "#ff5b3c"
		var nm := "BOSS"
		if boss.get("data") is Dictionary:
			col = str(boss.data.get("color", col))
			nm = str(boss.get("hudName") if boss.get("hudName") else boss.data.get("name", "BOSS"))
		ctx.fill_style(col)
		ctx.font("bold 13px Trebuchet MS")
		ctx.fill_text(nm, x, cy)
		cy += 6
		ctx.fill_style("#3a1020")
		ctx.begin_path()
		ctx.round_rect(x, cy, bw, 10, 3)
		ctx.fill()
		var hp := float(boss.get("hp") if boss.get("hp") != null else 1)
		var maxhp := maxf(1.0, float(boss.get("maxhp") if boss.get("maxhp") != null else hp))
		var g = ctx.create_linear_gradient(x, 0, x + bw, 0)
		g.addColorStop(0, "#ff3b30")
		g.addColorStop(1, col)
		ctx.fill_style(g)
		ctx.begin_path()
		ctx.round_rect(x, cy, bw * clampf(hp / maxhp, 0.0, 1.0), 10, 3)
		ctx.fill()
		cy += 15
		if bool(boss.get("twin")):
			var active := str(boss.get("active") if boss.get("active") != null else "igor")
			var o := "grichka" if active == "igor" else "igor"
			var tw = boss.get("tw")
			var ofrac := 0.0
			var done := false
			if tw is Dictionary and tw.get(o) is Dictionary:
				var tslot: Dictionary = tw[o]
				done = bool(tslot.get("done", false))
				if not done:
					var thp := float(tslot.get("hp", 0))
					var tmax := maxf(1.0, float(tslot.get("max", 1)))
					ofrac = thp / tmax
			ctx.fill_style("#241633")
			ctx.begin_path()
			ctx.round_rect(x, cy, bw, 5, 2)
			ctx.fill()
			ctx.fill_style("#4a4a55" if done else "#9d6bff")
			ctx.begin_path()
			ctx.round_rect(x, cy, bw * ofrac, 5, 2)
			ctx.fill()
			ctx.fill_style("#b8a0d0")
			ctx.font("8px monospace")
			ctx.text_align("right")
			var oname := "Igor" if o == "igor" else "Grichka"
			ctx.fill_text(oname + (" ✕ down" if done else ""), x + bw, cy - 2)
			ctx.text_align("left")
		else:
			var phases := int(boss.get("phases") if boss.get("phases") != null else 0)
			var phase := int(boss.get("phase") if boss.get("phase") != null else 0)
			for i in range(phases):
				ctx.fill_style("#ffd27a" if i <= phase else "#5a4a55")
				ctx.begin_path()
				ctx.arc(x + 6 + float(i) * 16.0, cy + 4, 4, 0, TAU)
				ctx.fill()
	else:
		var prog := _stage_progress()
		ctx.fill_style("#c8b0c4")
		ctx.font("11px monospace")
		ctx.fill_text("STAGE PROGRESS", x, cy)
		cy += 6
		ctx.fill_style("#2a1a30")
		ctx.begin_path()
		ctx.round_rect(x, cy, bw, 8, 3)
		ctx.fill()
		ctx.fill_style("#8fd35a")
		ctx.begin_path()
		ctx.round_rect(x, cy, bw * prog, 8, 3)
		ctx.fill()

func _stage_progress() -> float:
	var spawner = null
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		spawner = tree.root.get_node_or_null("/root/Main/EnemySpawner")
		if spawner == null:
			spawner = tree.get_first_node_in_group("enemy_spawner")
	var stg: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	var wave_dur := float(stg.get("waveDur", 1500))
	if spawner and "stage_time" in spawner:
		return clampf(float(spawner.stage_time) / maxf(1.0, wave_dur), 0.0, 1.0)
	return 0.0

func _armed_special_index() -> int:
	var player = _player()
	if player and player.get("armed_special") != null:
		return int(player.armed_special) % maxi(1, GameState.specials.size())
	return 0

func _armed_spec() -> Dictionary:
	## HTML armedSpec()
	if GameState.specials.is_empty():
		return {"col": "#6a5a72", "icon": "—", "name": "None"}
	var i := _armed_special_index()
	var key := str(GameState.specials[i])
	var s := _special_by_key(key)
	if s.is_empty():
		return {"col": "#6a5a72", "icon": "—", "name": key}
	return s

func _special_by_key(key: String) -> Dictionary:
	for s in DataRegistry.specials:
		if str(s.get("key")) == key:
			return s
	return {}

func _melee_idx_list() -> Array:
	if P2Meta and P2Meta.has_method("melee_idx_list"):
		var lst: Array = P2Meta.melee_idx_list()
		if lst.size():
			return lst
	var out: Array = []
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {}) if ProgressStore else {}
	var ms: Array = ar.get("m", ["katana"]) if ar.get("m") is Array else ["katana"]
	if ms.is_empty():
		ms = ["katana"]
	for k in ms:
		for i in range(DataRegistry.melee.size()):
			if str(DataRegistry.melee[i].get("key")) == str(k):
				out.append(i)
				break
	return out

func _current_melee_index() -> int:
	var lst := _melee_idx_list()
	if lst.is_empty():
		return 0
	return int(lst[0])

func _current_melee_def() -> Dictionary:
	var i := _current_melee_index()
	if i >= 0 and i < DataRegistry.melee.size():
		return DataRegistry.melee[i]
	if DataRegistry.melee.size():
		return DataRegistry.melee[0]
	return {"name": "Melee", "icon": "⚔", "col": "#ff8a6a"}

func _consum_by_id(key: String) -> Dictionary:
	for c in DataRegistry.consumables:
		if str(c.get("key")) == key:
			return c
	return {}

func _draw_item_chips(x: float, cy: float, max_w: float) -> void:
	## Kept for callers; landscape draws ITEMS inline 1:1 with HTML
	ctx.fill_style("#e8d6f0")
	ctx.font("11px monospace")
	ctx.fill_text("ITEMS", x, cy)
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {}) if ProgressStore else {}
	var ai: Array = ar.get("i", []) if ar else []
	var consum = null
	var player = _player()
	if player and player.get("consumables"):
		consum = player.consumables
	var ix := x
	var sel := int(consum.selected) if consum else 0
	for i in range(ai.size()):
		var key := str(ai[i])
		var def := _consum_by_id(key)
		var qty := int(ProgressStore.progress.get("consum", {}).get(key, 0)) if ProgressStore else 0
		if consum and consum.has_method("qty"):
			qty = int(consum.qty(key))
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
	var pf: Rect2 = Config.playfield()
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
	var pf: Rect2 = Config.playfield()
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
	## Visual pause card is PauseMenu Control (HTML #pausescreen).
	## Keep this empty so we don't double-draw over the full overlay.
	pass

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
