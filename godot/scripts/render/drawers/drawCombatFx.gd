extends RefCounted
## 1:1 HTML drawPowerAura / drawDashComet / drawOptions / drawPowerRadiance / melee weapon / pose props.

var ctx
var tick: int = 0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func _hex_a(h, a) -> String:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return "rgba(%d,%d,%d,%s)" % [(n >> 16) & 255, (n >> 8) & 255, n & 255, str(a)]

func draw_options(player_local: bool = true) -> void:
	## HTML drawOptions — option orbs around player (local 0,0 if on BobinaSprite)
	var lv := CombatHelpers.shot_level()
	var offsets: Array = []
	if lv <= 1:
		return
	elif lv == 2:
		offsets = [{"x": -28.0, "y": 8.0}, {"x": 28.0, "y": 8.0}]
	elif lv == 3:
		offsets = [{"x": -32.0, "y": 6.0}, {"x": 32.0, "y": 6.0}, {"x": 0.0, "y": 22.0}]
	else:
		offsets = [{"x": -36.0, "y": 4.0}, {"x": 36.0, "y": 4.0}, {"x": -18.0, "y": 20.0}, {"x": 18.0, "y": 20.0}]
	for o in offsets:
		ctx.save()
		ctx.translate(float(o.x), float(o.y))
		ctx.shadow_color("#ff8ad6")
		ctx.shadow_blur(8)
		ctx.fill_style("#ffd6f2")
		ctx.begin_path()
		ctx.arc(0, 0, 4.5, 0, TAU)
		ctx.fill()
		ctx.fill_style("#cf2f38")
		ctx.begin_path()
		ctx.arc(0, 0, 2, 0, TAU)
		ctx.fill()
		ctx.restore()

func draw_power_aura(p: Dictionary) -> void:
	## HTML drawPowerAura — psychedelic power bubble (local coords: p.x/p.y often 0)
	var power := float(p.get("power", GameState.power))
	var pf := clampf((power - 1.0) / 5.0, 0.0, 1.0)
	if pf < 0.02:
		return
	var t := float(p.get("tick", tick))
	var oc: Array = CombatHelpers.outfit_colors(str(p.get("outfit", GameState.selected_outfit)))
	var face := float(p.get("face", -PI / 2.0))
	var rot := face + PI / 2.0
	var R := (30.0 + pf * 15.0) * (1.0 + sin(t * 0.09) * 0.05 * (0.4 + pf))
	var hue0 := fmod(t * 2.4, 360.0)
	# bodyCtr relative to local origin
	var ctr := CombatHelpers.body_ctr({"x": float(p.get("x", 0)), "y": float(p.get("y", 0)), "face": face})
	ctx.save()
	ctx.translate(ctr.x, ctr.y)
	ctx.global_composite_operation("lighter")
	# outer glow (approx radial)
	ctx.fill_style(_hex_a(oc[0], 0.12 + pf * 0.16))
	ctx.begin_path()
	ctx.arc(0, 0, R * 1.6, 0, TAU)
	ctx.fill()
	ctx.save()
	ctx.rotate(rot)
	var bands := 6 + int(floor(pf * 4.0))
	for i in range(bands, 0, -1):
		var rr := R * (float(i) / float(bands) + 0.03)
		var hue := fmod(hue0 + float(i) * (38.0 + pf * 26.0) + sin(t * 0.09 + float(i)) * 18.0, 360.0)
		ctx.stroke_style("hsla(%d,100%%,60%%,%s)" % [int(hue), str(0.07 + pf * 0.12)])
		ctx.line_width((R / float(bands)) * 1.6)
		ctx.begin_path()
		ctx.arc(0, 0, rr, 0, TAU)
		ctx.stroke()
	# swirling ribbons
	var swirls := 2 + int(floor(pf * 3.0))
	ctx.line_cap("round")
	for k in range(swirls):
		var hue2 := fmod(hue0 + float(k) * 70.0, 360.0)
		ctx.stroke_style("hsla(%d,100%%,65%%,%s)" % [int(hue2), str(0.18 + pf * 0.22)])
		ctx.line_width(1.6 + pf * 1.4)
		ctx.begin_path()
		for a_i in range(33):
			var a := float(a_i) / 32.0 * TAU
			var wob := 1.0 + sin(a * 3.0 + t * 0.12 + float(k)) * 0.08 * pf
			var rr2 := R * (0.72 + 0.12 * sin(a * 2.0 + t * 0.08 + float(k) * 1.3)) * wob
			var px := cos(a + t * 0.04 * (1.0 + float(k) * 0.2)) * rr2
			var py := sin(a + t * 0.04 * (1.0 + float(k) * 0.2)) * rr2
			if a_i == 0:
				ctx.move_to(px, py)
			else:
				ctx.line_to(px, py)
		ctx.stroke()
	ctx.restore()
	# inner highlight ring
	ctx.stroke_style(_hex_a("#fff", 0.15 + pf * 0.2))
	ctx.line_width(1.2)
	ctx.begin_path()
	ctx.arc(0, 0, R * 0.55, 0, TAU)
	ctx.stroke()
	ctx.restore()

