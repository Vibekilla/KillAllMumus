extends RefCounted
## HTML virtual joystick + right-rail touch buttons as canvas chrome (DOM #joybase/#tright).

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx
var tick: int = 0
var W: float = 960.0
var H: float = 540.0
## Hit targets for Main/JoyPad: {id, x, y, w, h, key}
var btns: Array = []

func setup(c) -> void:
	ctx = c
	W = Config.W
	H = Config.H

func set_tick(t: int) -> void:
	tick = t

func should_show() -> bool:
	if GameState.state != GameState.State.PLAY:
		return false
	if JoyPad and JoyPad.touch_ui_on:
		return true
	# Force-on when settings ui=touch
	if JoyPad and JoyPad.has_method("read_ui_override"):
		var o = JoyPad.read_ui_override()
		if o == true:
			return true
	return DisplayServer.is_touchscreen_available()

func draw() -> void:
	if not should_show() or ctx == null:
		return
	btns.clear()
	_draw_joystick()
	_draw_action_rail()
	_draw_pause_chip()

func _draw_joystick() -> void:
	## HTML #joybase / #joyknob — fixed seat bottom-left
	if JoyPad == null:
		return
	var base: Vector2 = JoyPad.home if JoyPad.home else JoyPad.joy_home_pos()
	# Keep JoyPad.cx/cy aligned to home (HTML fixed centre)
	if not JoyPad.active:
		JoyPad.cx = base.x
		JoyPad.cy = base.y
	else:
		base = Vector2(float(JoyPad.cx), float(JoyPad.cy))
	var idle := not JoyPad.active
	var a := 0.5 if idle else 1.0
	ctx.save()
	ctx.global_alpha(a)
	# base ring
	ctx.fill_style("rgba(40,22,52,0.55)")
	ctx.begin_path()
	ctx.arc(base.x, base.y, JoyPad.JOY_R + 12.0, 0, TAU)
	ctx.fill()
	ctx.stroke_style("rgba(255,150,200,0.55)")
	ctx.line_width(2.5)
	ctx.begin_path()
	ctx.arc(base.x, base.y, JoyPad.JOY_R + 12.0, 0, TAU)
	ctx.stroke()
	ctx.stroke_style("rgba(255,210,230,0.22)")
	ctx.line_width(1)
	ctx.begin_path()
	ctx.arc(base.x, base.y, JoyPad.JOY_R, 0, TAU)
	ctx.stroke()
	# knob
	var kx := base.x + float(JoyPad.vx) * JoyPad.JOY_R
	var ky := base.y + float(JoyPad.vy) * JoyPad.JOY_R
	ctx.fill_style("rgba(255,180,220,0.85)")
	ctx.begin_path()
	ctx.arc(kx, ky, 22.0, 0, TAU)
	ctx.fill()
	ctx.stroke_style("#ffdcec")
	ctx.line_width(2)
	ctx.stroke()
	ctx.restore()

func _draw_action_rail() -> void:
	## HTML #tright — util + main grids bottom-right
	var pad := 10.0
	var rail_w := 148.0
	var rx := W - rail_w - pad
	var ry := H - 210.0
	ctx.fill_style("rgba(16,9,22,0.6)")
	ctx.begin_path()
	ctx.round_rect(rx, ry, rail_w, 196.0, 16)
	ctx.fill()
	ctx.stroke_style("rgba(255,120,190,0.3)")
	ctx.line_width(1)
	ctx.stroke()
	# util row: fire, swap, meleeswap, cycle (special cycle)
	var util := [
		{"k": "fire", "label": _fire_label(), "col": "#ffe0b0", "border": "rgba(255,170,80,0.6)", "sm": true},
		{"k": "swap", "label": _swap_label(), "col": "#ffdcec", "border": "rgba(255,150,200,0.45)", "sm": true},
		{"k": "cycle", "label": "★\n⇄", "col": "#e8d0ff", "border": "rgba(200,140,255,0.55)", "sm": true},
		{"k": "meleeswap", "label": _melee_swap_label(), "col": "#ffd2d8", "border": "rgba(255,95,110,0.5)", "sm": true},
	]
	var ux := rx + 8.0
	var uy := ry + 10.0
	var uw := 52.0
	var uh := 40.0
	var ug := 8.0
	for i in range(util.size()):
		var u: Dictionary = util[i]
		var col_i := i % 2
		var row_i := int(i / 2)
		var bx := ux + float(col_i) * (uw + ug)
		var by := uy + float(row_i) * (uh + 6.0)
		_btn(bx, by, uw, uh, str(u.k), str(u.label), str(u.col), str(u.border), false)
	# main row: focus, bomb, special, melee
	var mx0 := rx + 8.0
	var my0 := ry + 108.0
	var mw := 62.0
	var mh := 52.0
	var mg := 8.0
	var main := [
		{"k": "focus", "label": "◎\nFOCUS", "col": "#dff2ff", "border": "rgba(150,220,255,0.6)"},
		{"k": "bomb", "label": _bomb_label(), "col": "#ffe8b0", "border": "rgba(255,210,120,0.6)"},
		{"k": "special", "label": _special_label(), "col": "#e8d0ff", "border": "rgba(200,140,255,0.6)", "ready": GameState.special_meter >= 100.0},
		{"k": "melee", "label": _melee_label(), "col": "#ffd2d8", "border": "rgba(255,95,110,0.6)"},
	]
	for i in range(main.size()):
		var m: Dictionary = main[i]
		var col_i2 := i % 2
		var row_i2 := int(i / 2)
		var bx2 := mx0 + float(col_i2) * (mw + mg)
		var by2 := my0 + float(row_i2) * (mh + mg)
		var ready := bool(m.get("ready", false))
		_btn(bx2, by2, mw, mh, str(m.k), str(m.label), str(m.col), str(m.border), ready)

