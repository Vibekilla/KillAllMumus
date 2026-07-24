extends RefCounted
## 1:1 port of HTML drawElite

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


func drawElite(e) -> void:
	var R = e.get("r", 0)
	var fl = e.get("flash", 0) > 0
	var bob = sin(e.get("t", 0) * 0.14) * 1.6
	var ln = "#2a1a12"
	ctx.save()
	ctx.translate(e.get("x", 0), e.get("y", 0))
	ctx.fill_style("rgba(0,0,0,0.2)")
	ctx.begin_path()
	ctx.ellipse(0, R * 0.98, R * 0.72, 4, 0, 0, 7)
	ctx.fill()
	ctx.translate(0, bob)
	var K = str(e.get("elite", ""))
	if K == "cheer":
		# Mini Mumina — a bear-girl like Bobina in a green cheer kit, waving pom-poms
		var skin = ("#fff" if (fl ) else "#7c4c31")
		var hair = ("#fff" if (fl ) else "#181320")
		var dress = ("#fff" if (fl ) else "#7ed957")
		var trim = ("#fff" if (fl ) else "#eafff0")
		var pw = sin(e.get("t", 0) * 0.3) * R * 0.12
		ctx.stroke_style(skin)
		ctx.line_width(R * 0.15)
		ctx.line_cap("round")
		ctx.begin_path()
		ctx.move_to(-R * 0.3, -R * 0.05)
		ctx.line_to(-R * 0.7, -R * 0.42)
		ctx.move_to(R * 0.3, -R * 0.05)
		ctx.line_to(R * 0.7, -R * 0.42)
		ctx.stroke()
		ctx.fill_style(("#fff" if (fl ) else "#c8ff9a"))
		for sx in [-1, 1]:
			for k in range(int(0), int(8)):
				var a = (float(k) / 8.0) * 6.28
				ctx.begin_path()
				ctx.arc(float(sx) * R * 0.72 + pw * float(sx) + cos(a) * R * 0.17, -R * 0.5 + sin(a) * R * 0.17, R * 0.11, 0, TAU)
				ctx.fill()
		ctx.fill_style(dress)
		ctx.begin_path()
		ctx.move_to(-R * 0.4, -R * 0.08)
		ctx.line_to(-R * 0.6, R * 0.62)
		ctx.line_to(R * 0.6, R * 0.62)
		ctx.line_to(R * 0.4, -R * 0.08)
		ctx.close_path()
		ctx.fill()
		ctx.fill_style(trim)
		for i in range(float(-R * 0.55), float(R * 0.5), float(R * 0.24)):
			ctx.begin_path()
			ctx.arc(i + R * 0.12, R * 0.62, R * 0.12, 0, PI)
			ctx.fill()
		ctx.fill_style(dress)
		ctx.fill_rect(-R * 0.42, -R * 0.28, R * 0.84, R * 0.42)
		ctx.fill_style(trim)
		ctx.fill_rect(-R * 0.42, -R * 0.02, R * 0.84, R * 0.09)
		ctx.stroke_style(skin)
		ctx.line_width(R * 0.15)
		ctx.begin_path()
		ctx.move_to(-R * 0.2, R * 0.58)
		ctx.line_to(-R * 0.24, R * 0.88)
		ctx.move_to(R * 0.2, R * 0.58)
		ctx.line_to(R * 0.24, R * 0.88)
		ctx.stroke()
		ctx.fill_style(hair)
		ctx.begin_path()
		ctx.arc(0, -R * 0.5, R * 0.5, PI * 0.9, PI * 2.1)
		ctx.fill()
		draw_circle_helper(-R * 0.52, -R * 0.46, R * 0.17, hair)
		draw_circle_helper(R * 0.52, -R * 0.46, R * 0.17, hair)
		ctx.fill_style(skin)
		ctx.begin_path()
		ctx.arc(0, -R * 0.5, R * 0.42, 0, 7)
		ctx.fill()
		draw_circle_helper(-R * 0.32, -R * 0.86, R * 0.15, hair)
		draw_circle_helper(R * 0.32, -R * 0.86, R * 0.15, hair)
		draw_circle_helper(-R * 0.32, -R * 0.86, R * 0.07, ("#fff" if (fl ) else "#5f3823"))
		draw_circle_helper(R * 0.32, -R * 0.86, R * 0.07, ("#fff" if (fl ) else "#5f3823"))
		ctx.fill_style(hair)
		ctx.begin_path()
		ctx.move_to(-R * 0.42, -R * 0.62)
		ctx.quadratic_curve_to(0, -R * 0.98, R * 0.42, -R * 0.62)
		ctx.line_to(R * 0.3, -R * 0.5)
		ctx.quadratic_curve_to(0, -R * 0.72, -R * 0.3, -R * 0.5)
		ctx.close_path()
		ctx.fill()
		draw_circle_helper(-R * 0.16, -R * 0.46, R * 0.1, "#fff")
		draw_circle_helper(R * 0.16, -R * 0.46, R * 0.1, "#fff")
		ctx.fill_style("#3a2018")
		draw_circle_helper(-R * 0.16, -R * 0.44, R * 0.05, "#3a2018")
		draw_circle_helper(R * 0.16, -R * 0.44, R * 0.05, "#3a2018")
		ctx.fill_style("rgba(255,120,150,0.5)")
		draw_circle_helper(-R * 0.29, -R * 0.33, R * 0.07, "rgba(255,120,150,0.5)")
		draw_circle_helper(R * 0.29, -R * 0.33, R * 0.07, "rgba(255,120,150,0.5)")
		ctx.stroke_style(ln)
		ctx.line_width(1.2)
		ctx.begin_path()
		ctx.arc(0, -R * 0.37, R * 0.1, 0.15 * PI, 0.85 * PI)
		ctx.stroke()
	elif K == "ape":
		var fur = ("#fff" if (fl ) else "#a9743e")
		var face = ("#fff" if (fl ) else "#e8c9a0")
		ctx.fill_style(fur)
		draw_circle_helper(-R * 0.7, -R * 0.15, R * 0.28, fur)
		draw_circle_helper(R * 0.7, -R * 0.15, R * 0.28, fur)
		ctx.fill_style(fur)
		ctx.begin_path()
		ctx.arc(0, 0, R * 0.8, 0, 7)
		ctx.fill()
		ctx.fill_style(face)
		ctx.begin_path()
		ctx.ellipse(0, R * 0.14, R * 0.5, R * 0.56, 0, 0, 7)
		ctx.fill()
		ctx.fill_style("#3a2410")
		ctx.fill_rect(-R * 0.4, -R * 0.16, R * 0.8, R * 0.13)
		draw_circle_helper(-R * 0.2, 0.02 * R, R * 0.09, "#fff")
		draw_circle_helper(R * 0.2, 0.02 * R, R * 0.09, "#fff")
		ctx.fill_style("#150a0a")
		draw_circle_helper(-R * 0.2, R * 0.03, R * 0.045, "#150a0a")
		draw_circle_helper(R * 0.2, R * 0.03, R * 0.045, "#150a0a")
		ctx.fill_style("#7a2c2c")
		ctx.begin_path()
		ctx.ellipse(0, R * 0.36, R * 0.24, R * 0.13, 0, 0, 7)
		ctx.fill()
		ctx.fill_style("#ffd24a")
		ctx.fill_rect(-R * 0.14, R * 0.31, R * 0.28, R * 0.06)
		ctx.stroke_style("#ffd24a")
		ctx.line_width(2.2)
		ctx.begin_path()
		ctx.arc(0, R * 0.72, R * 0.42, 0.16 * PI, 0.84 * PI)
		ctx.stroke()
	elif K == "badnik":
		var metal = ("#fff" if (fl ) else "#c2c8ce")
		var sh = "#8a929a"
		var pink = ("#fff" if (fl ) else "#e05a86")
		ctx.fill_style(metal)
		ctx.begin_path()
		ctx.ellipse(0, 0, R * 0.62, R * 0.82, 0, 0, 7)
		ctx.fill()
		ctx.fill_style(sh)
		ctx.begin_path()
		ctx.ellipse(R * 0.22, R * 0.05, R * 0.2, R * 0.7, 0, 0, 7)
		ctx.fill()
		ctx.fill_style(pink)
		ctx.begin_path()
		ctx.arc(0, -R * 0.12, R * 0.26, 0, 7)
		ctx.fill()
		draw_circle_helper(0, -R * 0.12, R * 0.16, "#fff")
		ctx.fill_style("#150a0a")
		draw_circle_helper(0, -R * 0.1, R * 0.08, "#150a0a")
		ctx.stroke_style(sh)
		ctx.line_width(1.6)
		ctx.begin_path()
		ctx.move_to(0, -R * 0.8)
		ctx.line_to(0, -R * 1.06)
		ctx.stroke()
		draw_circle_helper(0, -R * 1.12, R * 0.1, pink)
		ctx.fill_style(sh)
		for a in [0.4, 1.2, 2.0, 2.7]:
			draw_circle_helper(cos(a) * R * 0.5, sin(a) * R * 0.5 + R * 0.25, R * 0.05, sh)
	elif K == "pup":
		var fur = ("#fff" if (fl ) else "#d8b48a")
		var sh = ("#fff" if (fl ) else "#b48a5e")
		var purp = ("#fff" if (fl ) else "#9945ff")
		ctx.fill_style(fur)
		ctx.begin_path()
		ctx.ellipse(0, R * 0.12, R * 0.6, R * 0.55, 0, 0, 7)
		ctx.fill()
		ctx.fill_style(sh)
		ctx.begin_path()
		ctx.move_to(-R * 0.4, -R * 0.5)
		ctx.line_to(-R * 0.56, -R * 0.95)
		ctx.line_to(-R * 0.12, -R * 0.55)
		ctx.fill()
		ctx.begin_path()
		ctx.move_to(R * 0.4, -R * 0.5)
		ctx.line_to(R * 0.56, -R * 0.95)
		ctx.line_to(R * 0.12, -R * 0.55)
		ctx.fill()
		ctx.fill_style(fur)
		ctx.begin_path()
		ctx.arc(0, -R * 0.32, R * 0.44, 0, 7)
		ctx.fill()
		ctx.fill_style(("#fff" if (fl ) else "#f0dcc4"))
		ctx.begin_path()
		ctx.ellipse(0, -R * 0.16, R * 0.22, R * 0.18, 0, 0, 7)
		ctx.fill()
		ctx.fill_style("#150a0a")
		draw_circle_helper(0, -R * 0.26, R * 0.08, "#150a0a")
		draw_circle_helper(-R * 0.16, -R * 0.4, R * 0.06, "#150a0a")
		draw_circle_helper(R * 0.16, -R * 0.4, R * 0.06, "#150a0a")
		ctx.fill_style("#ff7a9c")
		ctx.begin_path()
		ctx.ellipse(0, -R * 0.04, R * 0.07, R * 0.14, 0, 0, 7)
		ctx.fill()
		ctx.fill_style(purp)
		ctx.fill_rect(-R * 0.4, R * 0.02, R * 0.8, R * 0.13)
		draw_circle_helper(0, R * 0.09, R * 0.09, "#14f195")
	elif K == "scammer":
		var skin = ("#fff" if (fl ) else "#c9a06a")
		var shirt = ("#fff" if (fl ) else "#e08a2a")
		var hs = "#222"
		ctx.fill_style(shirt)
		ctx.fill_rect(-R * 0.5, 0, R * 1.0, R * 0.72)
		ctx.fill_style(skin)
		ctx.begin_path()
		ctx.arc(0, -R * 0.4, R * 0.4, 0, TAU)
		ctx.fill()
		ctx.fill_style("#241810")
		ctx.begin_path()
		ctx.arc(0, -R * 0.52, R * 0.4, PI, TAU)
		ctx.fill()
		ctx.stroke_style(hs)
		ctx.line_width(R * 0.08)
		ctx.begin_path()
		ctx.arc(0, -R * 0.42, R * 0.44, PI * 1.12, PI * 1.88)
		ctx.stroke()
		draw_circle_helper(-R * 0.44, -R * 0.4, R * 0.1, hs)
		ctx.stroke_style(hs)
		ctx.line_width(R * 0.05)
		ctx.begin_path()
		ctx.move_to(-R * 0.44, -R * 0.34)
		ctx.quadratic_curve_to(-R * 0.24, -R * 0.16, -R * 0.1, -R * 0.22)
		ctx.stroke()
		draw_circle_helper(-R * 0.14, -R * 0.42, R * 0.05, "#150a0a")
		draw_circle_helper(R * 0.14, -R * 0.42, R * 0.05, "#150a0a")
		ctx.stroke_style("#7a2c2c")
		ctx.line_width(1.4)
		ctx.begin_path()
		ctx.move_to(-R * 0.12, -R * 0.24)
		ctx.line_to(R * 0.12, -R * 0.24)
		ctx.stroke()
		ctx.fill_style("#111")
		ctx.fill_rect(R * 0.42, R * 0.12, R * 0.15, R * 0.3)
	elif K == "voideye":
		# AKASHIC EYE — an ornate all-seeing GOLD eye in a rune frame; reads the Records
		# (deliberately distinct from Call of the Void's purple, tentacle-spoked servitors — no confusion)
		var gold = ("#fff" if (fl ) else "#e0b84a")
		var goldD = "#9a7a2a"
		var vio = ("#fff" if (fl ) else "#b48ce0")
		var dark = "#140e22"
		var rot = e.get("t", 0) * 0.02
		ctx.save()
		ctx.rotate(rot)
		ctx.stroke_style(_hexA(gold, 0.7))
		ctx.line_width(2)
		ctx.begin_path()
		ctx.arc(0, 0, R * 0.92, 0, 7)
		ctx.stroke()
		for i in range(int(0), int(12)):
			var a = (i / 12) * 6.283
			ctx.begin_path()
			ctx.move_to(cos(a) * R * 0.92, sin(a) * R * 0.92)
			ctx.line_to(cos(a) * R * 1.04, sin(a) * R * 1.04)
			ctx.stroke()
		ctx.restore()
		ctx.save()
		ctx.rotate(-rot * 0.6)
		ctx.stroke_style(_hexA(vio, 0.5))
		ctx.line_width(1.6)
		ctx.begin_path()
		for i in range(int(0), int(3) + 1):
			var a = (i / 3) * 6.283
			var x = cos(a) * R * 0.78
			var y = sin(a) * R * 0.78
			if i:
				ctx.line_to(x, y)
			else:
				ctx.move_to(x, y)
		ctx.close_path()
		ctx.stroke()
		ctx.restore()
		ctx.fill_style(gold)
		ctx.begin_path()
		ctx.move_to(-R * 0.72, 0)
		ctx.quadratic_curve_to(0, -R * 0.5, R * 0.72, 0)
		ctx.quadratic_curve_to(0, R * 0.5, -R * 0.72, 0)
		ctx.close_path()
		ctx.fill()
		ctx.stroke_style(goldD)
		ctx.line_width(2)
		ctx.stroke()
		ctx.fill_style(dark)
		ctx.begin_path()
		ctx.arc(0, 0, R * 0.34, 0, 7)
		ctx.fill()
		ctx.save()
		ctx.shadow_color(vio)
		ctx.shadow_blur(8)
		ctx.fill_style(vio)
		ctx.begin_path()
		ctx.ellipse(0, 0, R * 0.12, R * 0.28, 0, 0, 7)
		ctx.fill()
		ctx.restore()
		ctx.fill_style("#f4ecff")
		ctx.begin_path()
		ctx.ellipse(-R * 0.06, -R * 0.08, R * 0.04, R * 0.09, 0, 0, 7)
		ctx.fill()
		for i in range(int(0), int(3)):
			var a = rot * 2 + i * 2.1
			var rr = R * 0.2
			draw_circle_helper(cos(a) * rr, sin(a) * rr, R * 0.02, _hexA("#fff", 0.8))
	else:
		# goon — cabal suit
		var suit = ("#fff" if (fl ) else "#2a2f3a")
		var skin = ("#fff" if (fl ) else "#c9a06a")
		var tie = ("#fff" if (fl ) else "#ff5b3c")
		ctx.fill_style(suit)
		ctx.begin_path()
		ctx.move_to(-R * 0.55, R * 0.62)
		ctx.line_to(-R * 0.5, -R * 0.06)
		ctx.line_to(R * 0.5, -R * 0.06)
		ctx.line_to(R * 0.55, R * 0.62)
		ctx.close_path()
		ctx.fill()
		ctx.fill_style("#f2f4f8")
		ctx.begin_path()
		ctx.move_to(-R * 0.14, -R * 0.06)
		ctx.line_to(0, R * 0.5)
		ctx.line_to(R * 0.14, -R * 0.06)
		ctx.close_path()
		ctx.fill()
		ctx.fill_style(tie)
		ctx.begin_path()
		ctx.move_to(-R * 0.06, 0)
		ctx.line_to(R * 0.06, 0)
		ctx.line_to(R * 0.09, R * 0.4)
		ctx.line_to(0, R * 0.5)
		ctx.line_to(-R * 0.09, R * 0.4)
		ctx.close_path()
		ctx.fill()
		ctx.fill_style(skin)
		ctx.begin_path()
		ctx.arc(0, -R * 0.4, R * 0.38, 0, 7)
		ctx.fill()
		ctx.fill_style("#161616")
		ctx.begin_path()
		ctx.arc(0, -R * 0.54, R * 0.38, PI, TAU)
		ctx.fill()
		ctx.fill_style("#111")
		ctx.fill_rect(-R * 0.28, -R * 0.46, R * 0.56, R * 0.16)
		ctx.fill_style(tie)
		ctx.fill_rect(-R * 0.02, -R * 0.44, R * 0.04, R * 0.1)
	ctx.restore()
