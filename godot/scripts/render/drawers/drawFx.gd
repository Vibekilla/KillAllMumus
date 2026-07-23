extends RefCounted
## 1:1 port of HTML drawFx — special FX overlays (laser beam, mech, bombs, etc).

var ctx
var tick: int = 0
var _mech

func setup(c) -> void:
	ctx = c
	_mech = load("res://scripts/render/drawers/drawMech.gd").new()
	if _mech and _mech.has_method("setup"):
		_mech.setup(c)

func set_tick(t: int) -> void:
	tick = t
	if _mech and _mech.has_method("set_tick"):
		_mech.set_tick(t)

func drawFx(fx_list: Array = []) -> void:
	## HTML drawFx — defaults to SpecialSystem.fx on the player
	var list: Array = fx_list
	if list.is_empty():
		list = _collect_fx()
	var pf: Rect2 = Config.PLAYFIELD
	var player = _player()
	for f in list:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var typ = str(f.get("type", ""))
		match typ:
			"laser":
				_fx_laser(f, pf, player)
			"mech":
				_fx_mech(f, player)
			"bearzooka":
				_fx_bearzooka(f)
			"bombdrop":
				_fx_bombdrop(f)
			"blackhole":
				_fx_blackhole(f)
			"wave":
				_fx_wave(f, pf)
			"bull":
				_fx_bull(f)
			"badger":
				_fx_badger(f)
			"kiss":
				_fx_kiss(f, pf)
			"bubble":
				_fx_bubble(f)
			"stardust":
				_fx_stardust(f)
			"tentacle":
				_fx_tentacle(f)
			"servitor":
				_fx_servitor(f)
			_:
				pass

func _collect_fx() -> Array:
	var out: Array = []
	var p = _player()
	if p and p.get("specials") != null:
		var sp = p.specials
		if sp and sp.get("fx") is Array:
			out = (sp.fx as Array).duplicate()
	# ItemSystem bubbles / stardust may also live as fx-like dicts
	if ItemSystem:
		if ItemSystem.get("fx") is Array:
			for x in ItemSystem.fx:
				out.append(x)
	return out

func _player() -> Node:
	var tree = Engine.get_main_loop()
	if tree and tree is SceneTree:
		return (tree as SceneTree).get_first_node_in_group("player")
	return null

func _body_ctr(p: Node) -> Vector2:
	if p == null:
		return Vector2.ZERO
	return p.global_position + Vector2(0, -16)

func _circle(x: float, y: float, r: float, col: String) -> void:
	ctx.fill_style(col)
	ctx.begin_path()
	ctx.arc(x, y, r, 0, TAU)
	ctx.fill()

func _fx_laser(f: Dictionary, pf: Rect2, player: Node) -> void:
	var px = float(f.get("x", NAN))
	var py = float(f.get("y", NAN))
	var ang = float(f.get("ang", NAN))
	if is_nan(px) or is_nan(py):
		if player:
			px = player.global_position.x
			py = player.global_position.y
		else:
			px = pf.position.x + pf.size.x * 0.5
			py = pf.position.y + pf.size.y - 70.0
	if is_nan(ang):
		ang = -PI / 2.0
	var L = pf.size.x + pf.size.y
	var hw = float(f.get("w", 58)) * 0.5
	var ft = float(f.get("t", 64))
	ctx.save()
	ctx.begin_path()
	ctx.rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	ctx.clip()
	ctx.translate(px, py)
	ctx.rotate(ang + PI / 2.0)
	ctx.global_alpha(0.85 * minf(1.0, (64.0 - ft) / 6.0) * minf(1.0, ft / 12.0))
	# HTML linear gradient across beam width
	var g = ctx.create_linear_gradient(-hw, 0, hw, 0)
	g.addColorStop(0, "rgba(168,85,247,0)")
	g.addColorStop(0.5, "#a855f7")
	g.addColorStop(1, "rgba(168,85,247,0)")
	ctx.fill_style(g)
	ctx.fill_rect(-hw, -L, float(f.get("w", 58)), L)
	ctx.fill_style("rgba(236,220,255,0.95)")
	ctx.fill_rect(-4, -L, 8, L)
	ctx.restore()

