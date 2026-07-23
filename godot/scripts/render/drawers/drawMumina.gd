extends RefCounted
## 1:1 port of HTML drawMumina

var ctx
var tick: int = 0
var selected_outfit: String = "og"
var EAR_HIDE := {
	"neko": true, "monke": true, "kigurumi": true, "cheese": true, "cabal": true,
	"badger": true, "viking": true, "samurai": true, "bullbina": true, "jester": true,
	"succubus": true, "squirrely": true, "banana": true
}
var _armCol = "#5f3823"
var _armW: float = 3.8
var _handCols = null
var _hold = null
var _armSw: float = 0.0
var _sBob: float = 0.0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func set_outfit(o: String) -> void:
	selected_outfit = o

func p_orb(x, y, glow, c1, c2) -> void:
	ctx.save()
	ctx.translate(float(x), float(y))
	ctx.global_alpha(0.55)
	ctx.fill_style(str(glow))
	ctx.begin_path()
	ctx.arc(0, 0, 5.5, 0, TAU)
	ctx.fill()
	ctx.global_alpha(1.0)
	ctx.fill_style(str(c1))
	ctx.begin_path()
	ctx.arc(0, 0, 3.2, 0, TAU)
	ctx.fill()
	ctx.fill_style(str(c2))
	ctx.begin_path()
	ctx.arc(-0.8, -0.8, 1.2, 0, TAU)
	ctx.fill()
	ctx.restore()

func draw_circle_helper(x, y, r, col) -> void:
	ctx.fill_style(col)
	ctx.begin_path()
	ctx.arc(float(x), float(y), float(r), 0, TAU)
	ctx.fill()

func _hexA(h, a) -> String:
	var c: Array = _hexRgb(h)
	return "rgba(%d,%d,%d,%s)" % [int(c[0]), int(c[1]), int(c[2]), str(a)]

func _hexRgb(h) -> Array:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return [(n >> 16) & 255, (n >> 8) & 255, n & 255]

func _rgbHue(r, g, b) -> float:
	r = float(r) / 255.0
	g = float(g) / 255.0
	b = float(b) / 255.0
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


