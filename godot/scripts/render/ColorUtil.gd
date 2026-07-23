extends RefCounted
## HTML _hexRgb / _hexA / _rgbHue helpers.

static func hex_rgb(h) -> Array:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return [(n >> 16) & 255, (n >> 8) & 255, n & 255]

static func hex_a(h, a: float) -> String:
	var c: Array = hex_rgb(h)
	return "rgba(%d,%d,%d,%s)" % [int(c[0]), int(c[1]), int(c[2]), str(a)]

static func rgb_hue(r: float, g: float, b: float) -> float:
	r /= 255.0
	g /= 255.0
	b /= 255.0
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var d := mx - mn
	if d < 0.0001:
		return 0.0
	var h := 0.0
	if mx == r:
		h = fmod(((g - b) / d), 6.0)
	elif mx == g:
		h = (b - r) / d + 2.0
	else:
		h = (r - g) / d + 4.0
	return h * 60.0
