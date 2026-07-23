extends RefCounted
## 1:1 port of HTML drawMumu (lil/big mumus — elites use drawElite).

var ctx
var tick: int = 0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func draw_circle_helper(x, y, r, col) -> void:
	ctx.fill_style(col)
	ctx.begin_path()
	ctx.arc(float(x), float(y), float(r), 0, TAU)
	ctx.fill()

func drawMumu(e) -> void:
	if str(e.get("kind", "")) == "elite":
		return  # routed to drawElite by PortedDraw
	var flash: bool = float(e.get("flash", 0)) > 0.0
	var R: float = float(e.get("r", 15))
	var icy: bool = bool(e.get("icy", false))
	var et: float = float(e.get("t", 0))
	ctx.save()
	ctx.translate(float(e.get("x", 0)), float(e.get("y", 0)))
	var body: String = "#fff" if flash else ("#bfe6ff" if icy else "#d9a487")
	var bodySh: String = "#8fc4ee" if icy else "#b07a5e"
	var belly: String = "#fff" if flash else ("#eaf6ff" if icy else "#f4e0d2")
	var horn := "#efe6d2"
	var ln := "#3a2018"
	var bob := sin(et * 0.14) * 1.5
	# shadow
	ctx.fill_style("rgba(0,0,0,0.18)")
	ctx.begin_path()
	ctx.ellipse(0, R * 0.9, R * 0.7, 4, 0, 0, TAU)
	ctx.fill()
	# body
	ctx.begin_path()
	ctx.ellipse(0, bob, R * 0.8, R * 0.78, 0, 0, TAU)
	ctx.stroke_style(ln)
	ctx.line_width(2)
	ctx.stroke()
	ctx.fill_style(body)
	ctx.fill()
	# belly patch
	ctx.fill_style(belly)
	ctx.begin_path()
	ctx.ellipse(0, bob + R * 0.28, R * 0.4, R * 0.42, 0, 0, TAU)
	ctx.fill()
	# hands
	draw_circle_helper(-R * 0.7, bob + R * 0.3, R * 0.2, "#fff" if flash else bodySh)
	draw_circle_helper(R * 0.7, bob + R * 0.3, R * 0.2, "#fff" if flash else bodySh)
	# ears
	ctx.fill_style("#fff" if flash else bodySh)
	ctx.begin_path()
	ctx.ellipse(-R * 0.72, bob - R * 0.5, R * 0.22, R * 0.15, -0.6, 0, TAU)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(R * 0.72, bob - R * 0.5, R * 0.22, R * 0.15, 0.6, 0, TAU)
	ctx.fill()
	# horns
	ctx.fill_style("#fff" if flash else horn)
	ctx.begin_path()
	ctx.move_to(-R * 0.5, bob - R * 0.55)
	ctx.quadratic_curve_to(-R * 0.95, bob - R * 0.95, -R * 0.5, bob - R * 1.05)
	ctx.quadratic_curve_to(-R * 0.4, bob - R * 0.75, -R * 0.3, bob - R * 0.6)
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.5, bob - R * 0.55)
	ctx.quadratic_curve_to(R * 0.95, bob - R * 0.95, R * 0.5, bob - R * 1.05)
	ctx.quadratic_curve_to(R * 0.4, bob - R * 0.75, R * 0.3, bob - R * 0.6)
	ctx.fill()
	# snout
	ctx.fill_style("#fff" if flash else belly)
	ctx.begin_path()
	ctx.ellipse(0, bob + R * 0.18, R * 0.34, R * 0.26, 0, 0, TAU)
	ctx.fill()
	ctx.stroke_style(ln)
	ctx.line_width(1)
	ctx.stroke()
	ctx.fill_style(bodySh)
	draw_circle_helper(-R * 0.14, bob + R * 0.14, R * 0.06, bodySh)
	draw_circle_helper(R * 0.14, bob + R * 0.14, R * 0.06, bodySh)
	# eyes
	draw_circle_helper(-R * 0.28, bob - R * 0.08, R * 0.18, "#fff")
	draw_circle_helper(R * 0.28, bob - R * 0.08, R * 0.18, "#fff")
	draw_circle_helper(-R * 0.28, bob - R * 0.05, R * 0.09, "#c0202a")
	draw_circle_helper(R * 0.28, bob - R * 0.05, R * 0.09, "#c0202a")
	draw_circle_helper(-R * 0.28, bob - R * 0.05, R * 0.04, "#150a0a")
	draw_circle_helper(R * 0.28, bob - R * 0.05, R * 0.04, "#150a0a")
	# brows
	ctx.stroke_style(ln)
	ctx.line_width(1.6)
	ctx.begin_path()
	ctx.move_to(-R * 0.45, bob - R * 0.3)
	ctx.line_to(-R * 0.14, bob - R * 0.16)
	ctx.move_to(R * 0.45, bob - R * 0.3)
	ctx.line_to(R * 0.14, bob - R * 0.16)
	ctx.stroke()
	if icy:
		ctx.stroke_style("rgba(255,255,255,0.6)")
		ctx.line_width(1)
		ctx.begin_path()
		ctx.move_to(-R * 0.5, -R * 0.2)
		ctx.line_to(R * 0.5, R * 0.2)
		ctx.move_to(R * 0.4, -R * 0.4)
		ctx.line_to(-R * 0.3, R * 0.4)
		ctx.stroke()
	ctx.restore()
