extends RefCounted
## 1:1 port of HTML drawHoneyBadger

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


func _rnd(i, seed) -> float:
	var j = sin(float(i) * 12.9898 + float(seed) * 78.233) * 43758.5453
	return j - floorf(j)

func drawHoneyBadger(cx, cy, s) -> void:
	ctx.save()
	ctx.translate(float(cx), float(cy))
	ctx.scale(float(s), float(s))
	var fur = "#2a2721"
	var furD = "#16140e"
	var furM = "#3a352c"
	var cheek = "#3d362b"
	var hc = { "x": 0.0, "y": -22.0 }
	# ground shadow
	ctx.fill_style("rgba(0,0,0,0.22)")
	ctx.begin_path()
	ctx.ellipse(0, 44, 29, 7, 0, 0, 7)
	ctx.fill()
	# --- small body tucked below (keeps him a standing shopkeeper; head dominates like the ref) ---
	ctx.fill_style(furD)
	ctx.begin_path()
	ctx.ellipse(0, 26, 26, 20, 0, 0, 7)
	ctx.fill()
	# feet — separate subpaths (CanvasCompat fills one poly; multi-ellipse paths self-intersect)
	ctx.begin_path()
	ctx.ellipse(-13, 40, 8, 6, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(13, 40, 8, 6, 0, 0, 7)
	ctx.fill()
	ctx.stroke_style("rgba(0,0,0,0.4)")
	ctx.line_width(0.9)
	ctx.line_cap("round")
	ctx.begin_path()
	for px in [-16, -13, -10, 10, 13, 16]:
		ctx.move_to(px, 42)
		ctx.line_to(px, 38)
	ctx.stroke()
	# --- ears (dark, mostly buried in the crest) ---
	ctx.fill_style(furD)
	ctx.begin_path()
	ctx.arc(-31, -38, 9, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.arc(31, -38, 9, 0, 7)
	ctx.fill()
	# --- wide furry head + drooping jowls/cheeks ---
	ctx.fill_style(fur)
	ctx.begin_path()
	ctx.ellipse(hc.x, hc.y, 37, 33, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(-27, 3, 15, 19, 0.22, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(27, 3, 15, 19, -0.22, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(0, 7, 31, 24, 0, 0, 7)
	ctx.fill()
	ctx.fill_style(cheek)
	ctx.begin_path()
	ctx.ellipse(-21, 3, 11, 12, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(21, 3, 11, 12, 0, 0, 7)
	ctx.fill()
	# --- fuzzy fur tufts around the lower silhouette ---
	ctx.fill_style(fur)
	var tufts = [
		[-38, -6], [-40, 6], [-36, 17], [-28, 25], [-18, 29], [-6, 31],
		[6, 31], [18, 29], [28, 25], [36, 17], [40, 6], [38, -6],
	]
	for i in range(int(0), int(tufts.size() - 1)):
		var p = tufts[i]
		var nx = tufts[i + 1]
		var mx: float = (float(p[0]) + float(nx[0])) / 2.0
		var my: float = (float(p[1]) + float(nx[1])) / 2.0
		# push outward from origin for bulk (not along mid→origin which collapses near axes)
		var ox: float = mx * 0.12
		var oy: float = my * 0.12
		ctx.begin_path()
		ctx.move_to(p[0], p[1])
		ctx.line_to(mx + ox, my + oy)
		ctx.line_to(nx[0], nx[1])
		ctx.close_path()
		ctx.fill()
	# short fur strokes for texture on the face
	ctx.stroke_style(furD)
	ctx.line_width(0.8)
	ctx.begin_path()
	for i in range(int(0), int(11)):
		var a = ((-160 + i * 15) * PI) / 180
		var bx = hc.x + cos(a) * 30
		var by = hc.y + sin(a) * 27
		ctx.move_to(bx, by)
		ctx.line_to(bx + cos(a) * 5, by + sin(a) * 5)
	ctx.stroke()
	# --- soft, fluffy white fur crest: a DENSE fluffy cap; the "wild" look is fine short texture, not spikes ---
	var cc = { "x": 0, "y": -44 }
	var puffs = [
		[-31, -30, 9], [-33, -24, 7], [-26, -38, 11], [-18, -45, 12], [-9, -50, 13],
		[0, -52, 13], [9, -50, 13], [18, -45, 12], [26, -38, 11], [33, -24, 7], [-31, -30, 9],
	]
	ctx.fill_style("#c3c7d3")
	for m in puffs:
		ctx.begin_path()
		ctx.arc(m[0], m[1] + 3, m[2], 0, 7)
		ctx.fill()
	ctx.fill_style("#e9ebf1")
	for m in puffs:
		ctx.begin_path()
		ctx.arc(m[0], m[1], m[2], 0, 7)
		ctx.fill()
	ctx.fill_style("#f6f8fc")
	for m in puffs:
		ctx.begin_path()
		ctx.arc(m[0] - 1.5, m[1] - 1.8, m[2] * 0.6, 0, 7)
		ctx.fill()
	# fine short brushed strokes for a wild, hairy texture (kept SHORT so the cap stays soft, never spiky)
	ctx.line_cap("round")
	for i in range(int(0), int(52)):
		var jr = _rnd(i, 1)
		var jr2 = _rnd(i, 3)
		var ang = ((-180 + (i / 51) * 180) * PI) / 180
		var rr = 6 + jr * 19
		var bx = cc.x + cos(ang) * rr
		var by = cc.y + sin(ang) * rr * 0.6
		var ln = 2.5 + jr2 * 3
		ctx.stroke_style("rgba(150,156,172,0.5)" if jr < 0.32 else "rgba(255,255,255,0.72)")
		ctx.line_width(0.7)
		ctx.begin_path()
		ctx.move_to(bx, by)
		ctx.line_to(bx + cos(ang) * ln, by + sin(ang) * ln - 1)
		ctx.stroke()
	# just a few soft fuzzy tufts barely breaking the top edge (short + thin)
	for i in range(int(0), int(8)):
		var f = i / 7
		var ang = ((-152 + f * 124) * PI) / 180
		var jr = _rnd(i, 7)
		var bx = cc.x + cos(ang) * 16
		var by = cc.y + sin(ang) * 11 - 1
		var len = 2 + jr * 4
		ctx.stroke_style("rgba(236,238,244,0.85)")
		ctx.line_width(1.1)
		ctx.begin_path()
		ctx.move_to(bx, by)
		ctx.line_to(bx + cos(ang) * len, by + sin(ang) * len - 1.5)
		ctx.stroke()
	# --- face ---
	var ex = 10.5
	var ey = -19
	var erx = 8.2
	var ery = 9.6
	# soft reddish glow under the eyes (separate fills — one path per disc)
	ctx.fill_style("rgba(180,70,80,0.38)")
	ctx.begin_path()
	ctx.ellipse(-ex, ey + 6, 7, 5, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(ex, ey + 6, 7, 5, 0, 0, 7)
	ctx.fill()
	# eye sockets seat the big glossy eyes
	ctx.fill_style(furD)
	ctx.begin_path()
	ctx.ellipse(-ex, ey, erx + 1.4, ery + 1.4, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(ex, ey, erx + 1.4, ery + 1.4, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("#0c0b10")
	ctx.begin_path()
	ctx.ellipse(-ex, ey, erx, ery, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(ex, ey, erx, ery, 0, 0, 7)
	ctx.fill()
	# reddish inner-lower reflection
	ctx.fill_style("rgba(150,50,60,0.5)")
	ctx.begin_path()
	ctx.ellipse(-ex, ey + 3.6, erx * 0.6, ery * 0.42, 0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.ellipse(ex, ey + 3.6, erx * 0.6, ery * 0.42, 0, 0, 7)
	ctx.fill()
	# big catchlight + small sparkle + tiny top glint
	ctx.fill_style("#fff")
	ctx.begin_path()
	ctx.arc(-ex - 2.6, ey - 3.6, 3.0, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.arc(ex - 2.6, ey - 3.6, 3.0, 0, 7)
	ctx.fill()
	ctx.fill_style("rgba(255,255,255,0.9)")
	ctx.begin_path()
	ctx.arc(-ex + 3.4, ey + 3.8, 1.5, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.arc(ex + 3.4, ey + 3.8, 1.5, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.arc(-ex + 1.7, ey - 4.8, 0.9, 0, 7)
	ctx.fill()
	ctx.begin_path()
	ctx.arc(ex + 1.7, ey - 4.8, 0.9, 0, 7)
	ctx.fill()
	# blush (stronger on the right cheek, like the ref)
	ctx.fill_style("rgba(210,90,110,0.4)")
	ctx.begin_path()
	ctx.ellipse(-19, -8, 6, 3.8, 0, 0, 7)
	ctx.fill()
	ctx.fill_style("rgba(216,78,98,0.6)")
	ctx.begin_path()
	ctx.ellipse(19, -7, 7.5, 4.6, 0, 0, 7)
	ctx.fill()
	# little glossy pink nose, low between the eyes
	ctx.fill_style("#e56b86")
	ctx.begin_path()
	ctx.move_to(-4.4, -12)
	ctx.quadratic_curve_to(0, -9.5, 4.4, -12)
	ctx.quadratic_curve_to(4.4, -7, 0, -5)
	ctx.quadratic_curve_to(-4.4, -7, -4.4, -12)
	ctx.close_path()
	ctx.fill()
	ctx.fill_style("rgba(255,200,215,0.9)")
	ctx.begin_path()
	ctx.ellipse(-1.4, -10.6, 1.5, 1.1, 0, 0, 7)
	ctx.fill()
	# tiny dark mouth
	ctx.stroke_style("#1c1418")
	ctx.line_width(1.4)
	ctx.line_cap("round")
	ctx.begin_path()
	ctx.move_to(0, -5)
	ctx.line_to(0, -3)
	ctx.move_to(-3, -2.4)
	ctx.quadratic_curve_to(0, -1, 3, -2.4)
	ctx.stroke()
	ctx.restore()
