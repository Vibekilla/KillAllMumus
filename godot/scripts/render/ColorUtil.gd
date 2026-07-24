extends RefCounted
class_name ColorUtil
## HTML _hexRgb / _hexA / _rgbHue + CSS color parse helpers.

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

static func hsl_to_color(h_deg: float, s: float, l: float, a: float = 1.0) -> Color:
	## Standard CSS HSL → RGB (s,l in 0..1, h in degrees)
	h_deg = fposmod(h_deg, 360.0)
	s = clampf(s, 0.0, 1.0)
	l = clampf(l, 0.0, 1.0)
	if s <= 0.00001:
		return Color(l, l, l, a)
	var q := (l * (1.0 + s)) if l < 0.5 else (l + s - l * s)
	var p := 2.0 * l - q
	var hk := h_deg / 360.0
	var tr := hk + 1.0 / 3.0
	var tg := hk
	var tb := hk - 1.0 / 3.0
	return Color(_hue_to_rgb(p, q, tr), _hue_to_rgb(p, q, tg), _hue_to_rgb(p, q, tb), a)

static func _hue_to_rgb(p: float, q: float, t: float) -> float:
	var tt := t
	if tt < 0.0:
		tt += 1.0
	if tt > 1.0:
		tt -= 1.0
	if tt < 1.0 / 6.0:
		return p + (q - p) * 6.0 * tt
	if tt < 0.5:
		return q
	if tt < 2.0 / 3.0:
		return p + (q - p) * (2.0 / 3.0 - tt) * 6.0
	return p

static func parse_css(c) -> Color:
	## HTML fillStyle / strokeStyle strings: #hex, rgb(), rgba(), hsl(), hsla()
	if c is Color:
		return c
	var s := str(c).strip_edges().replace("'", "").replace('"', '')
	if s.begins_with("rgba(") or s.begins_with("rgb("):
		var inner := s.trim_prefix("rgba(").trim_prefix("rgb(").trim_suffix(")")
		var parts := inner.split(",")
		if parts.size() >= 3:
			var r0 := float(parts[0].strip_edges())
			var g0 := float(parts[1].strip_edges())
			var b0 := float(parts[2].strip_edges())
			var a := float(parts[3].strip_edges()) if parts.size() > 3 else 1.0
			# 0–1 floats if all channels ≤ 1
			if r0 <= 1.0 and g0 <= 1.0 and b0 <= 1.0 and (r0 > 0.0 or g0 > 0.0 or b0 > 0.0 or a < 1.0):
				# Still treat pure 0,0,0,1 as 0–255 if written as 0,0,0 — prefer 0–255 when any > 1
				pass
			if r0 > 1.0 or g0 > 1.0 or b0 > 1.0:
				return Color(r0 / 255.0, g0 / 255.0, b0 / 255.0, a)
			# Heuristic: values like 255,120,190 always > 1; 0.5,0.2,0.1 are 0–1
			if r0 <= 1.0 and g0 <= 1.0 and b0 <= 1.0:
				return Color(r0, g0, b0, a)
			return Color(r0 / 255.0, g0 / 255.0, b0 / 255.0, a)
	if s.begins_with("hsla(") or s.begins_with("hsl("):
		var inner2 := s.trim_prefix("hsla(").trim_prefix("hsl(").trim_suffix(")")
		var parts2 := inner2.split(",")
		if parts2.size() >= 3:
			var h := float(parts2[0].strip_edges())
			var sat := float(parts2[1].strip_edges().replace("%", "")) / 100.0
			var lit := float(parts2[2].strip_edges().replace("%", "")) / 100.0
			var a2 := float(parts2[3].strip_edges()) if parts2.size() > 3 else 1.0
			# CSS HSL — NOT HSV (Color.from_hsv mis-reads L as V → neon spokes)
			return hsl_to_color(h, sat, lit, a2)
	if s.begins_with("#"):
		return Color.html(s)
	return Color.WHITE