func _btn(x: float, y: float, w: float, h: float, key: String, label: String, col: String, border: String, ready: bool) -> void:
	var bg := "rgba(220,120,40,0.6)" if ready else "rgba(42,24,54,0.78)"
	var bcol := "#ffd24a" if ready else border
	var tcol := "#fff" if ready else col
	if ready and (int(floorf(float(tick) / 8.0)) % 2) == 0:
		ctx.shadow_color("rgba(255,200,80,0.7)")
		ctx.shadow_blur(14)
	ctx.fill_style(bg)
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 12)
	ctx.fill()
	ctx.shadow_blur(0)
	ctx.stroke_style(bcol)
	ctx.line_width(1.5)
	ctx.stroke()
	ctx.fill_style(tcol)
	ctx.font("bold 11px Trebuchet MS")
	ctx.text_align("center")
	# multi-line label
	var parts := label.split("\n")
	var ly := y + h * 0.5 - float(parts.size() - 1) * 7.0
	for p in parts:
		ctx.fill_text(str(p), x + w * 0.5, ly)
		ly += 14.0
	ctx.text_align("left")
	btns.append({"x": x, "y": y, "w": w, "h": h, "key": key})

func _draw_pause_chip() -> void:
	var x := 12.0
	var y := 10.0
	var w := 38.0
	var h := 34.0
	ctx.fill_style("rgba(30,16,40,0.66)")
	ctx.begin_path()
	ctx.round_rect(x, y, w, h, 9)
	ctx.fill()
	ctx.stroke_style("rgba(255,150,200,0.45)")
	ctx.line_width(1)
	ctx.stroke()
	ctx.fill_style("#ffdcec")
	ctx.font("bold 15px Trebuchet MS")
	ctx.text_align("center")
	ctx.fill_text("Ⅱ", x + w * 0.5, y + 22.0)
	ctx.text_align("left")
	btns.append({"x": x, "y": y, "w": w, "h": h, "key": "pause"})

func _fire_label() -> String:
	## Hold to fire (maps to shoot action) — no separate autofire mode
	return "🔥\nFIRE"

func _swap_label() -> String:
	var icon := "⇄"
	var key := str(GameState.current_weapon)
	if DataRegistry and DataRegistry.weapons is Dictionary:
		var wp = DataRegistry.weapons.get(key, null)
		if wp is Dictionary:
			icon = str(wp.get("icon", "⇄"))
		else:
			# weapons.json may be {order:[], by id:...} or flat map
			for k in DataRegistry.weapons.keys():
				var v = DataRegistry.weapons[k]
				if v is Dictionary and (str(k) == key or str(v.get("id", "")) == key):
					icon = str(v.get("icon", "⇄"))
					break
	return icon + "\nSWAP"

func _bomb_label() -> String:
	return "✸\n×%d" % maxi(0, GameState.bombs)

func _special_label() -> String:
	var sp := float(GameState.special_meter)
	if sp >= 100.0:
		return "★\nUSE!"
	return "★\n%d%%" % int(floorf(sp))

func _melee_label() -> String:
	var icon := "⚔"
	var player = _player()
	var mi := 0
	if player and "melee" in player:
		mi = int(player.melee)
	elif player and "melee_key" in player:
		# string key index via arsenal
		pass
	if DataRegistry and DataRegistry.melee is Array and mi >= 0 and mi < DataRegistry.melee.size():
		var m = DataRegistry.melee[mi]
		if m is Dictionary:
			icon = str(m.get("icon", "⚔"))
	var chg := 0.0
	if player:
		if "melee_chg" in player:
			chg = float(player.melee_chg)
		elif "meleeChg" in player:
			chg = float(player.meleeChg)
	if chg > 0.0:
		return "%s\n%d%%" % [icon, int(roundf(chg * 100.0))]
	return icon + "\nMELEE"

func _melee_swap_label() -> String:
	var icon := "🗡"
	if DataRegistry and DataRegistry.melee is Array and DataRegistry.melee.size() > 0:
		var player = _player()
		var mi := 0
		if player and "melee" in player:
			mi = int(player.melee)
		mi = (mi + 1) % DataRegistry.melee.size()
		var m = DataRegistry.melee[mi]
		if m is Dictionary:
			icon = str(m.get("icon", "🗡"))
	return icon + "\nMEL⇄"

func hit_key(pos: Vector2) -> String:
	for b in btns:
		if MenuHelpers.in_btn(pos, b):
			return str(b.get("key", ""))
	return ""

func _player() -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D
