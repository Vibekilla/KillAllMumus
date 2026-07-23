extends RefCounted
## 1:1 port of HTML drawBogdanoff

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


func drawBogdanoff(b, flash) -> void:
	var R = float(b.get("r", 36))
	# which twin is on the strings? (fake bust passes no active → reflect the live boss, else default Igor)
	var igor: bool = true
	if b.get("active", null) != null:
		igor = str(b.get("active")) == "igor"
	var skin = ("#fff" if (flash ) else "#c99a6a")
	var skinSh = "#a2764c"
	var hair = ("#fff" if (flash ) else "#e8dcc4")
	var tux = "#20202a"
	var accent = ("#b48ce0" if (igor ) else "#e0b84a")
	var bust = b.get("t", 0) == null
	# astral aura behind him (pulses on the field, static in the dialogue picture)
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.global_alpha((0.34 if (bust ) else 0.32 + 0.16 * sin(tick * 0.1)))
	ctx.fill_style(accent)
	ctx.begin_path()
	ctx.arc(0, -R * 0.05, R * 1.05, 0, 7)
	ctx.fill()
	ctx.restore()
	# faint puppet strings descending from above
	ctx.stroke_style(_hexA(accent, 0.35))
	ctx.line_width(1)
	ctx.begin_path()
	ctx.move_to(-R * 0.5, R * 0.2)
	ctx.line_to(-R * 0.72, -R * 1.4)
	ctx.move_to(R * 0.5, R * 0.2)
	ctx.line_to(R * 0.72, -R * 1.4)
	ctx.stroke()
	# tuxedo shoulders + shirt + bow tie
	ctx.fill_style(tux)
	ctx.begin_path()
	ctx.ellipse(0, R * 0.72, R * 0.95, R * 0.5, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#f4efe6")
	ctx.begin_path()
	ctx.move_to(0, R * 0.3)
	ctx.line_to(-R * 0.15, R * 0.72)
	ctx.line_to(R * 0.15, R * 0.72)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style(accent)
	ctx.begin_path()
	ctx.move_to(0, R * 0.32)
	ctx.line_to(-R * 0.08, R * 0.5)
	ctx.line_to(0, R * 0.62)
	ctx.line_to(R * 0.08, R * 0.5)
	ctx.close_path()
	ctx.fill()
	# long gaunt face with the signature jutting chin + high cheekbones
	ctx.fill_style(skin)
	ctx.begin_path()
	ctx.move_to(-R * 0.42, -R * 0.34)
	ctx.quadratic_curve_to(-R * 0.54, R * 0.04, -R * 0.34, R * 0.3)
	ctx.quadratic_curve_to(-R * 0.2, R * 0.64, 0, R * 0.68)
	ctx.quadratic_curve_to(R * 0.2, R * 0.64, R * 0.34, R * 0.3)
	ctx.quadratic_curve_to(R * 0.54, R * 0.04, R * 0.42, -R * 0.34)
	ctx.quadratic_curve_to(0, -R * 0.5, -R * 0.42, -R * 0.34)
	ctx.close_path()
	ctx.fill()
	# cheekbone + jaw shadows (over-sculpted look)
	ctx.fill_style(skinSh)
	ctx.begin_path()
	ctx.ellipse(-R * 0.3, R * 0.14, R * 0.1, R * 0.2, 0.3, 0, 7)
	ctx.ellipse(R * 0.3, R * 0.14, R * 0.1, R * 0.2, -0.3, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(0, R * 0.5, R * 0.16, R * 0.12, 0, 0, 7)
	ctx.fill()
	# huge swept-back hair
	ctx.fill_style(hair)
	ctx.begin_path()
	ctx.move_to(-R * 0.44, -R * 0.26)
	ctx.quadratic_curve_to(-R * 0.62, -R * 0.92, -R * 0.08, -R * 0.82)
	ctx.quadratic_curve_to(R * 0.12, -R * 1.08, R * 0.52, -R * 0.76)
	ctx.quadratic_curve_to(R * 0.72, -R * 0.48, R * 0.44, -R * 0.26)
	ctx.quadratic_curve_to(R * 0.2, -R * 0.48, 0, -R * 0.44)
	ctx.quadratic_curve_to(-R * 0.2, -R * 0.48, -R * 0.44, -R * 0.26)
	ctx.close_path()
	ctx.fill()
	# hair sweep lines
	ctx.stroke_style(_hexA("#c9bfa2", 0.6))
	ctx.line_width(1.2)
	ctx.begin_path()
	for i in range(int(-2), int(3) + 1):
		ctx.move_to(i * R * 0.16, -R * 0.4)
		ctx.quadratic_curve_to(i * R * 0.16 - R * 0.2, -R * 0.75, i * R * 0.16 - R * 0.05, -R * 0.9)
	ctx.stroke()
	# heavy brow + deep-set glowing eyes
	ctx.stroke_style("#3a2a1a")
	ctx.line_width(R * 0.06)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.move_to(-R * 0.32, -R * 0.12)
	ctx.line_to(-R * 0.08, -R * 0.05)
	ctx.move_to(R * 0.32, -R * 0.12)
	ctx.line_to(R * 0.08, -R * 0.05)
	ctx.stroke()
	ctx.save()
	ctx.shadow_color(accent)
	ctx.shadow_blur(8)
	draw_circle_helper(-R * 0.2, 0.02 * R, R * 0.07, ("#fff" if (flash ) else accent))
	draw_circle_helper(R * 0.2, 0.02 * R, R * 0.07, ("#fff" if (flash ) else accent))
	ctx.restore()
	ctx.fill_style("#1a1008")
	draw_circle_helper(-R * 0.2, 0.02 * R, R * 0.03, "#1a1008")
	draw_circle_helper(R * 0.2, 0.02 * R, R * 0.03, "#1a1008")
	# long nose + thin flat mouth
	ctx.stroke_style(skinSh)
	ctx.line_width(2)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.move_to(0, -R * 0.02)
	ctx.line_to(-R * 0.05, R * 0.2)
	ctx.line_to(R * 0.04, R * 0.22)
	ctx.stroke()
	ctx.stroke_style("#7a4a3a")
	ctx.begin_path()
	ctx.move_to(-R * 0.13, R * 0.38)
	ctx.quadratic_curve_to(0, R * 0.34, R * 0.13, R * 0.38)
	ctx.stroke()
	# initial floating above (I / G)
	ctx.fill_style(accent)
	ctx.font("bold " + R * 0.32 + "px \"Trebuchet MS\"")
	ctx.text_align("center")
	ctx.save()
	ctx.shadow_color(accent)
	ctx.shadow_blur(8)
	ctx.fill_text(("I" if (igor ) else "G"), 0, -R * 0.62)
	ctx.restore()
	ctx.text_align("left")
