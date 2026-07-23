extends RefCounted
## 1:1 port of HTML drawPolice

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


func drawPolice(b, flash) -> void:
	var R = float(b.get("r", 36))
	var khaki = "#b59a4a"
	var khakiD = "#8a742e"
	var skin = "#7a4a28"
	var skinSh = "#5f3820"
	var cap = "#2a2a30"
	var gold = "#ffd24a"
	var saff = "#e08a2a"
	# khaki uniform shoulders
	ctx.fill_style(("#fff" if (flash ) else khaki))
	ctx.begin_path()
	ctx.ellipse(0, R * 0.55, R * 0.92, R * 0.6, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(gold)
	ctx.begin_path()
	ctx.round_rect(-R * 0.86, R * 0.28, R * 0.3, R * 0.12, 2)
	ctx.round_rect(R * 0.56, R * 0.28, R * 0.3, R * 0.12, 2)
	ctx.fill()
	ctx.fill_style(khakiD)
	ctx.begin_path()
	ctx.move_to(-R * 0.25, R * 0.1)
	ctx.line_to(R * 0.25, R * 0.1)
	ctx.line_to(0, R * 0.52)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style(skinSh)
	ctx.fill_rect(-R * 0.16, 0, R * 0.32, R * 0.18)
	# face
	ctx.fill_style(("#fff" if (flash ) else skin))
	ctx.begin_path()
	ctx.ellipse(0, -R * 0.12, R * 0.5, R * 0.55, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(skinSh)
	ctx.begin_path()
	ctx.ellipse(0, R * 0.18, R * 0.28, R * 0.14, 0, 0, PI)
	ctx.fill()
	# angry brows
	ctx.stroke_style("#1a1008")
	ctx.line_width(R * 0.07)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.move_to(-R * 0.32, -R * 0.18)
	ctx.line_to(-R * 0.08, -R * 0.06)
	ctx.move_to(R * 0.32, -R * 0.18)
	ctx.line_to(R * 0.08, -R * 0.06)
	ctx.stroke()
	# corrupted glowing saffron eyes
	ctx.save()
	ctx.shadow_color(saff)
	ctx.shadow_blur(8)
	draw_circle_helper(-R * 0.18, -R * 0.02, R * 0.09, ("#fff" if (flash ) else saff))
	draw_circle_helper(R * 0.18, -R * 0.02, R * 0.09, ("#fff" if (flash ) else saff))
	ctx.restore()
	ctx.fill_style("#2a1500")
	draw_circle_helper(-R * 0.18, -R * 0.02, R * 0.04, "#2a1500")
	draw_circle_helper(R * 0.18, -R * 0.02, R * 0.04, "#2a1500")
	# big mustache
	ctx.fill_style(("#eee" if (flash ) else "#1a1008"))
	ctx.begin_path()
	ctx.move_to(0, R * 0.12)
	ctx.quadratic_curve_to(-R * 0.28, R * 0.06, -R * 0.34, R * 0.2)
	ctx.quadratic_curve_to(-R * 0.2, R * 0.16, 0, R * 0.18)
	ctx.quadratic_curve_to(R * 0.2, R * 0.16, R * 0.34, R * 0.2)
	ctx.quadratic_curve_to(R * 0.28, R * 0.06, 0, R * 0.12)
	ctx.fill()
	ctx.fill_style("#3a1414")
	ctx.begin_path()
	ctx.ellipse(0, R * 0.26, R * 0.12, R * 0.05, 0, 0, 7)
	ctx.fill()
	# peaked police cap
	ctx.fill_style(("#fff" if (flash ) else cap))
	ctx.begin_path()
	ctx.ellipse(0, -R * 0.5, R * 0.6, R * 0.3, 0, PI, 0)
	ctx.fill()
	ctx.fill_style(cap)
	ctx.begin_path()
	ctx.ellipse(0, -R * 0.42, R * 0.64, R * 0.16, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#12121a")
	ctx.begin_path()
	ctx.ellipse(0, -R * 0.34, R * 0.66, R * 0.12, 0, 0, PI)
	ctx.fill()
	ctx.fill_style(gold)
	ctx.begin_path()
	ctx.arc(0, -R * 0.5, R * 0.11, 0, 7)
	ctx.fill()
	ctx.fill_style(saff)
	ctx.begin_path()
	ctx.arc(0, -R * 0.5, R * 0.05, 0, 7)
	ctx.fill()
	# call-center headset
	ctx.stroke_style("#20202a")
	ctx.line_width(R * 0.05)
	ctx.begin_path()
	ctx.arc(0, -R * 0.5, R * 0.6, PI * 1.12, PI * 1.88)
	ctx.stroke()
	ctx.fill_style("#20202a")
	ctx.begin_path()
	ctx.ellipse(R * 0.56, -R * 0.26, R * 0.09, R * 0.13, 0, 0, 7)
	ctx.fill()
	ctx.stroke_style("#20202a")
	ctx.line_width(R * 0.035)
	ctx.begin_path()
	ctx.move_to(R * 0.56, -R * 0.16)
	ctx.quadratic_curve_to(R * 0.42, R * 0.12, R * 0.14, R * 0.22)
	ctx.stroke()
	ctx.fill_style(saff)
	ctx.begin_path()
	ctx.arc(R * 0.14, R * 0.22, R * 0.045, 0, 7)
	ctx.fill()
