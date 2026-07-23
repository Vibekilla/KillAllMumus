extends RefCounted
## 1:1 port of HTML drawBullet

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


func drawBullet(b) -> void:
	var bx := float(b.get("x", 0))
	var by := float(b.get("y", 0))
	var br := float(b.get("r", 4))
	var col := str(b.get("col", "#ff7ad1"))
	var bhp := float(b.get("hp", 0))
	ctx.save()
	ctx.translate(bx, by)
	ctx.shadow_color(col)
	ctx.shadow_blur(7)
	ctx.fill_style(col)
	ctx.begin_path()
	ctx.arc(0, 0, br, 0, TAU)
	ctx.fill()
	if bhp > 0.0:
		ctx.stroke_style("#fff")
		ctx.line_width(1.5)
		ctx.begin_path()
		ctx.arc(0, 0, br - 1.0, 0, TAU)
		ctx.stroke()
	ctx.shadow_blur(0)
	ctx.fill_style("rgba(255,255,255,0.92)")
	ctx.begin_path()
	ctx.arc(-br * 0.25, -br * 0.25, br * 0.42, 0, TAU)
	ctx.fill()
	ctx.restore()