func draw_power_radiance(p: Dictionary) -> void:
	## HTML drawPowerRadiance
	if float(p.get("power", GameState.power)) < 0.0:
		pass
	var pf := clampf((float(p.get("power", GameState.power)) - 1.0) / 5.0, 0.0, 1.0)
	if pf < 0.12:
		return
	var t := float(p.get("tick", tick))
	var face := float(p.get("face", -PI / 2.0))
	var ctr := CombatHelpers.body_ctr({"x": float(p.get("x", 0)), "y": float(p.get("y", 0)), "face": face})
	var hue0 := fmod(t * 2.4, 360.0)
	ctx.save()
	ctx.global_composite_operation("lighter")
	var HR := 55.0 + pf * 95.0
	ctx.fill_style("hsla(%d,90%%,60%%,%s)" % [int(hue0), str(0.035 + pf * 0.06)])
	ctx.begin_path()
	ctx.arc(ctr.x, ctr.y, HR, 0, TAU)
	ctx.fill()
	var rings := 2 + int(floor(pf * 3.0))
	for k in range(rings):
		var ph := fmod(t * 0.009 + float(k) / float(rings), 1.0)
		var rr := 22.0 + ph * (66.0 + pf * 120.0)
		var al := (1.0 - ph) * (0.05 + pf * 0.09)
		var hue := fmod(hue0 + float(k) * 55.0, 360.0)
		ctx.stroke_style("hsla(%d,95%%,66%%,%s)" % [int(hue), str(al)])
		ctx.line_width(1.4 * (1.0 - ph) + 0.4)
		ctx.begin_path()
		var first := true
		var a := 0.0
		while a <= 6.3:
			var wob := 1.0 + sin(a * 5.0 + t * 0.14 + float(k)) * 0.06 * pf
			var x := ctr.x + cos(a) * rr * wob
			var y := ctr.y + sin(a) * rr * wob
			if first:
				ctx.move_to(x, y)
				first = false
			else:
				ctx.line_to(x, y)
			a += 0.32
		ctx.close_path()
		ctx.stroke()
	ctx.restore()

func draw_dash_comet(p: Dictionary) -> void:
	## HTML drawDashComet — trail + head (local or absolute points in p.trail)
	var trail: Array = p.get("trail", [])
	var dashing := bool(p.get("dash", false)) or float(p.get("dash", 0)) > 0.0
	if not dashing and trail.is_empty():
		return
	var slash := bool(p.get("slashDash", false))
	var t := float(p.get("tick", tick))
	var hue0 := fmod(t * 4.0, 360.0)
	var px := float(p.get("x", 0))
	var py := float(p.get("y", 0))
	ctx.save()
	ctx.global_composite_operation("lighter")
	if trail.size() > 1:
		var n := trail.size()
		for i in range(n - 1, -1, -1):
			var q: Dictionary = trail[i]
			var f := 1.0 - float(i) / float(n)
			var r := 4.0 + f * (26.0 if slash else 20.0)
			var hue := fmod(hue0 + float(i) * 22.0, 360.0)
			ctx.global_alpha(0.14 + f * 0.55)
			ctx.fill_style("hsla(%d,100%%,74%%,1)" % int(hue))
			ctx.begin_path()
			ctx.arc(float(q.get("x", 0)), float(q.get("y", 0)), r, 0, TAU)
			ctx.fill()
		ctx.global_alpha(0.85 if slash else 0.55)
		ctx.stroke_style("rgba(255,255,255,0.9)")
		ctx.line_width(2.6 if slash else 1.5)
		ctx.line_cap("round")
		ctx.begin_path()
		for i in range(n):
			var q2: Dictionary = trail[i]
			if i == 0:
				ctx.move_to(float(q2.get("x", 0)), float(q2.get("y", 0)))
			else:
				ctx.line_to(float(q2.get("x", 0)), float(q2.get("y", 0)))
		ctx.stroke()
		ctx.global_alpha(1.0)
	var aura := 1.0 if dashing else minf(1.0, float(trail.size()) / 16.0)
	if aura > 0.02:
		var ar := (26.0 if slash else 19.0) + 4.0 * sin(t * 0.5)
		ctx.fill_style("hsla(%d,100%%,74%%,%s)" % [int(hue0), str((0.55 if slash else 0.35) * aura)])
		ctx.begin_path()
		ctx.arc(px, py, ar, 0, TAU)
		ctx.fill()
		# rainbow rim
		for i in range(8):
			var a0 := float(i) / 8.0 * TAU + t * 0.2
			var hue := fmod(hue0 + float(i) * 45.0, 360.0)
			ctx.stroke_style("hsla(%d,100%%,70%%,%s)" % [int(hue), str(0.4 * aura)])
			ctx.line_width(2.0)
			ctx.begin_path()
			ctx.arc(px, py, ar + 2.0, a0, a0 + 0.5)
			ctx.stroke()
	ctx.restore()