func _fx_mech(f: Dictionary, player: Node) -> void:
	var ft = float(f.get("t", 240))
	var fade = ft / 40.0 if ft < 40.0 else ((240.0 - ft) / 30.0 if ft > 210.0 else 1.0)
	fade = clampf(fade, 0.0, 1.0)
	var face = float(f.get("face", -PI / 2.0))
	if _mech and _mech.has_method("drawMech"):
		_mech.drawMech(float(f.get("x", 0)), float(f.get("y", 0)), fade, face + PI / 2.0)
	if player and is_instance_valid(player):
		var _sc = _body_ctr(player)
		ctx.save()
		ctx.global_composite_operation("lighter")
		ctx.translate(_sc.x, _sc.y)
		ctx.global_alpha(0.6 * fade)
		ctx.stroke_style("#8fb8ff")
		ctx.line_width(2.4)
		ctx.shadow_color("#8fb8ff")
		ctx.shadow_blur(12)
		ctx.begin_path()
		ctx.arc(0, 0, 27, 0, TAU)
		ctx.stroke()
		ctx.stroke_style("rgba(220,235,255,0.7)")
		ctx.line_width(1)
		for i in range(5):
			var a = float(tick) * 0.06 + float(i) * 1.257
			ctx.begin_path()
			ctx.arc(0, 0, 27, a, a + 0.4)
			ctx.stroke()
		ctx.restore()
		ctx.global_alpha(1.0)

func _fx_bearzooka(f: Dictionary) -> void:
	var ft = float(f.get("t", 156))
	var fade = minf(1.0, ft / 20.0) * minf(1.0, (156.0 - ft) / 12.0)
	if _mech and _mech.has_method("drawMech"):
		_mech.drawMech(float(f.get("x", 0)), float(f.get("y", 0)), fade, PI * 0.5)

