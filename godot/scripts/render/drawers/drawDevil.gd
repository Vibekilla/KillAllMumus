extends RefCounted
## 1:1 port of HTML drawDevil

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


func drawDevil(b, flash) -> void:
	var R = float(b.get("r", 36))
	ctx.fill_style(("#fff" if (flash ) else "#7a1420"))
	ctx.begin_path()
	ctx.ellipse(0, R * 0.55, R * 0.82, R * 0.6, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(("#fff" if (flash ) else "#c0202a"))
	ctx.begin_path()
	ctx.arc(0, -R * 0.08, R * 0.62, 0, 7)
	ctx.fill()
	# horns
	ctx.fill_style(("#eee" if (flash ) else "#2a0a10"))
	ctx.begin_path()
	ctx.move_to(-R * 0.4, -R * 0.48)
	ctx.quadratic_curve_to(-R * 0.72, -R * 1.02, -R * 0.34, -R * 1.06)
	ctx.quadratic_curve_to(-R * 0.44, -R * 0.7, -R * 0.18, -R * 0.54)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.4, -R * 0.48)
	ctx.quadratic_curve_to(R * 0.72, -R * 1.02, R * 0.34, -R * 1.06)
	ctx.quadratic_curve_to(R * 0.44, -R * 0.7, R * 0.18, -R * 0.54)
	ctx.close_path()
	ctx.fill()
	# glowing eyes
	ctx.save()
	ctx.shadow_color("#ffd000")
	ctx.shadow_blur(10)
	ctx.fill_style("#ffe23a")
	ctx.begin_path()
	ctx.move_to(-R * 0.34, -R * 0.2)
	ctx.line_to(-R * 0.08, -R * 0.1)
	ctx.line_to(-R * 0.34, -R * 0.01)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.34, -R * 0.2)
	ctx.line_to(R * 0.08, -R * 0.1)
	ctx.line_to(R * 0.34, -R * 0.01)
	ctx.close_path()
	ctx.fill()
	ctx.restore()
	ctx.fill_style("#1a0000")
	draw_circle_helper(-R * 0.2, -R * 0.1, R * 0.045, "#1a0000")
	draw_circle_helper(R * 0.2, -R * 0.1, R * 0.045, "#1a0000")
	# fanged grin
	ctx.stroke_style("#3a0000")
	ctx.line_width(2.5)
	ctx.begin_path()
	ctx.arc(0, R * 0.04, R * 0.34, 0.18, PI - 0.18)
	ctx.stroke()
	ctx.fill_style("#fff")
	for i in range(int(-2), int(2) + 1):
		var fx = i * R * 0.14
		ctx.begin_path()
		ctx.move_to(fx - R * 0.05, R * 0.2)
		ctx.line_to(fx + R * 0.02, R * 0.2)
		ctx.line_to(fx - R * 0.02, R * 0.32)
		ctx.close_path()
		ctx.fill()
	# goatee
	ctx.fill_style("#2a0a10")
	ctx.begin_path()
	ctx.move_to(-R * 0.1, R * 0.42)
	ctx.line_to(R * 0.1, R * 0.42)
	ctx.line_to(0, R * 0.64)
	ctx.close_path()
	ctx.fill()