func coffee_hold(t: float) -> Dictionary:
	var sip := (1.0 - cos(t * 0.025)) / 2.0
	return {"x": 0.0, "y": 3.0 - sip * 7.0, "sip": sip}

func pose_params(pose: int, t: float) -> Dictionary:
	## HTML poseParams
	var vx := 0.0
	var vy := 0.0
	var lean := 0.0
	var expr := "smile"
	var rot := 0.0
	var bounce := 0.0
	var sway := 0.0
	var sq := 1.0
	if pose == 1:
		bounce = absf(sin(t * 0.15)) * 15.0
		sway = sin(t * 0.11) * 18.0
		rot = sin(t * 0.11) * 0.13
		vx = sin(t * 0.3) * 3.6
		vy = cos(t * 0.42) * 1.6
		lean = sin(t * 0.11) * 0.5
		expr = "uwu"
	elif pose == 2:
		rot = t * 0.05
		bounce = absf(sin(t * 0.15)) * 3.5
		expr = "annoyed"
	elif pose == 3:
		bounce = absf(sin(t * 0.2)) * 26.0
		sq = 1.0 + sin(t * 0.2) * 0.1
		expr = "smile"
	elif pose == 4:
		var s := sin(t * 0.12)
		sway = s * 13.0
		lean = s * 0.5
		rot = s * 0.06
		bounce = absf(sin(t * 0.24)) * 4.5
		expr = "squee"
	elif pose == 5:
		bounce = (1.0 - cos(t * 0.05)) * 1.4
		lean = 0.04
		expr = "giggle"
	else:
		bounce = (1.0 - cos(t * 0.045)) * 1.6
		sway = sin(t * 0.035) * 2.0
		expr = "smile"
	return {"vx": vx, "vy": vy, "lean": lean, "expr": expr, "rot": rot, "bounce": bounce, "sway": sway, "sq": sq}

func draw_pose_prop(pose: int, t: float) -> void:
	## HTML drawPoseProp — This Is Fine fire + coffee
	if pose != 5:
		return
	var h := coffee_hold(t)
	# ring of fire
	for i in range(12):
		var fa := float(i) / 12.0 * TAU
		var ring := 12.0 if i % 2 else 9.5
		var fx := cos(fa) * ring
		var fby := 17.0 + sin(fa) * 4.5
		var fl := (4.5 + float(i % 3) * 2.4) * (0.55 + 0.45 * absf(sin(t * 0.3 + float(i) * 1.7)))
		_flame(fx, fby, fl, i, t)
	for sx in [-13.5, 13.5]:
		_flame(sx, 14.0, 13.0 + absf(sin(t * 0.25 + sx)) * 6.0, int(sx), t)
	# coffee mug
	ctx.save()
	ctx.translate(float(h.x), float(h.y) - 0.6)
	ctx.fill_style("#f4efe6")
	ctx.begin_path()
	ctx.move_to(-2.4, -2.2)
	ctx.line_to(2.4, -2.2)
	ctx.line_to(1.9, 2.3)
	ctx.line_to(-1.9, 2.3)
	ctx.close_path()
	ctx.fill()
	ctx.stroke_style("#b89a68")
	ctx.line_width(0.6)
	ctx.stroke()
	ctx.fill_style("#4a2c14")
	ctx.begin_path()
	ctx.ellipse(0, -2.2, 2.3, 0.7, 0, 0, TAU)
	ctx.fill()
	ctx.stroke_style("#f4efe6")
	ctx.line_width(0.9)
	ctx.begin_path()
	ctx.arc(2.7, 0.2, 1.3, -1.0, 1.7)
	ctx.stroke()
	# steam
	ctx.stroke_style("rgba(255,255,255,0.45)")
	ctx.line_width(0.7)
	for i in range(3):
		var sx2 := -1.2 + float(i) * 1.2
		ctx.begin_path()
		ctx.move_to(sx2, -3.0)
		ctx.quadratic_curve_to(sx2 + sin(t * 0.1 + float(i)) * 1.2, -5.5 - float(h.sip) * 2.0, sx2, -7.0 - float(h.sip) * 3.0)
		ctx.stroke()
	ctx.restore()

