extends RefCounted
## 1:1 HTML drawMech — special mech summon sprite.

var ctx
var tick: int = 0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func drawMech(x, y, alpha = 1.0, rot = 0.0) -> void:
	ctx.save()
	ctx.translate(float(x), float(y))
	if rot:
		ctx.rotate(float(rot))
	ctx.global_alpha(clampf(float(alpha if alpha != null else 1.0), 0.0, 1.0))
	var t := float(tick)
	var blue := "#33507a"
	var blueD := "#22384f"
	var blueL := "#5a7ba6"
	var red := "#d8283a"
	var redD := "#9c1420"
	var steel := "#c8d2e0"
	ctx.line_join("round")
	# aura
	ctx.save()
	ctx.global_alpha(ctx.get_alpha() * 0.5)
	ctx.shadow_color("#ffb04a")
	ctx.shadow_blur(26)
	ctx.fill_style("rgba(255,160,60,0.5)")
	ctx.begin_path()
	ctx.ellipse(0, 4, 30, 26, 0, 0, TAU)
	ctx.fill()
	ctx.restore()
	# thruster flames
	ctx.fill_style("rgba(255,180,60,0.85)")
	for fx2 in [-8.0, 8.0]:
		ctx.begin_path()
		ctx.move_to(fx2 - 4, 18)
		ctx.line_to(fx2, 26 + sin(t * 0.6) * 4)
		ctx.line_to(fx2 + 4, 18)
		ctx.fill()
	# red jagged wings
	ctx.fill_style(red)
	ctx.stroke_style(redD)
	ctx.line_width(1.5)
	for s in [-1.0, 1.0]:
		ctx.save()
		ctx.scale(s, 1)
		ctx.begin_path()
		ctx.move_to(10, -6)
		ctx.line_to(34, -16)
		ctx.line_to(26, -8)
		ctx.line_to(40, -4)
		ctx.line_to(30, -1)
		ctx.line_to(42, 6)
		ctx.line_to(28, 6)
		ctx.line_to(34, 12)
		ctx.line_to(16, 6)
		ctx.close_path()
		ctx.fill()
		ctx.stroke()
		ctx.restore()
	# torso
	ctx.fill_style(blue)
	ctx.begin_path()
	ctx.round_rect(-13, -6, 26, 22, 5)
	ctx.fill()
	ctx.fill_style(blueL)
	ctx.begin_path()
	ctx.round_rect(-13, -6, 26, 6, 4)
	ctx.fill()
	ctx.fill_style(blueD)
	ctx.begin_path()
	ctx.round_rect(-18, -4, 7, 12, 3)
	ctx.round_rect(11, -4, 7, 12, 3)
	ctx.fill()
	# panda face
	ctx.fill_style("#f2efe6")
	ctx.begin_path()
	ctx.arc(0, 5, 8, 0, TAU)
	ctx.fill()
	ctx.fill_style("#1a1620")
	ctx.begin_path()
	ctx.ellipse(-3.5, 3, 2.4, 3, 0.3, 0, TAU)
	ctx.ellipse(3.5, 3, 2.4, 3, -0.3, 0, TAU)
	ctx.fill()
	ctx.fill_style("#ff3b5c")
	ctx.begin_path()
	ctx.arc(-3.5, 3.5, 1, 0, TAU)
	ctx.arc(3.5, 3.5, 1, 0, TAU)
	ctx.fill()
	ctx.fill_style("#1a1620")
	ctx.begin_path()
	ctx.arc(0, 7, 1.4, 0, TAU)
	ctx.fill()
	# legs
	ctx.fill_style(blueD)
	ctx.begin_path()
	ctx.round_rect(-10, 15, 7, 7, 2)
	ctx.round_rect(3, 15, 7, 7, 2)
	ctx.fill()
	# missile-pod head
	ctx.fill_style(blueD)
	ctx.begin_path()
	ctx.round_rect(-11, -20, 22, 15, 3)
	ctx.fill()
	ctx.fill_style(steel)
	var cx := -8.0
	while cx <= 8.0:
		var cy := -18.0
		while cy <= -9.0:
			ctx.begin_path()
			ctx.arc(cx, cy, 1.6, 0, TAU)
			ctx.fill()
			cy += 4
		cx += 5
	ctx.fill_style(blueD)
	ctx.begin_path()
	ctx.arc(-9, -21, 3, 0, TAU)
	ctx.arc(9, -21, 3, 0, TAU)
	ctx.fill()
	ctx.restore()
