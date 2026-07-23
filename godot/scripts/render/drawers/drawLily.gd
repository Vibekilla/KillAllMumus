extends RefCounted
## 1:1 port of HTML drawLily

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


func drawLily(b, flash) -> void:
	var R = float(b.get("r", 36))
	var fur = ("#fff" if (flash ) else "#f5f2ec")
	var furSh = ("#fff" if (flash ) else "#dcd6c9")
	var pink = "#e8b8c0"
	# fluffy body with tufted outline
	ctx.fill_style(furSh)
	for i in range(int(-4), int(4) + 1):
		ctx.begin_path()
		ctx.arc(i * R * 0.2, R * 0.92, R * 0.17, 0, 7)
		ctx.fill()
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.ellipse(0, R * 0.52, R * 0.82, R * 0.6, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(fur)
	for i in range(int(-4), int(4) + 1):
		ctx.begin_path()
		ctx.arc(i * R * 0.2, R * 0.82, R * 0.15, 0, 7)
		ctx.fill()
	# Solana collar (purple→teal) with ◎ tag
	var cg = ctx.createLinearGradient(-R * 0.5, 0, R * 0.5, 0)
	cg.addColorStop(0, "#9945ff")
	cg.addColorStop(1, "#14f195")
	ctx.stroke_style(cg)
	ctx.line_width(R * 0.15)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.arc(0, R * 0.28, R * 0.52, PI * 0.16, PI * 0.84)
	ctx.stroke()
	ctx.fill_style("#14f195")
	draw_circle_helper(0, R * 0.55, R * 0.11, "#14f195")
	ctx.fill_style("#0a2e1a")
	ctx.font("bold " + str(R * 0.15) + "px monospace")
	ctx.text_align("center")
	ctx.fill_text("◎", 0, R * 0.6)
	ctx.text_align("left")
	# pointy ears (with pink inner)
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.move_to(-R * 0.5, -R * 0.55)
	ctx.line_to(-R * 0.66, -R * 1.16)
	ctx.line_to(-R * 0.16, -R * 0.7)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.5, -R * 0.55)
	ctx.line_to(R * 0.66, -R * 1.16)
	ctx.line_to(R * 0.16, -R * 0.7)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style(pink)
	ctx.begin_path()
	ctx.move_to(-R * 0.44, -R * 0.64)
	ctx.line_to(-R * 0.55, -R * 1.0)
	ctx.line_to(-R * 0.26, -R * 0.72)
	ctx.close_path()
	ctx.fill()
	ctx.begin_path()
	ctx.move_to(R * 0.44, -R * 0.64)
	ctx.line_to(R * 0.55, -R * 1.0)
	ctx.line_to(R * 0.26, -R * 0.72)
	ctx.close_path()
	ctx.fill()
	# head — big fluffy round with cheek tufts
	ctx.fill_style(furSh)
	for a in range(int(0), int(14)):
		var ang = (float(a) / 14.0) * PI * 2.0
		ctx.begin_path()
		ctx.arc(cos(ang) * R * 0.7, -R * 0.12 + sin(ang) * R * 0.66, R * 0.14, 0, TAU)
		ctx.fill()
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.arc(0, -R * 0.12, R * 0.68, 0, 7)
	ctx.fill()
	# sleepy dark eyes
	ctx.fill_style("#1a1410")
	ctx.begin_path()
	ctx.ellipse(-R * 0.25, -R * 0.14, R * 0.1, R * 0.11, 0, 0, 7)
	ctx.ellipse(R * 0.25, -R * 0.14, R * 0.1, R * 0.11, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#fff")
	draw_circle_helper(-R * 0.28, -R * 0.17, R * 0.03, "#fff")
	draw_circle_helper(R * 0.22, -R * 0.17, R * 0.03, "#fff")
	# muzzle + black nose
	ctx.fill_style(furSh)
	ctx.begin_path()
	ctx.ellipse(0, R * 0.12, R * 0.28, R * 0.22, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.ellipse(0, R * 0.16, R * 0.2, R * 0.15, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(("#888" if (flash ) else "#141014"))
	ctx.begin_path()
	ctx.ellipse(0, R * 0.02, R * 0.12, R * 0.09, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("rgba(255,255,255,0.5)")
	draw_circle_helper(-R * 0.03, -R * 0.01, R * 0.03, "rgba(255,255,255,0.5)")
	# little frown mouth
	ctx.stroke_style("#3a2e28")
	ctx.line_width(2)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.move_to(0, R * 0.1)
	ctx.line_to(0, R * 0.2)
	ctx.move_to(0, R * 0.2)
	ctx.quadratic_curve_to(-R * 0.12, R * 0.28, -R * 0.2, R * 0.2)
	ctx.move_to(0, R * 0.2)
	ctx.quadratic_curve_to(R * 0.12, R * 0.28, R * 0.2, R * 0.2)
	ctx.stroke()
	# cross forehead crease (she's grumpy at ETH)
	ctx.stroke_style("rgba(80,60,50,0.5)")
	ctx.line_width(1.4)
	ctx.begin_path()
	ctx.move_to(-R * 0.06, -R * 0.4)
	ctx.line_to(-R * 0.02, -R * 0.28)
	ctx.move_to(R * 0.06, -R * 0.4)
	ctx.line_to(R * 0.02, -R * 0.28)
	ctx.stroke()