func _fx_bombdrop(f: Dictionary) -> void:
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.fill_style("rgba(255,170,60,0.75)")
	ctx.begin_path()
	ctx.move_to(-3.5, 7)
	ctx.line_to(0, 16 + sin(float(tick) * 0.5) * 3.0)
	ctx.line_to(3.5, 7)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("#33333c")
	ctx.begin_path()
	ctx.ellipse(0, 0, 5, 8.5, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#8a8a95")
	ctx.begin_path()
	ctx.ellipse(-1.6, -2, 1.6, 3, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#ffb04a")
	ctx.begin_path()
	ctx.move_to(-4.5, -6.5)
	ctx.line_to(0, -13)
	ctx.line_to(4.5, -6.5)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("#fff" if (tick % 4 < 2) else "#ff6a2a")
	ctx.begin_path()
	ctx.arc(0, -13, 1.4, 0, TAU)
	ctx.fill()
	ctx.restore()

func _fx_blackhole(f: Dictionary) -> void:
	var R = 15.0 + float(f.get("r", 0))
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	var gbh = ctx.create_radial_gradient(0, 0, 4, 0, 0, 64)
	gbh.addColorStop(0, "rgba(60,230,120,0.42)")
	gbh.addColorStop(0.4, "rgba(30,160,70,0.2)")
	gbh.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fill_style(gbh)
	ctx.begin_path()
	ctx.arc(0, 0, 64, 0, TAU)
	ctx.fill()
	for k in range(5):
		var rr = 8.0 + float(k) * 7.0
		var a0 = float(tick) * 0.16 * (1.0 if k % 2 else -1.0) + float(k) * 1.3
		ctx.stroke_style("rgba(90,235,140,%s)" % str(0.55 - float(k) * 0.08))
		ctx.line_width(2.6 - float(k) * 0.35)
		ctx.begin_path()
		ctx.arc(0, 0, rr, a0, a0 + 3.6)
		ctx.stroke()
	ctx.restore()
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.fill_style("#04160b")
	ctx.begin_path()
	ctx.arc(0, 0, float(f.get("r", 8)), 0, TAU)
	ctx.fill()
	ctx.stroke_style("#3ae66a")
	ctx.line_width(1.6)
	ctx.stroke()
	ctx.restore()

func _fx_wave(f: Dictionary, pf: Rect2) -> void:
	if float(f.get("delay", 0)) > 0.0:
		return
	ctx.save()
	ctx.global_alpha(maxf(0.0, 1.0 - float(f.get("r", 0)) / maxf(1.0, pf.size.x)))
	ctx.stroke_style("#ffd27a")
	ctx.line_width(5)
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(14)
	ctx.begin_path()
	ctx.arc(float(f.get("x", 0)), float(f.get("y", 0)), float(f.get("r", 0)), 0, TAU)
	ctx.stroke()
	ctx.stroke_style("#fff")
	ctx.line_width(2)
	ctx.begin_path()
	ctx.arc(float(f.get("x", 0)), float(f.get("y", 0)), float(f.get("r", 0)), 0, TAU)
	ctx.stroke()
	ctx.restore()

func _fx_bull(f: Dictionary) -> void:
	var ft = float(f.get("t", 0))
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.global_alpha(minf(1.0, ft / 12.0))
	ctx.fill_style("rgba(191,230,160,0.5)")
	for i in range(3):
		ctx.begin_path()
		ctx.arc(-7 + float(i) * 7, 14 + fmod(ft * 3.0 + float(i) * 9.0, 10.0), 2.4, 0, TAU)
		ctx.fill()
	ctx.save()
	ctx.shadow_color("#7ed957")
	ctx.shadow_blur(14)
	ctx.fill_style("#7ed957")
	ctx.begin_path()
	ctx.ellipse(0, 0, 15, 11, 0, 0, TAU)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(0, -11, 8.5, 7.5, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#d6ffa8")
	ctx.begin_path()
	ctx.move_to(-6, -16)
	ctx.line_to(-11, -23)
	ctx.line_to(-2, -17)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(6, -16)
	ctx.line_to(11, -23)
	ctx.line_to(2, -17)
	ctx.close_path()
	ctx.fill()
	_circle(-3, -11, 1.6, "#c0202a")
	_circle(3, -11, 1.6, "#c0202a")
	ctx.restore()
	ctx.restore()

func _fx_badger(f: Dictionary) -> void:
	var ft = float(f.get("t", 0))
	var dir = float(f.get("dir", 1))
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.scale(dir, 1)
	ctx.global_alpha(minf(1.0, ft / 12.0))
	ctx.fill_style("rgba(240,176,48,0.5)")
	for i in range(4):
		ctx.begin_path()
		ctx.arc(-18 - float(i) * 6, 6 + fmod(ft * 3.0 + float(i) * 7.0, 8.0), 2.6, 0, TAU)
		ctx.fill()
	ctx.save()
	ctx.shadow_color("#f0b030")
	ctx.shadow_blur(12)
	ctx.fill_style("#20201c")
	ctx.begin_path()
	ctx.ellipse(-7, 10, 3, 4, 0, 0, TAU)
	ctx.ellipse(7, 10, 3, 4, 0, 0, TAU)
	ctx.fill()
	var lp = sin(ft * 0.7) * 1.6
	ctx.fill_style("#c9b48a")
	ctx.begin_path()
	ctx.ellipse(-7 + lp, 13, 2.2, 1.5, 0, 0, TAU)
	ctx.ellipse(7 - lp, 13, 2.2, 1.5, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#221f18")
	ctx.begin_path()
	ctx.ellipse(0, 4, 21, 9, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#dcd6c6")
	ctx.begin_path()
	ctx.ellipse(-2, -2, 20, 8, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#1c1a16")
	ctx.begin_path()
	ctx.ellipse(17, 1, 9.5, 8, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#f4efe6")
	ctx.begin_path()
	ctx.move_to(9, -6)
	ctx.line_to(25, -6)
	ctx.line_to(25, -2.5)
	ctx.line_to(9, -2.5)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("#1c1a16")
	ctx.begin_path()
	ctx.arc(12, -7, 2.6, 0, TAU)
	ctx.fill()
	_circle(19, -0.5, 1.5, "#fff")
	_circle(19.6, -0.5, 0.8, "#100c08")
	ctx.fill_style("#efe8db")
	ctx.begin_path()
	ctx.ellipse(25, 2, 3.4, 3, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#100c08")
	ctx.begin_path()
	ctx.ellipse(27.4, 2, 1.6, 1.3, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#7a1c22")
	ctx.begin_path()
	ctx.ellipse(24.5, 5, 2.2, 1.4, 0, 0, TAU)
	ctx.fill()
	ctx.fill_style("#fff")
	ctx.begin_path()
	ctx.move_to(23.4, 4)
	ctx.line_to(24.4, 6.4)
	ctx.line_to(25.4, 4)
	ctx.close_path()
	ctx.fill()
	ctx.stroke_style("#eae2d0")
	ctx.line_width(1.5)
	ctx.line_cap("round")
	for i in range(3):
		ctx.begin_path()
		ctx.move_to(14, 9 + float(i) * 2.2)
		ctx.line_to(21, 8 + float(i) * 2.2)
		ctx.stroke()
	ctx.restore()
	ctx.restore()

func _fx_kiss(f: Dictionary, pf: Rect2) -> void:
	var fr = float(f.get("r", 0))
	ctx.save()
	ctx.global_alpha(maxf(0.0, 1.0 - fr / (pf.size.x * 0.95)))
	ctx.stroke_style("#ff5b8d")
	ctx.line_width(5)
	ctx.shadow_color("#ff8ac0")
	ctx.shadow_blur(16)
	ctx.begin_path()
	ctx.arc(float(f.get("x", 0)), float(f.get("y", 0)), fr, 0, TAU)
	ctx.stroke()
	ctx.shadow_blur(0)
	ctx.text_align("center")
	for i in range(12):
		var a = float(i) / 12.0 * TAU + float(tick) * 0.02
		var hx = float(f.get("x", 0)) + cos(a) * fr
		var hy = float(f.get("y", 0)) + sin(a) * fr
		ctx.font("13px serif")
		ctx.fill_style("#ff5b8d")
		ctx.fill_text("💗", hx, hy + 4)
	ctx.text_align("left")
	ctx.restore()

func _fx_bubble(f: Dictionary) -> void:
	ctx.save()
	if float(f.get("pop", 0)) > 0.0:
		var a = maxf(0.0, float(f.get("pop", 0)) / 16.0)
		ctx.global_alpha(a)
		ctx.stroke_style("#bfe8ff")
		ctx.line_width(3)
		ctx.shadow_color("#8fd0ff")
		ctx.shadow_blur(12)
		ctx.begin_path()
		ctx.arc(float(f.get("x", 0)), float(f.get("y", 0)), float(f.get("popR", f.get("r", 10))), 0, TAU)
		ctx.stroke()
	else:
		var r = float(f.get("r", 12))
		var fx = float(f.get("x", 0))
		var fy = float(f.get("y", 0))
		ctx.global_alpha(0.62)
		var gbub = ctx.create_radial_gradient(fx - r * 0.3, fy - r * 0.3, 1, fx, fy, r)
		gbub.addColorStop(0, "rgba(255,255,255,0.5)")
		gbub.addColorStop(0.6, "rgba(160,220,255,0.16)")
		gbub.addColorStop(1, "rgba(120,190,255,0.34)")
		ctx.fill_style(gbub)
		ctx.begin_path()
		ctx.arc(fx, fy, r, 0, TAU)
		ctx.fill()
		ctx.global_alpha(0.9)
		ctx.stroke_style("#cbeaff")
		ctx.line_width(1.4)
		ctx.begin_path()
		ctx.arc(fx, fy, r, 0, TAU)
		ctx.stroke()
		ctx.fill_style("rgba(255,255,255,0.85)")
		ctx.begin_path()
		ctx.arc(fx - r * 0.35, fy - r * 0.4, r * 0.16, 0, TAU)
		ctx.fill()
	ctx.restore()

func _fx_stardust(f: Dictionary) -> void:
	ctx.save()
	ctx.global_composite_operation("lighter")
	var stars = f.get("stars", [])
	if stars is Array:
		for st in stars:
			if typeof(st) != TYPE_DICTIONARY:
				continue
			var stt = float(st.get("t", 0))
			var life = float(st.get("life", 20))
			var fade = minf(1.0, stt / 4.0) * minf(1.0, (life - stt) / 7.0)
			var tw = 0.55 + 0.45 * sin(float(tick) * 0.3 + float(st.get("rot", 0)))
			var hue = int(st.get("hue", 50))
			if bool(st.get("sapping", false)):
				ctx.stroke_style("hsla(%d,100%%,74%%,%s)" % [hue, str(0.45 * fade)])
				ctx.line_width(1)
				ctx.begin_path()
				ctx.move_to(float(st.get("x", 0)), float(st.get("y", 0)))
				ctx.line_to(float(st.get("sapX", 0)), float(st.get("sapY", 0)))
				ctx.stroke()
			var s = float(st.get("sz", 3)) * (0.7 + 0.5 * tw)
			ctx.save()
			ctx.translate(float(st.get("x", 0)), float(st.get("y", 0)))
			ctx.rotate(float(st.get("rot", 0)) + float(tick) * 0.05)
			ctx.fill_style("hsla(%d,100%%,82%%,%s)" % [hue, str(0.9 * fade * tw)])
			ctx.shadow_color("hsl(%d,100%%,70%%)" % hue)
			ctx.shadow_blur(6)
			ctx.begin_path()
			ctx.move_to(0, -s * 2.4)
			ctx.line_to(s * 0.5, -s * 0.5)
			ctx.line_to(s * 2.4, 0)
			ctx.line_to(s * 0.5, s * 0.5)
			ctx.line_to(0, s * 2.4)
			ctx.line_to(-s * 0.5, s * 0.5)
			ctx.line_to(-s * 2.4, 0)
			ctx.line_to(-s * 0.5, -s * 0.5)
			ctx.close_path()
			ctx.fill()
			ctx.restore()
	ctx.restore()

func _fx_tentacle(f: Dictionary) -> void:
	var ft = float(f.get("t", 0))
	var fade = minf(1.0, ft / 24.0) * minf(1.0, (360.0 - ft) / 16.0)
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.global_alpha(fade)
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.global_alpha(fade * 0.35)
	ctx.fill_style("#5fc9c9")
	ctx.begin_path()
	ctx.arc(0, 0, float(f.get("reach", 76)) * 0.5, 0, TAU)
	ctx.fill()
	ctx.restore()
	var segs = 11
	var pts: Array = []
	var ph = float(f.get("ph", 0))
	for s in range(segs + 1):
		pts.append([sin(ph + float(s) * 0.5) * float(s) * 1.5, -float(s) * 7.5])
	ctx.line_cap("round")
	ctx.line_join("round")
	ctx.stroke_style("#2f6d6d")
	ctx.line_width(10)
	ctx.begin_path()
	ctx.move_to(pts[0][0], pts[0][1])
	for q in pts:
		ctx.line_to(q[0], q[1])
	ctx.stroke()
	ctx.stroke_style("#5fc9c9")
	ctx.line_width(5.5)
	ctx.begin_path()
	ctx.move_to(pts[0][0], pts[0][1])
	for q2 in pts:
		ctx.line_to(q2[0], q2[1])
	ctx.stroke()
	ctx.fill_style("#bff0f0")
	var s2 = 2
	while s2 <= segs:
		ctx.begin_path()
		ctx.arc(pts[s2][0], pts[s2][1], 1.7, 0, TAU)
		ctx.fill()
		s2 += 2
	ctx.restore()

func _fx_servitor(f: Dictionary) -> void:
	var ft = float(f.get("t", 0))
	var sz = float(f.get("sz", 1))
	var fade = minf(1.0, (600.0 - ft) / 16.0) * minf(1.0, ft / 20.0)
	ctx.save()
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.save()
	ctx.scale(sz, sz)
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.global_alpha(fade * 0.55)
	ctx.fill_style("rgba(157,107,255,0.45)")
	ctx.begin_path()
	ctx.arc(0, 0, 18, 0, TAU)
	ctx.fill()
	ctx.restore()
	ctx.global_alpha(fade)
	ctx.stroke_style("#3a1a5a")
	ctx.line_width(2.2)
	ctx.line_cap("round")
	for k in range(8):
		var a = float(tick) * 0.05 + float(k) * 0.785
		var ln = 9.0 + sin(float(tick) * 0.11 + float(k)) * 3.8
		ctx.begin_path()
		ctx.move_to(0, 0)
		ctx.line_to(cos(a) * ln, sin(a) * ln)
		ctx.stroke()
	ctx.fill_style("#2a1040")
	ctx.begin_path()
	ctx.arc(0, 0, 7.5, 0, TAU)
	ctx.fill()
	ctx.fill_style("#e0d0ff")
	ctx.begin_path()
	ctx.arc(0, 0, 4.4, 0, TAU)
	ctx.fill()
	ctx.fill_style("#9d1bff")
	ctx.begin_path()
	ctx.arc(cos(float(tick) * 0.1) * 1.7, sin(float(tick) * 0.1) * 1.7, 2.3, 0, TAU)
	ctx.fill()
	ctx.restore()
	# HP bar
	ctx.global_alpha(fade)
	var bw = 32.0
	var bh = 5.0
	var bx = -bw / 2.0
	var by = -12.0 * sz - 10.0
	var maxhp = float(f.get("maxhp", f.get("hp", 1)))
	var hf = clampf(float(f.get("hp", maxhp)) / maxf(1.0, maxhp), 0.0, 1.0)
	ctx.fill_style("rgba(0,0,0,0.55)")
	ctx.fill_rect(bx - 1, by - 1, bw + 2, bh + 2)
	ctx.fill_style("#241038")
	ctx.fill_rect(bx, by, bw, bh)
	ctx.fill_style("#b57aff" if hf > 0.5 else ("#ffb04a" if hf > 0.25 else "#ff5b6e"))
	ctx.fill_rect(bx, by, bw * hf, bh)
	ctx.restore()