func _flame(fx: float, fby: float, fl: float, i: int, t: float) -> void:
	ctx.fill_style("#ff2e00")
	ctx.begin_path()
	ctx.move_to(fx - fl * 0.18 - 0.6, fby)
	ctx.quadratic_curve_to(fx - 0.8, fby - fl * 0.6, fx + sin(t * 0.22 + float(i)) * 1.3, fby - fl)
	ctx.quadratic_curve_to(fx + 0.8, fby - fl * 0.6, fx + fl * 0.18 + 0.6, fby)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("#ff8a12")
	ctx.begin_path()
	ctx.move_to(fx - fl * 0.1, fby)
	ctx.quadratic_curve_to(fx, fby - fl * 0.5, fx + sin(t * 0.3 + float(i)) * 0.6, fby - fl * 0.7)
	ctx.quadratic_curve_to(fx, fby - fl * 0.4, fx + fl * 0.1, fby)
	ctx.close_path()
	ctx.fill()

func draw_melee_weapon(key: String, length: float, col: String, charge: float) -> void:
	## HTML drawMeleeWeapon — drawn in local space along +X
	ctx.line_cap("round")
	ctx.line_join("round")
	if key == "katana":
		ctx.fill_style("#241820")
		ctx.begin_path()
		ctx.round_rect(-17, -3.1, 27, 6.2, 2.6)
		ctx.fill()
		ctx.stroke_style("#0d0910")
		ctx.line_width(1)
		var wx := -14.0
		while wx < 7.0:
			ctx.begin_path()
			ctx.move_to(wx, -3)
			ctx.line_to(wx + 2.6, 3)
			ctx.move_to(wx + 2.6, -3)
			ctx.line_to(wx, 3)
			ctx.stroke()
			wx += 4
		ctx.fill_style("#3a2a30")
		ctx.begin_path()
		ctx.round_rect(-20, -3.7, 4, 7.4, 1.5)
		ctx.fill()
		ctx.fill_style("#e0b040")
		ctx.begin_path()
		ctx.ellipse(10, 0, 2.7, 6.6, 0, 0, TAU)
		ctx.fill()
		ctx.stroke_style("#8a6a1e")
		ctx.line_width(0.9)
		ctx.stroke()
		var b0 := 13.0
		var bl := length - b0
		ctx.save()
		ctx.shadow_color(col)
		ctx.shadow_blur(12 + charge * 8)
		ctx.fill_style(col)
		ctx.begin_path()
		ctx.move_to(b0, -3.1)
		ctx.quadratic_curve_to(b0 + bl * 0.55, -4.8, b0 + bl, -1.5)
		ctx.quadratic_curve_to(b0 + bl + 5, 0, b0 + bl, 1.5)
		ctx.quadratic_curve_to(b0 + bl * 0.55, 3.1, b0, 3.1)
		ctx.close_path()
		ctx.fill()
		ctx.restore()
		ctx.stroke_style("rgba(150,18,38,0.85)")
		ctx.line_width(0.9)
		ctx.stroke()
		ctx.stroke_style("#fff")
		ctx.line_width(1.5)
		ctx.begin_path()
		ctx.move_to(b0 + 2, -1.4)
		ctx.quadratic_curve_to(b0 + bl * 0.55, -2.6, b0 + bl - 2, -0.2)
		ctx.stroke()
	elif key == "lash":
		# whip cord
		ctx.stroke_style(col)
		ctx.line_width(2.2 + charge)
		ctx.shadow_color(col)
		ctx.shadow_blur(8)
		ctx.begin_path()
		ctx.move_to(0, 0)
		ctx.quadratic_curve_to(length * 0.4, -6 - charge * 4, length * 0.75, 2)
		ctx.quadratic_curve_to(length * 0.9, 4, length, 0)
		ctx.stroke()
		ctx.shadow_blur(0)
		ctx.fill_style("#3a2a20")
		ctx.begin_path()
		ctx.round_rect(-8, -3, 12, 6, 2)
		ctx.fill()
	elif key == "scythe":
		ctx.stroke_style("#5a4636")
		ctx.line_width(3.2)
		ctx.begin_path()
		ctx.move_to(-length * 0.2, 0)
		ctx.line_to(length * 0.9, 0)
		ctx.stroke()
		ctx.fill_style("#5a4636")
		ctx.begin_path()
		ctx.arc(-length * 0.2, 0, 2, 0, TAU)
		ctx.arc(length * 0.42, 0, 1.8, 0, TAU)
		ctx.fill()
		ctx.save()
		ctx.shadow_color(col)
		ctx.shadow_blur(12)
		ctx.fill_style(col)
		ctx.begin_path()
		ctx.move_to(length * 0.86, 3)
		ctx.quadratic_curve_to(length * 1.02, -4, length * 0.78, -length * 0.34)
		ctx.quadratic_curve_to(length * 0.7, -length * 0.16, length * 0.86, -1)
		ctx.close_path()
		ctx.fill()
		ctx.restore()
		ctx.stroke_style("#1f7a3a")
		ctx.line_width(1)
		ctx.stroke()
		ctx.stroke_style("#fff")
		ctx.line_width(1.1)
		ctx.begin_path()
		ctx.move_to(length * 0.88, 1)
		ctx.quadratic_curve_to(length * 1.0, -4, length * 0.79, -length * 0.31)
		ctx.stroke()
	elif key == "hammer":
		var hlen := length * 0.64
		ctx.fill_style("#7a5326")
		ctx.begin_path()
		ctx.round_rect(-17, -3, hlen + 17, 6, 2.6)
		ctx.fill()
		ctx.stroke_style("#4a3214")
		ctx.line_width(0.9)
		ctx.stroke()
		ctx.fill_style("#5a3a1a")
		ctx.begin_path()
		ctx.round_rect(-17, -3, 14, 6, 2.6)
		ctx.fill()
		ctx.save()
		ctx.translate(hlen + 8, 0)
		ctx.shadow_color(col)
		ctx.shadow_blur(11)
		ctx.fill_style(col)
		ctx.begin_path()
		ctx.round_rect(-5, -15, 22, 30, 4)
		ctx.fill()
		ctx.shadow_blur(0)
		ctx.fill_style("rgba(255,248,210,0.5)")
		ctx.begin_path()
		ctx.round_rect(-5, -15, 22, 7, 4)
		ctx.fill()
		ctx.fill_style("#fff8e0")
		ctx.begin_path()
		ctx.move_to(9, -8)
		ctx.line_to(15, 0)
		ctx.line_to(9, 8)
		ctx.line_to(3, 0)
		ctx.close_path()
		ctx.fill()
		ctx.restore()
	elif key == "claws":
		ctx.fill_style("#2c2620")
		ctx.begin_path()
		ctx.round_rect(-10, -9, 20, 18, 4)
		ctx.fill()
		ctx.fill_style("#3c3228")
		ctx.begin_path()
		ctx.round_rect(3, -8, 9, 16, 3)
		ctx.fill()
		ctx.save()
		ctx.shadow_color(col)
		ctx.shadow_blur(8)
		for c in range(-1, 2):
			var y0 := float(c) * 5.5
			var cl := length - 10.0
			var tipx := 10.0 + cl
			var tipy := y0 + float(c) * 9.0
			ctx.fill_style(col)
			ctx.begin_path()
			ctx.move_to(10, y0 - 2.8)
			ctx.quadratic_curve_to(10 + cl * 0.6, y0 + float(c) * 5.0, tipx, tipy)
			ctx.quadratic_curve_to(10 + cl * 0.45, y0 + float(c) * 4.0, 10, y0 + 2.8)
			ctx.close_path()
			ctx.fill()
		ctx.restore()
	else:
		ctx.fill_style(col)
		ctx.shadow_color(col)
		ctx.shadow_blur(10)
		ctx.begin_path()
		ctx.round_rect(8, -2.5, length - 8, 5, 2)
		ctx.fill()
		ctx.shadow_blur(0)