func drawMumina(b, flash) -> void:
	var R = float(b.get("r", 36))
	# body (green uniform)
	ctx.fill_style(("#fff" if (flash ) else "#2f6b3a"))
	ctx.begin_path()
	ctx.ellipse(0, R * 0.55, R * 0.85, R * 0.7, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#f4efe6")
	ctx.fill_rect(-R * 0.06, R * 0.08, R * 0.12, R * 0.36)
	ctx.fill_style(("#fff" if (flash ) else "#3f8a4a"))
	ctx.begin_path()
	ctx.move_to(0, R * 0.08)
	ctx.line_to(-R * 0.16, R * 0.5)
	ctx.line_to(R * 0.16, R * 0.5)
	ctx.close_path()
	ctx.fill()
	# hair back
	ctx.fill_style(("#fff" if (flash ) else "#c96a24"))
	ctx.begin_path()
	ctx.arc(0, -R * 0.18, R * 0.78, 0, 7)
	ctx.fill()
	# face
	ctx.fill_style(("#fff" if (flash ) else "#f0c9a0"))
	ctx.begin_path()
	ctx.arc(0, -R * 0.24, R * 0.55, 0, 7)
	ctx.fill()
	# white bull horns
	ctx.fill_style(("#fff" if (flash ) else "#f0ead6"))
	ctx.stroke_style("#cbbf9a")
	ctx.line_width(1.5)
	ctx.begin_path()
	ctx.move_to(-R * 0.4, -R * 0.55)
	ctx.quadratic_curve_to(-R * 0.98, -R * 0.85, -R * 0.78, -R * 1.16)
	ctx.quadratic_curve_to(-R * 0.55, -R * 0.8, -R * 0.25, -R * 0.6)
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.4, -R * 0.55)
	ctx.quadratic_curve_to(R * 0.98, -R * 0.85, R * 0.78, -R * 1.16)
	ctx.quadratic_curve_to(R * 0.55, -R * 0.8, R * 0.25, -R * 0.6)
	ctx.fill()
	# bangs
	ctx.fill_style(("#fff" if (flash ) else "#e8873a"))
	ctx.begin_path()
	ctx.move_to(-R * 0.56, -R * 0.28)
	ctx.quadratic_curve_to(-R * 0.5, -R * 0.82, 0, -R * 0.84)
	ctx.quadratic_curve_to(R * 0.5, -R * 0.82, R * 0.56, -R * 0.28)
	ctx.quadratic_curve_to(R * 0.3, -R * 0.5, R * 0.16, -R * 0.32)
	ctx.quadratic_curve_to(0, -R * 0.5, -R * 0.16, -R * 0.32)
	ctx.quadratic_curve_to(-R * 0.3, -R * 0.5, -R * 0.56, -R * 0.28)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(-R * 0.53, -R * 0.08, R * 0.14, R * 0.4, 0.1, 0, 7)
	ctx.ellipse(R * 0.53, -R * 0.08, R * 0.14, R * 0.4, -0.1, 0, 7)
	ctx.fill()
	# green bow
	ctx.fill_style(("#fff" if (flash ) else "#4a9e3a"))
	ctx.begin_path()
	ctx.move_to(R * 0.46, -R * 0.5)
	ctx.line_to(R * 0.64, -R * 0.62)
	ctx.line_to(R * 0.64, -R * 0.38)
	ctx.close_path()
	ctx.move_to(R * 0.46, -R * 0.5)
	ctx.line_to(R * 0.28, -R * 0.62)
	ctx.line_to(R * 0.28, -R * 0.38)
	ctx.close_path()
	ctx.fill()
	draw_circle_helper(R * 0.46, -R * 0.5, R * 0.06, ("#fff" if (flash ) else "#3a7e2a"))
	# green eyes
	ctx.fill_style("#fff")
	ctx.begin_path()
	ctx.ellipse(-R * 0.2, -R * 0.2, R * 0.13, R * 0.17, 0, 0, 7)
	ctx.ellipse(R * 0.2, -R * 0.2, R * 0.13, R * 0.17, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#5fae3a")
	draw_circle_helper(-R * 0.2, -R * 0.18, R * 0.09, "#5fae3a")
	draw_circle_helper(R * 0.2, -R * 0.18, R * 0.09, "#5fae3a")
	ctx.fill_style("#123a0a")
	draw_circle_helper(-R * 0.2, -R * 0.18, R * 0.045, "#123a0a")
	draw_circle_helper(R * 0.2, -R * 0.18, R * 0.045, "#123a0a")
	ctx.fill_style("#fff")
	draw_circle_helper(-R * 0.23, -R * 0.22, R * 0.03, "#fff")
	draw_circle_helper(R * 0.17, -R * 0.22, R * 0.03, "#fff")
	ctx.fill_style("rgba(220,120,120,0.4)")
	draw_circle_helper(-R * 0.33, -R * 0.04, R * 0.07, "rgba(220,120,120,0.4)")
	draw_circle_helper(R * 0.33, -R * 0.04, R * 0.07, "rgba(220,120,120,0.4)")
	ctx.fill_style("#a94a4a")
	ctx.begin_path()
	ctx.ellipse(0, -R * 0.02, R * 0.06, R * 0.045, 0, 0, 7)
	ctx.fill()
	# gold crown
	ctx.fill_style(("#fff" if (flash ) else "#ffd24a"))
	ctx.begin_path()
	ctx.move_to(-R * 0.26, -R * 0.72)
	ctx.line_to(-R * 0.26, -R * 0.9)
	ctx.line_to(-R * 0.13, -R * 0.78)
	ctx.line_to(0, -R * 0.98)
	ctx.line_to(R * 0.13, -R * 0.78)
	ctx.line_to(R * 0.26, -R * 0.9)
	ctx.line_to(R * 0.26, -R * 0.72)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("#e0102a")
	draw_circle_helper(0, -R * 0.85, R * 0.04, "#e0102a")
