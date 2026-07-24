extends RefCounted
## 1:1 port of HTML drawPShot

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


func drawPShot(s) -> void:
	var sx := float(s.get("x", 0))
	var sy := float(s.get("y", 0))
	var vx := float(s.get("vx", 0))
	var vy := float(s.get("vy", -1))
	ctx.save()
	ctx.translate(sx, sy)
	if bool(s.get("gat", false)):
		ctx.rotate(atan2(vy, vx) + PI / 2.0)
		ctx.shadow_color("#7ed957")
		ctx.shadow_blur(10)
		for dy2 in [-4.0, -1.5, 1.5, 4.0]:
			ctx.fill_style("#d6ffb0")
			ctx.begin_path()
			ctx.arc(0, dy2, 2.2, 0, TAU)
			ctx.fill()
		ctx.fill_style("#3fbf2f")
		ctx.begin_path()
		ctx.arc(0, 0, 1.1, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	if bool(s.get("nade", false)):
		ctx.shadow_color("#b6e34a")
		ctx.shadow_blur(8)
		ctx.fill_style("#586a28")
		ctx.begin_path()
		ctx.arc(0, 0, 3.8, 0, TAU)
		ctx.fill()
		ctx.fill_style("#b6e34a")
		ctx.begin_path()
		ctx.arc(0, 0, 1.9, 0, TAU)
		ctx.fill()
		ctx.fill_style("#fff" if (tick % 4 < 2) else "#ffd27a")
		ctx.begin_path()
		ctx.arc(0, -4.6, 1.2, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	if bool(s.get("vrip", false)):
		ctx.rotate(atan2(vy, vx) + PI / 2.0)
		ctx.shadow_color("#9d6bff")
		ctx.shadow_blur(12)
		ctx.fill_style("rgba(157,107,255,0.9)")
		ctx.begin_path()
		ctx.move_to(0, -12)
		ctx.line_to(3.2, 0)
		ctx.line_to(0, 12)
		ctx.line_to(-3.2, 0)
		ctx.close_path()
		ctx.fill()
		ctx.fill_style("#160530")
		ctx.begin_path()
		ctx.ellipse(0, 0, 1.4, 8, 0, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	if bool(s.get("petal", false)):
		ctx.rotate(atan2(vy, vx) + PI / 2.0 + float(tick) * 0.25)
		ctx.shadow_color("#ff8ac0")
		ctx.shadow_blur(8)
		ctx.fill_style("#ffd0e6")
		ctx.begin_path()
		ctx.move_to(0, -5.6)
		ctx.quadratic_curve_to(3.2, -1, 0, 4.2)
		ctx.quadratic_curve_to(-3.2, -1, 0, -5.6)
		ctx.fill()
		ctx.fill_style("#ff5b9d")
		ctx.begin_path()
		ctx.move_to(0, -3)
		ctx.quadratic_curve_to(1.4, -0.4, 0, 2.6)
		ctx.quadratic_curve_to(-1.4, -0.4, 0, -3)
		ctx.fill()
		ctx.fill_style("#fff")
		ctx.begin_path()
		ctx.arc(0, -4.1, 0.7, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	if bool(s.get("zap", false)):
		ctx.rotate(atan2(vy, vx) + PI / 2.0)
		ctx.shadow_color("#8fd0ff")
		ctx.shadow_blur(11)
		ctx.line_cap("round")
		ctx.stroke_style("#eaf6ff")
		ctx.line_width(2)
		ctx.begin_path()
		ctx.move_to(0, -8)
		ctx.line_to(2.4, -2)
		ctx.line_to(-2.4, 2)
		ctx.line_to(0, 8)
		ctx.stroke()
		ctx.stroke_style("#5fb0ff")
		ctx.line_width(0.9)
		ctx.stroke()
		ctx.restore()
		return
	if bool(s.get("laser", false)):
		# Face travel; one arc per fill (multi-subpath fills triangulate badly)
		ctx.rotate(atan2(vy, vx) + PI / 2.0)
		ctx.shadow_color("#ff3b5c")
		ctx.shadow_blur(11)
		for dy in [-5.0, -2.5, 0.0, 2.5, 5.0]:
			ctx.fill_style("#ffd2da")
			ctx.begin_path()
			ctx.arc(0, dy, 2.8, 0, TAU)
			ctx.fill()
			ctx.fill_style("#ff2f52")
			ctx.begin_path()
			ctx.arc(0, dy, 1.4, 0, TAU)
			ctx.fill()
		ctx.restore()
		return
	if float(s.get("wv", 0)) > 0.0:
		ctx.rotate(atan2(vy, vx) + PI / 2.0)
		ctx.shadow_color("#7ed957")
		ctx.shadow_blur(9)
		ctx.fill_style("#daffb4")
		ctx.begin_path()
		ctx.arc(0, 0, 4.0, 0, TAU)
		ctx.fill()
		ctx.fill_style("#4fb02f")
		ctx.begin_path()
		ctx.arc(0, 0, 1.7, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	if bool(s.get("home", false)):
		ctx.shadow_color("#ffe14a")
		ctx.shadow_blur(9)
		ctx.fill_style("#fff4a8")
		ctx.begin_path()
		ctx.arc(0, -1.5, 3.6, 0, TAU)
		ctx.fill()
		ctx.begin_path()
		ctx.arc(0, 1.5, 3.6, 0, TAU)
		ctx.fill()
		ctx.fill_style("#ffcf1a")
		ctx.begin_path()
		ctx.arc(0, 0, 1.6, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	# life_frames is always a float on bullets (-1 = unlimited); only treat >=0 as timed orbs
	var life_v = s.get("life", null)
	if life_v != null and float(life_v) >= 0.0:
		ctx.shadow_color("#e0a060")
		ctx.shadow_blur(7)
		ctx.fill_style("#f2d3a6")
		ctx.begin_path()
		ctx.arc(0, 0, 3, 0, TAU)
		ctx.fill()
		ctx.fill_style("#c8813e")
		ctx.begin_path()
		ctx.arc(0, 0, 1.3, 0, TAU)
		ctx.fill()
		ctx.restore()
		return
	# Emblem Amulets (spread) — gold
	ctx.shadow_color("#ffd27a")
	ctx.shadow_blur(9)
	var foc := bool(s.get("foc", false))
	ctx.fill_style("#fff4d6" if foc else "#ffe6a6")
	var w := 4.0 if foc else 3.4
	ctx.begin_path()
	ctx.arc(0, 0, w, 0, TAU)
	ctx.fill()
	ctx.fill_style("#ffb63a")
	ctx.begin_path()
	ctx.arc(0, 0, 1.2, 0, TAU)
	ctx.fill()
	ctx.restore()
