extends RefCounted
## 1:1 HTML drawBobo — cute brown bear cub (reunion / win / specials).

var ctx
var tick: int = 0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func drawBobo(cx, cy, sc = 1.0, happy = true) -> void:
	ctx.save()
	ctx.translate(float(cx), float(cy))
	ctx.scale(float(sc), float(sc))
	ctx.line_join("round")
	ctx.line_cap("round")
	var fur := "#6e4a2e"
	var furD := "#4e3320"
	var ear := "#7a5540"
	var muz := "#e8cfa4"
	var nose := "#241812"
	var shirt := "#cf2f38"
	var shirtD := "#9c1f27"
	var ln := "#241611"
	var bob := sin(float(tick) * 0.08) * 1.2
	# body / red shirt
	ctx.fill_style(shirt)
	ctx.begin_path()
	ctx.ellipse(0, 30 + bob, 26, 22, 0, 0, TAU)
	ctx.stroke_style(ln)
	ctx.line_width(2)
	ctx.stroke()
	ctx.fill()
	ctx.fill_style(shirtD)
	ctx.begin_path()
	ctx.ellipse(0, 40 + bob, 24, 10, 0, 0, TAU)
	ctx.fill()
	# arms / feet
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.ellipse(-22, 26 + bob, 7, 9, 0.4, 0, TAU)
	ctx.ellipse(22, 26 + bob, 7, 9, -0.4, 0, TAU)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(-12, 50 + bob, 8, 6, 0, 0, TAU)
	ctx.ellipse(12, 50 + bob, 8, 6, 0, 0, TAU)
	ctx.fill()
	# ears
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.arc(-22, -30 + bob, 13, 0, TAU)
	ctx.arc(22, -30 + bob, 13, 0, TAU)
	ctx.fill()
	ctx.fill_style(ear)
	ctx.begin_path()
	ctx.arc(-22, -30 + bob, 6.5, 0, TAU)
	ctx.arc(22, -30 + bob, 6.5, 0, TAU)
	ctx.fill()
	# head
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.arc(0, -12 + bob, 30, 0, TAU)
	ctx.stroke_style(ln)
	ctx.line_width(2)
	ctx.stroke()
	ctx.fill()
	# muzzle
	ctx.fill_style(muz)
	ctx.begin_path()
	ctx.ellipse(0, 0 + bob, 16, 13, 0, 0, TAU)
	ctx.fill()
	# nose
	ctx.fill_style(nose)
	ctx.begin_path()
	ctx.move_to(-5, -4 + bob)
	ctx.line_to(5, -4 + bob)
	ctx.line_to(0, 1 + bob)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(0, 1 + bob)
	ctx.quadratic_curve_to(0, 6 + bob, -4, 7 + bob)
	ctx.move_to(0, 1 + bob)
	ctx.quadratic_curve_to(0, 6 + bob, 4, 7 + bob)
	ctx.stroke_style(nose)
	ctx.line_width(1.4)
	ctx.stroke()
	# eyes
	if happy:
		ctx.stroke_style(ln)
		ctx.line_width(2.4)
		ctx.begin_path()
		ctx.arc(-12, -16 + bob, 5, PI * 1.15, PI * 1.85)
		ctx.arc(12, -16 + bob, 5, PI * 1.15, PI * 1.85)
		ctx.stroke()
	else:
		for ex in [-12.0, 12.0]:
			ctx.fill_style("#fff")
			ctx.begin_path()
			ctx.ellipse(ex, -15 + bob, 4, 5, 0, 0, TAU)
			ctx.fill()
			ctx.fill_style("#1a120c")
			ctx.begin_path()
			ctx.arc(ex, -14 + bob, 2.4, 0, TAU)
			ctx.fill()
			ctx.fill_style("#fff")
			ctx.begin_path()
			ctx.arc(ex - 1, -16 + bob, 1, 0, TAU)
			ctx.fill()
	# blush
	ctx.fill_style("rgba(220,120,120,0.4)")
	ctx.begin_path()
	ctx.arc(-18, -6 + bob, 4, 0, TAU)
	ctx.arc(18, -6 + bob, 4, 0, TAU)
	ctx.fill()
	ctx.restore()
