extends RefCounted
class_name CanvasCompat
## Canvas2D-compatible drawing API for 1:1 ports of HTML draw* code.
## Attach to a CanvasItem via bind(node); call begin_frame() before drawing; node.queue_redraw().

const _ColorUtil = preload("res://scripts/render/ColorUtil.gd")

## HTML CanvasGradient stand-in (linear / radial) with addColorStop.
class CanvasGradient:
	extends RefCounted
	var kind: String = "linear"  # linear | radial
	var x0: float = 0.0
	var y0: float = 0.0
	var x1: float = 0.0
	var y1: float = 0.0
	var r0: float = 0.0
	var r1: float = 1.0
	var stops: Array = []  # {t: float, c: Color}

	func addColorStop(offset, color) -> void:
		add_color_stop(offset, color)

	func add_color_stop(offset, color) -> void:
		var t = clampf(float(offset), 0.0, 1.0)
		# Nested classes cannot resolve outer class_name (CanvasCompat) at compile time
		# in Godot 4.3 — that broke the whole draw stack and WASM with OOB crashes.
		var col: Color = ColorUtil_parse(color)
		stops.append({"t": t, "c": col})
		stops.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))

	## Local parse so nested class has zero outer/class_name deps
	static func ColorUtil_parse(c) -> Color:
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
				if r0 > 1.0 or g0 > 1.0 or b0 > 1.0:
					return Color(r0 / 255.0, g0 / 255.0, b0 / 255.0, a)
				return Color(r0, g0, b0, a)
		if s.begins_with("hsla(") or s.begins_with("hsl("):
			var inner2 := s.trim_prefix("hsla(").trim_prefix("hsl(").trim_suffix(")")
			var parts2 := inner2.split(",")
			if parts2.size() >= 3:
				var h := float(parts2[0].strip_edges())
				var sat := float(parts2[1].strip_edges().replace("%", "")) / 100.0
				var lit := float(parts2[2].strip_edges().replace("%", "")) / 100.0
				var a2 := float(parts2[3].strip_edges()) if parts2.size() > 3 else 1.0
				# CSS HSL (not HSV) — inline so nested class has no outer deps
				h = fposmod(h, 360.0)
				sat = clampf(sat, 0.0, 1.0)
				lit = clampf(lit, 0.0, 1.0)
				if sat <= 0.00001:
					return Color(lit, lit, lit, a2)
				var q := (lit * (1.0 + sat)) if lit < 0.5 else (lit + sat - lit * sat)
				var p := 2.0 * lit - q
				var hk := h / 360.0
				var tr := hk + 1.0 / 3.0
				var tg := hk
				var tb := hk - 1.0 / 3.0
				return Color(_hsl_chan(p, q, tr), _hsl_chan(p, q, tg), _hsl_chan(p, q, tb), a2)
		if s.begins_with("#"):
			return Color.html(s)
		return Color.WHITE

	static func _hsl_chan(p: float, q: float, t: float) -> float:
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


	func sample(t: float) -> Color:
		if stops.is_empty():
			return Color.WHITE
		if stops.size() == 1:
			return stops[0]["c"]
		t = clampf(t, 0.0, 1.0)
		if t <= float(stops[0]["t"]):
			return stops[0]["c"]
		if t >= float(stops[stops.size() - 1]["t"]):
			return stops[stops.size() - 1]["c"]
		for i in range(1, stops.size()):
			var t0 = float(stops[i - 1]["t"])
			var t1 = float(stops[i]["t"])
			if t <= t1:
				var u = 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
				return (stops[i - 1]["c"] as Color).lerp(stops[i]["c"] as Color, u)
		return stops[stops.size() - 1]["c"]

	func first_color() -> Color:
		return stops[0]["c"] if stops.size() else Color.WHITE

	func mid_color() -> Color:
		return sample(0.5)

var node: CanvasItem
var _fill: Color = Color.WHITE
var _stroke: Color = Color.WHITE
var _fill_grad = null  # CanvasGradient or null
var _lw: float = 1.0
var _alpha: float = 1.0
var _font_size: int = 12
var _font_css: String = "12px sans-serif"
## Font cache — RegEx + FontBank lookup once per css string (FPS)
var _font_regex: RegEx = null
var _font_bank = null
var _cached_font: Font = null
var _cached_font_key: String = ""
var _align: String = "left"
var _path: PackedVector2Array = PackedVector2Array()
var _path_closed: bool = false
var _stack: Array = []
var _xform: Transform2D = Transform2D.IDENTITY
var _shadow_col: Color = Color(0,0,0,0)
var _shadow_blur: float = 0.0
## HTML globalCompositeOperation — lighter/screen boost alpha; multiply darkens
var _gco: String = "source-over"
## HTML clip region: {} = none; {kind:"rect"|"circle"|"poly", ...} in world (post-xform) space
var _clip: Dictionary = {}
## Last full-circle arc in world space (for high-quality circular clip of images)
var _last_full_arc: Dictionary = {}
## Last full ellipse (HTML arc 0..7) for native scaled-circle fill
var _last_full_ellipse: Dictionary = {}

func bind(n: CanvasItem) -> void:
	node = n

func begin_frame() -> void:
	_path = PackedVector2Array()
	_stack.clear()
	_xform = Transform2D.IDENTITY
	_alpha = 1.0
	_gco = "source-over"
	_clip = {}
	_last_full_arc = {}
	_last_full_ellipse = {}
	# Reset shadow — leaked gold boss-portrait shadows were neon-spoking ambience strokes
	_shadow_col = Color(0, 0, 0, 0)
	_shadow_blur = 0.0

func _c(col: Color) -> Color:
	var c := col
	c.a *= _alpha
	# Approximate Canvas GCO on Godot CanvasItem (no true blend modes mid-draw)
	match _gco:
		"lighter", "screen", "plus-lighter":
			# Additive-ish on dark bg. Never floor alpha — a +0.08 floor turned
			# HTML faint map-bleed (α≈0.03–0.09) into opaque purple mud.
			if c.a < 0.15:
				c.a = minf(1.0, c.a * 1.12)
				c.r = minf(1.0, c.r * 1.04)
				c.g = minf(1.0, c.g * 1.04)
				c.b = minf(1.0, c.b * 1.04)
			else:
				c.a = minf(1.0, c.a * 1.22 + 0.02)
				c.r = minf(1.0, c.r * 1.06 + 0.02)
				c.g = minf(1.0, c.g * 1.06 + 0.02)
				c.b = minf(1.0, c.b * 1.06 + 0.02)
		"multiply", "darken":
			c.a = minf(1.0, c.a * 0.85)
			c.r *= 0.92
			c.g *= 0.92
			c.b *= 0.92
		"destination-out", "xor":
			c.a *= 0.35
		_:
			pass
	return c

static func static_parse_color(c) -> Color:
	return _ColorUtil.parse_css(c)

func _parse_color(c) -> Color:
	return _ColorUtil.parse_css(c)

func fill_style(c) -> void:
	## Accept solid color OR CanvasGradient (HTML fillStyle = gradient)
	if c is CanvasGradient:
		_fill_grad = c
		_fill = c.mid_color()
		return
	if c is Dictionary and (c.get("type") == "linear" or c.get("type") == "radial"):
		# Legacy dict form → wrap as CanvasGradient
		var g = CanvasGradient.new()
		g.kind = str(c.get("type", "linear"))
		g.x0 = float(c.get("x0", 0))
		g.y0 = float(c.get("y0", 0))
		g.x1 = float(c.get("x1", 0))
		g.y1 = float(c.get("y1", 0))
		g.r0 = float(c.get("r0", 0))
		g.r1 = float(c.get("r1", 1))
		for st in c.get("stops", []):
			if typeof(st) == TYPE_DICTIONARY:
				g.add_color_stop(st.get("t", 0), st.get("c", "#fff"))
		_fill_grad = g
		_fill = g.mid_color()
		return
	_fill_grad = null
	_fill = _parse_color(c)

func stroke_style(c) -> void:
	## Solid stroke; gradients sample mid color (HTML strokeStyle with gradient is rare)
	if c is CanvasGradient:
		_stroke = c.mid_color()
		return
	_stroke = _parse_color(c)

func line_width(w: float) -> void:
	_lw = w

func _effective_lw() -> float:
	## HTML Canvas2D: lineWidth is in user space and scales with the current CTM.
	## Cap the scale factor so large menu previews (×4.7) keep lid weight readable without
	## turning smile eyes into heavy “glasses” frames.
	var sc := _xform.get_scale()
	var m := (absf(sc.x) + absf(sc.y)) * 0.5
	if m < 0.001:
		m = 1.0
	# Soft compress: full scale up to 1.35×, then stronger sqrt dampen; hard cap ~2.1×
	if m > 1.35:
		m = 1.35 + sqrt(m - 1.35) * 0.55
	m = minf(m, 2.1)
	return maxf(0.5, _lw * m)

func global_alpha(a: float) -> void:
	_alpha = a

func get_alpha() -> float:
	return _alpha

func shadow_color(c) -> void:
	## HTML shadowColor — #hex or rgba()/rgb() via ColorUtil
	if c is Color:
		_shadow_col = c
	else:
		_shadow_col = _parse_color(c)

func shadow_blur(b: float) -> void:
	_shadow_blur = b

func font(f) -> void:
	# e.g. 'bold 12px monospace' / '900 18px "Trebuchet MS"' — HTML ctx.font
	var s := str(f)
	if s == _font_css:
		return
	_font_css = s
	_cached_font_key = ""
	if _font_regex == null:
		_font_regex = RegEx.new()
		_font_regex.compile("(\\d+)px")
	var r := _font_regex.search(s)
	if r:
		_font_size = int(r.get_string(1))

func _active_font() -> Font:
	## Cached FontBank pick — avoid get_node every fill_text
	var key := "%s|%d" % [_font_css, _font_size]
	if _cached_font != null and key == _cached_font_key:
		return _cached_font
	if _font_bank == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			_font_bank = tree.root.get_node_or_null("/root/FontBank")
	var f: Font = null
	if _font_bank != null and _font_bank.has_method("font_for"):
		f = _font_bank.font_for(_font_css)
	elif _font_bank != null and _font_bank.get("ui") != null:
		f = _font_bank.ui as Font
	if f == null:
		f = ThemeDB.fallback_font
	_cached_font = f
	_cached_font_key = key
	return f

func text_align(a) -> void:
	_align = str(a).replace("'","").replace('"','')

func text_baseline(_b) -> void:
	pass

func line_join(_j) -> void:
	pass

func line_cap(_c) -> void:
	pass

func global_composite_operation(op) -> void:
	## HTML globalCompositeOperation — stored; applied in _c() color path
	_gco = str(op if op != null else "source-over").to_lower()

func set_line_dash(_segments = []) -> void:
	# CanvasItem polyline dash not fully supported — no-op (solid stroke)
	pass

func save() -> void:
	_stack.append({
		"fill": _fill, "stroke": _stroke, "lw": _lw, "alpha": _alpha,
		"xform": _xform, "font": _font_size, "align": _align, "fill_grad": _fill_grad,
		"gco": _gco, "clip": _clip.duplicate(true),
	})

func restore() -> void:
	if _stack.is_empty():
		return
	var s: Dictionary = _stack.pop_back()
	_fill = s.fill
	_stroke = s.stroke
	_lw = s.lw
	_alpha = s.alpha
	_xform = s.xform
	_font_size = s.font
	_align = s.align
	_fill_grad = s.get("fill_grad", null)
	_gco = str(s.get("gco", "source-over"))
	_clip = s.get("clip", {})
	if _clip == null:
		_clip = {}

func translate(x: float, y: float) -> void:
	_xform = _xform * Transform2D(0, Vector2(x, y))

func rotate(a: float) -> void:
	_xform = _xform * Transform2D(a, Vector2.ZERO)

func scale(x: float, y: float) -> void:
	var t := Transform2D.IDENTITY
	t.x *= x
	t.y *= y
	_xform = _xform * t

func set_transform(a: float, b: float, c: float, d: float, e: float, f: float) -> void:
	_xform = Transform2D(Vector2(a, b), Vector2(c, d), Vector2(e, f))

func begin_path() -> void:
	_path = PackedVector2Array()
	_path_closed = false
	_last_full_arc = {}
	_last_full_ellipse = {}

func close_path() -> void:
	_path_closed = true

func move_to(x: float, y: float) -> void:
	_path.append(_xform * Vector2(x, y))

func line_to(x: float, y: float) -> void:
	_path.append(_xform * Vector2(x, y))

func arc(x: float, y: float, r: float, a0: float, a1: float, ccw: bool = false) -> void:
	# approximate arc as polyline; HTML often uses 0..7 ≈ full circle
	var a0f := float(a0)
	var a1f := float(a1)
	if a1f >= 6.0 and is_equal_approx(a0f, 0.0):
		a1f = TAU
	var steps := 20
	var da := a1f - a0f
	if ccw and da > 0.0:
		da -= TAU
	elif not ccw and da < 0.0:
		da += TAU
	# Track full circles for clip() → circle kind (portrait bust, title peephole)
	if absf(da) >= TAU * 0.92:
		var c_world := _xform * Vector2(x, y)
		var edge := _xform * (Vector2(x, y) + Vector2(r, 0))
		_last_full_arc = {"c": c_world, "r": c_world.distance_to(edge)}
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang := a0f + da * t
		var p := _xform * (Vector2(x, y) + Vector2(cos(ang), sin(ang)) * r)
		_path.append(p)

func quadratic_curve_to(cpx: float, cpy: float, x: float, y: float) -> void:
	var p0 := _path[_path.size()-1] if _path.size() else _xform * Vector2.ZERO
	var p1 := _xform * Vector2(cpx, cpy)
	var p2 := _xform * Vector2(x, y)
	for i in range(1, 9):
		var t := float(i) / 8.0
		var u := 1.0 - t
		_path.append(u*u*p0 + 2*u*t*p1 + t*t*p2)

func bezier_curve_to(cp1x, cp1y, cp2x, cp2y, x, y) -> void:
	var p0 := _path[_path.size()-1] if _path.size() else _xform * Vector2.ZERO
	var p1 := _xform * Vector2(cp1x, cp1y)
	var p2 := _xform * Vector2(cp2x, cp2y)
	var p3 := _xform * Vector2(x, y)
	for i in range(1, 13):
		var t := float(i) / 12.0
		var u := 1.0 - t
		_path.append(u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3)

func ellipse(x, y, rx, ry, rot, a0, a1, ccw: bool = false) -> void:
	var a0f: float = float(a0)
	var a1f: float = float(a1)
	# HTML often uses 0..7 as a full-circle stand-in for 2π
	if a1f >= 6.0 and is_equal_approx(a0f, 0.0):
		a1f = TAU
	var rxf: float = float(rx)
	var ryf: float = float(ry)
	var rotf: float = float(rot)
	# Track full ellipses for fill() → scaled draw_circle (same solid disc look, no ear-clip)
	var da := a1f - a0f
	if ccw and da > 0.0:
		da -= TAU
	elif not ccw and da < 0.0:
		da += TAU
	if absf(da) >= TAU * 0.92 and rxf > 0.05 and ryf > 0.05:
		var c_local := Vector2(float(x), float(y))
		var c_world := _xform * c_local
		# average semi-axis in world space (uniform scale approx)
		var ex := _xform * (c_local + Vector2(rxf, 0).rotated(rotf))
		var ey := _xform * (c_local + Vector2(0, ryf).rotated(rotf))
		_last_full_ellipse = {
			"c": c_world,
			"rx": c_world.distance_to(ex),
			"ry": c_world.distance_to(ey),
			"rot": rotf + _xform.get_rotation(),
			# local (pre-xform) for gradient sampling (Bobina iris, etc.)
			"c_local": c_local,
			"rx_local": rxf,
			"ry_local": ryf,
			"rot_local": rotf,
		}
	var steps := 28
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang: float = a0f + da * t
		var lp := Vector2(cos(ang) * rxf, sin(ang) * ryf).rotated(rotf) + Vector2(float(x), float(y))
		_path.append(_xform * lp)

func round_rect(x, y, w, h, r) -> void:
	## HTML Path2D.roundRect — true corner arcs (not chamfered corners)
	var rf := minf(float(r), minf(float(w), float(h)) * 0.5)
	var xf := float(x)
	var yf := float(y)
	var wf := float(w)
	var hf := float(h)
	if rf <= 0.05:
		rect(xf, yf, wf, hf)
		return
	begin_path()
	move_to(xf + rf, yf)
	line_to(xf + wf - rf, yf)
	_arc_corner(xf + wf - rf, yf + rf, rf, -PI / 2.0, 0.0)
	line_to(xf + wf, yf + hf - rf)
	_arc_corner(xf + wf - rf, yf + hf - rf, rf, 0.0, PI / 2.0)
	line_to(xf + rf, yf + hf)
	_arc_corner(xf + rf, yf + hf - rf, rf, PI / 2.0, PI)
	line_to(xf, yf + rf)
	_arc_corner(xf + rf, yf + rf, rf, PI, PI * 1.5)
	close_path()

func _arc_corner(cx: float, cy: float, r: float, a0: float, a1: float) -> void:
	var steps := 8
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var ang := a0 + (a1 - a0) * t
		_path.append(_xform * (Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * r))

func rect(x, y, w, h) -> void:
	move_to(x,y); line_to(x+w,y); line_to(x+w,y+h); line_to(x,y+h); close_path()

func fill() -> void:
	## HTML CanvasRenderingContext2D.fill — evenodd not used; nonzero fill via triangulation.
	## Full-circle paths (HTML arc 0..2π / 0..7) use native draw_circle — same solid disc pixels,
	## without ear-clip thrash (performance only; not a visual stand-in for complex shapes).
	if node == null or _path.size() < 3:
		return
	var pts := _closed_path_pts(_path)
	if pts.size() < 3:
		return
	# Prefer tracked full-circle arc before clip/ear-clip (hot path for bullets/orbs)
	if not _last_full_arc.is_empty() and _fill_grad == null and _is_path_full_circle(pts):
		var c: Vector2 = _last_full_arc.get("c", Vector2.ZERO)
		var r: float = float(_last_full_arc.get("r", 0.0))
		if r > 0.05 and _point_in_clip(c):
			var col_c := _c(_fill)
			_draw_shadow_circle(c, r, col_c)
			node.draw_circle(c, r, col_c)
			return
	# Full ellipse (portal / honey badger body / Bobina eyes) — solid or gradient
	if not _last_full_ellipse.is_empty() and pts.size() >= 16:
		var ec: Vector2 = _last_full_ellipse.get("c", Vector2.ZERO)
		var erx: float = float(_last_full_ellipse.get("rx", 0.0))
		var ery: float = float(_last_full_ellipse.get("ry", 0.0))
		var erot: float = float(_last_full_ellipse.get("rot", 0.0))
		if erx > 0.05 and ery > 0.05 and _point_in_clip(ec):
			if _fill_grad == null:
				var col_e := _c(_fill)
				# CanvasItem local xform: position, rotation, scale (ellipse = scaled unit circle)
				node.draw_set_transform(ec, erot, Vector2(erx, ery))
				node.draw_circle(Vector2.ZERO, 1.0, col_e)
				node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return
			# Gradient ellipse (HTML smile-eye amber iris) — banded local sampling
			_fill_ellipse_gradient(_last_full_ellipse)
			return
	pts = _clip_poly(pts)
	if pts.size() < 3:
		return
	# Drop duplicate closing vertex for triangulate_polygon
	var poly := pts
	if poly.size() >= 2 and poly[0].distance_to(poly[poly.size() - 1]) < 0.05:
		poly = poly.slice(0, poly.size() - 1)
	if poly.size() < 3:
		return
	if _fill_grad != null:
		# Gradient on arbitrary path: sample per-triangle centroid (better than solid mid)
		_fill_triangulated_gradient(poly)
		return
	var col := _c(_fill)
	_draw_shadow_poly(poly, col)
	_fill_triangulated(poly, col)

func _fill_ellipse_gradient(info: Dictionary) -> void:
	## Banded fill for ellipse with CanvasGradient (Bobina iris, auras).
	## Builds bands in local (pre-xform) ellipse space, samples gradient there, draws world polys.
	if node == null or _fill_grad == null:
		return
	var c_local: Vector2 = info.get("c_local", Vector2.ZERO)
	var rxf: float = float(info.get("rx_local", info.get("rx", 0.0)))
	var ryf: float = float(info.get("ry_local", info.get("ry", 0.0)))
	var rotf: float = float(info.get("rot_local", 0.0))
	if rxf < 0.05 or ryf < 0.05:
		return
	var g: CanvasGradient = _fill_grad
	var axis := Vector2(g.x1 - g.x0, g.y1 - g.y0)
	var vertical := absf(axis.x) < absf(axis.y) * 0.5 or absf(axis.x) < 0.001
	# Tiny irises (Bobina smile eyes at any preview scale): layered solid discs along the
	# gradient axis. Banded quads under large CTM scale read as dark “glasses” rims;
	# layered circles match the HTML amber look more reliably.
	if rxf <= 4.0 and ryf <= 4.0 and vertical:
		var n_layers := 10
		var dir_axis := axis.normalized() if axis.length_squared() > 0.0001 else Vector2(0, 1)
		for i in range(n_layers):
			var t := float(i) / float(n_layers - 1)
			# shrink slightly toward gradient end so gold bottom dominates (HTML smile iris)
			var shrink := 1.0 - t * 0.22
			var shift := dir_axis * (t * ryf * 0.55)
			var col := _c(g.sample(t))
			var ec: Vector2 = _xform * (c_local + shift)
			var ex: Vector2 = _xform * (c_local + shift + Vector2(rxf * shrink, 0).rotated(rotf))
			var ey: Vector2 = _xform * (c_local + shift + Vector2(0, ryf * shrink).rotated(rotf))
			var wrx := ec.distance_to(ex)
			var wry := ec.distance_to(ey)
			if wrx < 0.2 or wry < 0.2:
				continue
			node.draw_set_transform(ec, rotf + _xform.get_rotation(), Vector2(wrx, wry))
			node.draw_circle(Vector2.ZERO, 1.0, col)
			node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var bands := 16
	var cs := cos(rotf)
	var sn := sin(rotf)
	if vertical:
		for i in range(bands):
			var t0 := float(i) / float(bands)
			var t1 := float(i + 1) / float(bands)
			var y0 := -1.0 + 2.0 * t0
			var y1 := -1.0 + 2.0 * t1
			var ym := (y0 + y1) * 0.5
			var hw := sqrt(maxf(0.0, 1.0 - ym * ym))
			if hw < 0.02:
				continue
			var lx_mid := 0.0
			var ly_mid := ym * ryf
			var local := c_local + Vector2(lx_mid * cs - ly_mid * sn, lx_mid * sn + ly_mid * cs)
			var col := _c(_sample_grad_at_local(local))
			var corners_u := [
				Vector2(-hw, y0), Vector2(hw, y0), Vector2(hw, y1), Vector2(-hw, y1)
			]
			var wpts := PackedVector2Array()
			for p in corners_u:
				var lx: float = float(p.x) * rxf
				var ly: float = float(p.y) * ryf
				var rx: float = lx * cs - ly * sn
				var ry: float = lx * sn + ly * cs
				wpts.append(_xform * (c_local + Vector2(rx, ry)))
			if wpts.size() >= 3:
				node.draw_colored_polygon(PackedVector2Array([wpts[0], wpts[1], wpts[2]]), col)
				if wpts.size() >= 4:
					node.draw_colored_polygon(PackedVector2Array([wpts[0], wpts[2], wpts[3]]), col)
	else:
		for i in range(bands):
			var t0 := float(i) / float(bands)
			var t1 := float(i + 1) / float(bands)
			var x0 := -1.0 + 2.0 * t0
			var x1 := -1.0 + 2.0 * t1
			var xm := (x0 + x1) * 0.5
			var hh := sqrt(maxf(0.0, 1.0 - xm * xm))
			if hh < 0.02:
				continue
			var lx_mid := xm * rxf
			var ly_mid := 0.0
			var local := c_local + Vector2(lx_mid * cs - ly_mid * sn, lx_mid * sn + ly_mid * cs)
			var col := _c(_sample_grad_at_local(local))
			var corners_u := [
				Vector2(x0, -hh), Vector2(x1, -hh), Vector2(x1, hh), Vector2(x0, hh)
			]
			var wpts := PackedVector2Array()
			for p in corners_u:
				var lx: float = float(p.x) * rxf
				var ly: float = float(p.y) * ryf
				var rx: float = lx * cs - ly * sn
				var ry: float = lx * sn + ly * cs
				wpts.append(_xform * (c_local + Vector2(rx, ry)))
			if wpts.size() >= 3:
				node.draw_colored_polygon(PackedVector2Array([wpts[0], wpts[1], wpts[2]]), col)
				if wpts.size() >= 4:
					node.draw_colored_polygon(PackedVector2Array([wpts[0], wpts[2], wpts[3]]), col)

func _fill_triangulated_gradient(poly: PackedVector2Array) -> void:
	## Fan triangles, each colored by gradient at centroid (local space).
	if node == null or poly.size() < 3:
		return
	var inv := _xform.affine_inverse()
	var c0: Vector2 = poly[0]
	for si in range(1, poly.size() - 1):
		var a: Vector2 = c0
		var b: Vector2 = poly[si]
		var c: Vector2 = poly[si + 1]
		# Skip degenerate / collinear fans (Godot triangulation errors)
		var area2 := absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y))
		if area2 < 0.05:
			continue
		var centroid := (a + b + c) / 3.0
		var local := inv * centroid
		var col := _c(_sample_grad_at_local(local))
		node.draw_colored_polygon(PackedVector2Array([a, b, c]), col)

func _is_path_full_circle(pts: PackedVector2Array) -> bool:
	## True when path is a closed disc (many points near constant radius from center).
	if pts.size() < 12:
		return false
	if _last_full_arc.is_empty():
		return false
	var c: Vector2 = _last_full_arc.get("c", Vector2.ZERO)
	var r: float = float(_last_full_arc.get("r", 0.0))
	if r < 0.05:
		return false
	var tol := maxf(1.5, r * 0.12)
	var ok_n := 0
	var n := pts.size()
	# ignore possible closing duplicate
	if n >= 2 and pts[0].distance_to(pts[n - 1]) < 0.05:
		n -= 1
	for i in range(n):
		if absf(pts[i].distance_to(c) - r) <= tol:
			ok_n += 1
	return ok_n >= int(float(n) * 0.85)

func _point_in_clip(p: Vector2) -> bool:
	if _clip.is_empty():
		return true
	match str(_clip.get("kind", "")):
		"rect":
			var rr: Rect2 = _clip.get("rect", Rect2())
			return rr.has_point(p)
		"circle":
			return p.distance_to(_clip.get("c", Vector2.ZERO)) <= float(_clip.get("r", 0.0)) + 0.5
		_:
			return true

func _draw_shadow_circle(c: Vector2, r: float, col: Color) -> void:
	if _shadow_blur <= 0.1 or _shadow_col.a <= 0.01:
		return
	var sc := _shadow_col
	sc.a *= _alpha * 0.35
	var o := maxf(1.0, _shadow_blur * 0.35)
	node.draw_circle(c + Vector2(o * 0.3, o * 0.3), r + o * 0.15, sc)

func _closed_path_pts(src: PackedVector2Array) -> PackedVector2Array:
	var pts := _dedupe_path(src)
	if pts.size() >= 3 and pts[0].distance_to(pts[pts.size() - 1]) > 0.05:
		pts.append(pts[0])
	return pts

func _fill_triangulated(poly: PackedVector2Array, col: Color) -> void:
	## HTML Canvas fill (nonzero) — always emit triangles only.
	## Never pass n>3 to draw_colored_polygon (Godot errors on concave/self-intersect).
	if poly.size() == 3:
		_draw_tri(poly[0], poly[1], poly[2], col)
		return
	_fill_ear_clip(poly, col)

func _draw_tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var fill_col := col
	if _fill_grad != null:
		fill_col = _c(_sample_grad_at_world((a + b + c) / 3.0))
	# Skip degenerate / collinear (Godot draw_colored_polygon errors: "Invalid polygon data")
	var cross_z := (b - a).cross(c - a)
	if absf(cross_z) < 0.25:
		return
	if a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c):
		return
	node.draw_colored_polygon(PackedVector2Array([a, b, c]), fill_col)

func _is_convex(poly: PackedVector2Array) -> bool:
	var n := poly.size()
	if n < 3:
		return false
	var sign := 0.0
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var c: Vector2 = poly[(i + 2) % n]
		var cr := (b - a).cross(c - b)
		if absf(cr) < 1e-8:
			continue
		if sign == 0.0:
			sign = signf(cr)
		elif signf(cr) != sign:
			return false
	return true

func _poly_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	var n := poly.size()
	for i in range(n):
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

func _point_in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var dot00 := v0.dot(v0)
	var dot01 := v0.dot(v1)
	var dot02 := v0.dot(v2)
	var dot11 := v1.dot(v1)
	var dot12 := v1.dot(v2)
	var inv := 1.0 / (dot00 * dot11 - dot01 * dot01)
	var u := (dot11 * dot02 - dot01 * dot12) * inv
	var v := (dot00 * dot12 - dot01 * dot02) * inv
	return u >= -1e-6 and v >= -1e-6 and (u + v) <= 1.0 + 1e-6

func _fill_ear_clip(poly: PackedVector2Array, col: Color) -> void:
	## Classic ear clipping (HTML-equivalent solid fill for simple polygons)
	var pts: Array = []
	for p in poly:
		pts.append(p)
	# Ensure CCW for consistent ear test
	if _poly_area(poly) < 0.0:
		pts.reverse()
	var guard := 0
	var max_iters := pts.size() * pts.size() + 8
	while pts.size() >= 3 and guard < max_iters:
		guard += 1
		if pts.size() == 3:
			_draw_tri(pts[0], pts[1], pts[2], col)
			break
		var n := pts.size()
		var clipped := false
		for i in range(n):
			var i0 := (i - 1 + n) % n
			var i1 := i
			var i2 := (i + 1) % n
			var a: Vector2 = pts[i0]
			var b: Vector2 = pts[i1]
			var c: Vector2 = pts[i2]
			# Ear if convex (left turn for CCW)
			if (b - a).cross(c - b) <= 1e-8:
				continue
			var has_pt := false
			for j in range(n):
				if j == i0 or j == i1 or j == i2:
					continue
				if _point_in_tri(pts[j], a, b, c):
					has_pt = true
					break
			if has_pt:
				continue
			_draw_tri(a, b, c, col)
			pts.remove_at(i1)
			clipped = true
			break
		if not clipped:
			# Self-intersecting path from polyline sampling — drop one vertex and continue
			if pts.size() > 3:
				pts.remove_at(1)
			else:
				break

func _sample_grad_at_world(world: Vector2) -> Color:
	## Inverse of current xform so gradient stops match HTML pre-transform space
	var local := _xform.affine_inverse() * world
	return _sample_grad_at_local(local)

func _draw_shadow_poly(poly: PackedVector2Array, _col: Color) -> void:
	## HTML shadowColor + shadowBlur under fill (offset solid, no Geometry2D)
	if _shadow_blur <= 0.05 or _shadow_col.a <= 0.001:
		return
	var sc := _shadow_col
	sc.a *= _alpha * 0.35
	var o := maxf(0.8, _shadow_blur * 0.18)
	var shifted := PackedVector2Array()
	for p in poly:
		shifted.append(p + Vector2(o * 0.2, o * 0.45))
	if shifted.size() < 3:
		return
	# triangles only (avoid Godot concave polygon error spam)
	var a0: Vector2 = shifted[0]
	for i in range(1, shifted.size() - 1):
		if absf((shifted[i] - a0).cross(shifted[i + 1] - a0)) > 0.02:
			node.draw_colored_polygon(PackedVector2Array([a0, shifted[i], shifted[i + 1]]), sc)

func _dedupe_path(src: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in src:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.001:
			out.append(p)
	return out

func stroke() -> void:
	if node == null or _path.size() < 2:
		return
	var pts := _path
	if not _clip.is_empty():
		var ab := _clip_aabb()
		if ab.size.x > 0.0 and ab.size.y > 0.0:
			var kept := PackedVector2Array()
			for p in pts:
				if ab.grow(maxf(2.0, _lw)).has_point(p):
					kept.append(p)
			if kept.size() < 2:
				return
			pts = kept
	var col := _c(_stroke)
	var elw := _effective_lw()
	if _shadow_blur > 0.05 and _shadow_col.a > 0.001:
		var sc := _shadow_col
		sc.a *= _alpha * 0.45
		node.draw_polyline(pts, sc, elw + _shadow_blur * 0.25, true)
	node.draw_polyline(pts, col, elw, true)

func fill_rect(x, y, w, h) -> void:
	if node == null:
		return
	if _fill_grad != null:
		_fill_rect_gradient(float(x), float(y), float(w), float(h))
		return
	var p0 := _xform * Vector2(x, y)
	var p1 := _xform * Vector2(x + w, y + h)
	var r := Rect2(p0, p1 - p0).abs()
	r = _clip_rect(r)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	node.draw_rect(r, _c(_fill), true)

func _sample_grad_at_local(local: Vector2) -> Color:
	## Sample gradient using local (pre-xform) coords matching HTML canvas space.
	if _fill_grad == null:
		return _fill
	var g: CanvasGradient = _fill_grad
	if g.kind == "radial":
		var d0 := Vector2(g.x0, g.y0)
		var dist := local.distance_to(d0)
		var span := maxf(0.0001, g.r1 - g.r0)
		return g.sample((dist - g.r0) / span)
	# linear
	var a := Vector2(g.x0, g.y0)
	var b := Vector2(g.x1, g.y1)
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return g.first_color()
	var t := clampf((local - a).dot(ab) / len2, 0.0, 1.0)
	return g.sample(t)

func _fill_rect_gradient(x: float, y: float, w: float, h: float) -> void:
	## Banded linear / concentric radial fill approximating CanvasGradient.
	var g: CanvasGradient = _fill_grad
	if g.kind == "radial":
		# Concentric ellipse bands from outer → inner
		var cx = x + w * 0.5
		var cy = y + h * 0.5
		var max_r = maxf(w, h) * 0.5
		var bands = 24
		for i in range(bands, 0, -1):
			var t = float(i) / float(bands)
			var rr = max_r * t
			var col = _c(g.sample(t))
			var p = _xform * Vector2(cx, cy)
			# Approximate circle as rect cascade is coarse; use polygon
			var pts = PackedVector2Array()
			var segs = 20
			for s in range(segs):
				var ang = float(s) / float(segs) * TAU
				pts.append(_xform * Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr * (h / maxf(w, 0.001))))
			if pts.size() >= 3:
				# Fan triangles only — draw_colored_polygon(n>3) can fail after non-uniform xform
				var c0: Vector2 = pts[0]
				for si in range(1, pts.size() - 1):
					node.draw_colored_polygon(PackedVector2Array([c0, pts[si], pts[si + 1]]), col)
		return
	# Linear: slice along gradient axis into bands
	var bands2 = 32
	var axis = Vector2(g.x1 - g.x0, g.y1 - g.y0)
	var vertical = absf(axis.x) < absf(axis.y) * 0.35
	if vertical or absf(axis.x) < 0.001:
		for i in range(bands2):
			var t0 = float(i) / float(bands2)
			var t1 = float(i + 1) / float(bands2)
			var yy = y + h * t0
			var hh = h * (t1 - t0) + 0.5
			var col = _c(g.sample((t0 + t1) * 0.5))
			var p = _xform * Vector2(x, yy)
			node.draw_rect(Rect2(p, Vector2(w, hh)), col, true)
	else:
		for i in range(bands2):
			var t0b = float(i) / float(bands2)
			var t1b = float(i + 1) / float(bands2)
			var xx = x + w * t0b
			var ww = w * (t1b - t0b) + 0.5
			var colb = _c(g.sample((t0b + t1b) * 0.5))
			var pb = _xform * Vector2(xx, y)
			node.draw_rect(Rect2(pb, Vector2(ww, h)), colb, true)

func stroke_rect(x, y, w, h) -> void:
	if node == null:
		return
	var p0 := _xform * Vector2(x, y)
	var p1 := _xform * Vector2(x + w, y + h)
	var r := Rect2(p0, p1 - p0).abs()
	r = _clip_rect(r)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	node.draw_rect(r, _c(_stroke), false, _lw)

func fill_text(text, x, y) -> void:
	if node == null:
		return
	var f := _active_font()
	if f == null:
		return
	var p := _xform * Vector2(x, y)
	var sz := _font_size
	var w := f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if _align == "center":
		p.x -= w * 0.5
	elif _align == "right":
		p.x -= w
	# Canvas text baseline ~alphabetic: Godot draws from top-left of glyphs
	p.y -= sz * 0.15
	if _shadow_blur > 0.05 and _shadow_col.a > 0.001:
		var sc := _shadow_col
		sc.a *= _alpha
		node.draw_string(f, p + Vector2(0, maxf(1.0, _shadow_blur * 0.15)), str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, sc)
	node.draw_string(f, p, str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, _c(_fill))

func stroke_text(text, x, y) -> void:
	if node == null:
		return
	var f := _active_font()
	if f == null:
		return
	var p := _xform * Vector2(x, y)
	var sz := _font_size
	var w := f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if _align == "center":
		p.x -= w * 0.5
	elif _align == "right":
		p.x -= w
	p.y -= sz * 0.15
	var col := _c(_stroke)
	# HTML strokeText — outline via offset fills (4-cardinal + diagonals only when thick)
	var o := maxf(1.0, _lw * 0.35)
	var offs: Array = [Vector2(-o, 0), Vector2(o, 0), Vector2(0, -o), Vector2(0, o)]
	if _lw >= 3.0:
		offs.append_array([Vector2(-o, -o), Vector2(o, -o), Vector2(-o, o), Vector2(o, o)])
	for d in offs:
		node.draw_string(f, p + d, str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func clip() -> void:
	## HTML ctx.clip() — intersect current path with active clip region.
	var next := _path_to_clip(_path)
	if next.is_empty():
		return
	if _clip.is_empty():
		_clip = next
	else:
		_clip = _intersect_clip(_clip, next)

func clip_circle(cx: float, cy: float, r: float) -> void:
	## Explicit circular clip (HTML peephole / portrait bust) in current local space.
	var c_world := _xform * Vector2(cx, cy)
	var edge := _xform * (Vector2(cx, cy) + Vector2(r, 0))
	var next := {"kind": "circle", "c": c_world, "r": c_world.distance_to(edge)}
	_last_full_arc = next.duplicate()
	if _clip.is_empty():
		_clip = next
	else:
		_clip = _intersect_clip(_clip, next)

func _path_to_clip(src: PackedVector2Array) -> Dictionary:
	var pts := _dedupe_path(src)
	if pts.size() < 3 and _last_full_arc.is_empty():
		return {}
	# Prefer tracked full circle (arc 0..2π)
	if not _last_full_arc.is_empty():
		return {
			"kind": "circle",
			"c": _last_full_arc.get("c", Vector2.ZERO),
			"r": float(_last_full_arc.get("r", 1.0)),
		}
	# Axis-aligned rect (4–5 points from rect/round_rect approximation)
	if pts.size() >= 4 and pts.size() <= 12:
		var mn := pts[0]
		var mx := pts[0]
		for p in pts:
			mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
			mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
		var bb := Rect2(mn, mx - mn)
		# Nearly rectangular: all points near bbox edges
		var edgeish := 0
		for p in pts:
			var on_x := absf(p.x - mn.x) < 1.5 or absf(p.x - mx.x) < 1.5
			var on_y := absf(p.y - mn.y) < 1.5 or absf(p.y - mx.y) < 1.5
			if on_x or on_y:
				edgeish += 1
		if edgeish >= pts.size() - 1 and bb.size.x > 2.0 and bb.size.y > 2.0:
			# Distinguishes circle polyline (many points on arc, not edges) from rect
			if pts.size() <= 6 or edgeish == pts.size():
				return {"kind": "rect", "rect": bb}
	# Circle-like closed path (nearly constant radius from centroid)
	if pts.size() >= 12:
		var c := Vector2.ZERO
		for p in pts:
			c += p
		c /= float(pts.size())
		var rs: Array = []
		var r_sum := 0.0
		for p in pts:
			var d := c.distance_to(p)
			rs.append(d)
			r_sum += d
		var r_avg := r_sum / float(pts.size())
		var var_sum := 0.0
		for d in rs:
			var_sum += absf(float(d) - r_avg)
		if r_avg > 2.0 and var_sum / float(pts.size()) < r_avg * 0.08:
			return {"kind": "circle", "c": c, "r": r_avg}
	# Free polygon clip
	if pts.size() >= 3:
		if pts[0].distance_to(pts[pts.size() - 1]) > 0.05:
			pts.append(pts[0])
		return {"kind": "poly", "poly": pts}
	return {}

func _intersect_clip(a: Dictionary, b: Dictionary) -> Dictionary:
	## Approximate nested clip as intersection of AABBs when kinds differ; poly∩poly when both poly.
	if a.get("kind") == "rect" and b.get("kind") == "rect":
		var ra: Rect2 = a.rect
		var rb: Rect2 = b.rect
		var inter := ra.intersection(rb)
		if inter.size.x <= 0.0 or inter.size.y <= 0.0:
			return {"kind": "rect", "rect": Rect2()}
		return {"kind": "rect", "rect": inter}
	if a.get("kind") == "circle" and b.get("kind") == "circle":
		# Keep the tighter circle if centers are close; else fall back to AABB intersect
		var ca: Vector2 = a.c
		var cb: Vector2 = b.c
		if ca.distance_to(cb) < 2.0:
			return a if float(a.r) <= float(b.r) else b
	# General: AABB intersection as practical Godot mid-draw clip
	var aa := _clip_aabb_of(a)
	var bb := _clip_aabb_of(b)
	var inter2 := aa.intersection(bb)
	if inter2.size.x <= 0.0 or inter2.size.y <= 0.0:
		return {"kind": "rect", "rect": Rect2()}
	# Preserve circle if it fits entirely in intersected AABB
	if b.get("kind") == "circle":
		var c: Vector2 = b.c
		var r: float = float(b.r)
		if inter2.grow(-r * 0.05).has_point(c) or inter2.has_point(c):
			return {"kind": "circle", "c": c, "r": minf(r, minf(inter2.size.x, inter2.size.y) * 0.5)}
	if a.get("kind") == "circle":
		var c2: Vector2 = a.c
		var r2: float = float(a.r)
		if inter2.has_point(c2):
			return {"kind": "circle", "c": c2, "r": minf(r2, minf(inter2.size.x, inter2.size.y) * 0.5)}
	return {"kind": "rect", "rect": inter2}

func _clip_aabb_of(cl: Dictionary) -> Rect2:
	if cl.is_empty():
		return Rect2(-1e6, -1e6, 2e6, 2e6)
	match str(cl.get("kind", "")):
		"rect":
			return cl.rect as Rect2
		"circle":
			var c: Vector2 = cl.c
			var r: float = float(cl.r)
			return Rect2(c - Vector2(r, r), Vector2(r * 2.0, r * 2.0))
		"poly":
			var poly: PackedVector2Array = cl.poly
			if poly.is_empty():
				return Rect2()
			var mn := poly[0]
			var mx := poly[0]
			for p in poly:
				mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
				mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
			return Rect2(mn, mx - mn)
	return Rect2(-1e6, -1e6, 2e6, 2e6)

func _clip_aabb() -> Rect2:
	return _clip_aabb_of(_clip)

func _clip_rect(r: Rect2) -> Rect2:
	if _clip.is_empty():
		return r
	if str(_clip.get("kind", "")) == "circle":
		# Rect fill under circle: keep AABB intersect (true circle mask is for images/polys)
		var aabb := _clip_aabb()
		return r.intersection(aabb)
	var aabb2 := _clip_aabb()
	return r.intersection(aabb2)

func _clip_poly(pts: PackedVector2Array) -> PackedVector2Array:
	## Sutherland–Hodgman / reject-outside — no Geometry2D (avoids engine triangulation errors)
	if _clip.is_empty() or pts.size() < 3:
		return pts
	match str(_clip.get("kind", "")):
		"rect":
			return _sutherland_hodgman_rect(pts, _clip.rect as Rect2)
		"circle":
			# Keep vertices inside circle; for edges, leave to ear-clip (HTML clip is pixel-perfect; this is geometric)
			var c: Vector2 = _clip.c
			var rad: float = float(_clip.r)
			var out := PackedVector2Array()
			for p in pts:
				if c.distance_to(p) <= rad + 0.5:
					out.append(p)
			if out.size() >= 3:
				return out
			# entire poly outside or fully covering — if centroid inside, keep original (common for busts)
			var cen := Vector2.ZERO
			for p2 in pts:
				cen += p2
			cen /= float(pts.size())
			if c.distance_to(cen) <= rad:
				return pts
			return PackedVector2Array()
		"poly":
			# AABB reject then keep (full poly∩poly is rare in this game)
			var ab := _clip_aabb()
			var kept := PackedVector2Array()
			for p3 in pts:
				if ab.has_point(p3):
					kept.append(p3)
			return kept if kept.size() >= 3 else PackedVector2Array()
	return pts

func _sutherland_hodgman_rect(subj: PackedVector2Array, r: Rect2) -> PackedVector2Array:
	## Clip polygon to axis-aligned rect (HTML playfield clip)
	var out := subj
	# left, right, top, bottom edges
	out = _clip_edge(out, true, true, r.position.x)   # x >= left
	out = _clip_edge(out, true, false, r.end.x)       # x <= right
	out = _clip_edge(out, false, true, r.position.y)  # y >= top
	out = _clip_edge(out, false, false, r.end.y)      # y <= bottom
	return out

func _clip_edge(inp: PackedVector2Array, is_x: bool, keep_gte: bool, edge: float) -> PackedVector2Array:
	if inp.size() < 2:
		return PackedVector2Array()
	var out := PackedVector2Array()
	var n := inp.size()
	# treat as open ring: last may equal first
	for i in range(n):
		var cur: Vector2 = inp[i]
		var prv: Vector2 = inp[(i - 1 + n) % n]
		var cur_in := _inside_edge(cur, is_x, keep_gte, edge)
		var prv_in := _inside_edge(prv, is_x, keep_gte, edge)
		if cur_in:
			if not prv_in:
				out.append(_intersect_edge(prv, cur, is_x, edge))
			out.append(cur)
		elif prv_in:
			out.append(_intersect_edge(prv, cur, is_x, edge))
	return out

func _inside_edge(p: Vector2, is_x: bool, keep_gte: bool, edge: float) -> bool:
	var v := p.x if is_x else p.y
	return v >= edge - 0.001 if keep_gte else v <= edge + 0.001

func _intersect_edge(a: Vector2, b: Vector2, is_x: bool, edge: float) -> Vector2:
	if is_x:
		var t := 0.0 if absf(b.x - a.x) < 1e-9 else (edge - a.x) / (b.x - a.x)
		return Vector2(edge, a.y + (b.y - a.y) * t)
	var t2 := 0.0 if absf(b.y - a.y) < 1e-9 else (edge - a.y) / (b.y - a.y)
	return Vector2(a.x + (b.x - a.x) * t2, edge)

func draw_image(img, dx, dy, dw=null, dh=null) -> void:
	if node == null or img == null:
		return
	var tex: Texture2D = img as Texture2D
	if tex == null:
		return
	var p := _xform * Vector2(dx, dy)
	var size := Vector2(dw if dw != null else tex.get_width(), dh if dh != null else tex.get_height())
	var dest := Rect2(p, size)
	if _clip.is_empty():
		node.draw_texture_rect(tex, dest, false)
		return
	if str(_clip.get("kind", "")) == "circle":
		# HTML clip+drawImage: textured triangle fan (one tri per segment — never n>3 poly)
		var c: Vector2 = _clip.c
		var rad: float = float(_clip.r)
		var segs := 32
		var uvc := Vector2(
			(c.x - dest.position.x) / maxf(dest.size.x, 0.001),
			(c.y - dest.position.y) / maxf(dest.size.y, 0.001)
		)
		var colw := Color(1, 1, 1, _alpha)
		for i in range(segs):
			var a0 := float(i) / float(segs) * TAU
			var a1 := float(i + 1) / float(segs) * TAU
			var w0 := c + Vector2(cos(a0), sin(a0)) * rad
			var w1 := c + Vector2(cos(a1), sin(a1)) * rad
			var uv0 := Vector2(
				(w0.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(w0.y - dest.position.y) / maxf(dest.size.y, 0.001)
			)
			var uv1 := Vector2(
				(w1.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(w1.y - dest.position.y) / maxf(dest.size.y, 0.001)
			)
			node.draw_polygon(
				PackedVector2Array([c, w0, w1]),
				PackedColorArray([colw, colw, colw]),
				PackedVector2Array([uvc, uv0, uv1]),
				tex
			)
		return
	if str(_clip.get("kind", "")) == "rect":
		var r: Rect2 = _clip.rect
		var inter := dest.intersection(r)
		if inter.size.x <= 0.0 or inter.size.y <= 0.0:
			return
		var u0 := (inter.position.x - dest.position.x) / maxf(dest.size.x, 0.001)
		var v0 := (inter.position.y - dest.position.y) / maxf(dest.size.y, 0.001)
		var u1 := (inter.end.x - dest.position.x) / maxf(dest.size.x, 0.001)
		var v1 := (inter.end.y - dest.position.y) / maxf(dest.size.y, 0.001)
		var src := Rect2(
			u0 * tex.get_width(), v0 * tex.get_height(),
			(u1 - u0) * tex.get_width(), (v1 - v0) * tex.get_height()
		)
		node.draw_texture_rect_region(tex, inter, src)
		return
	if str(_clip.get("kind", "")) == "poly":
		var poly: PackedVector2Array = _clip.poly
		if poly.size() < 3:
			return
		var colw2 := Color(1, 1, 1, _alpha)
		var p0: Vector2 = poly[0]
		var uv0b := Vector2(
			(p0.x - dest.position.x) / maxf(dest.size.x, 0.001),
			(p0.y - dest.position.y) / maxf(dest.size.y, 0.001)
		)
		for i in range(1, poly.size() - 1):
			var p1: Vector2 = poly[i]
			var p2: Vector2 = poly[i + 1]
			var uv1b := Vector2(
				(p1.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(p1.y - dest.position.y) / maxf(dest.size.y, 0.001)
			)
			var uv2b := Vector2(
				(p2.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(p2.y - dest.position.y) / maxf(dest.size.y, 0.001)
			)
			node.draw_polygon(
				PackedVector2Array([p0, p1, p2]),
				PackedColorArray([colw2, colw2, colw2]),
				PackedVector2Array([uv0b, uv1b, uv2b]),
				tex
			)
		return
	node.draw_texture_rect(tex, dest, false)

func create_radial_gradient(x0, y0, r0, x1, y1, r1) -> CanvasGradient:
	var g = CanvasGradient.new()
	g.kind = "radial"
	g.x0 = float(x0)
	g.y0 = float(y0)
	g.r0 = float(r0)
	g.x1 = float(x1)
	g.y1 = float(y1)
	g.r1 = float(r1)
	return g

func create_linear_gradient(x0, y0, x1, y1) -> CanvasGradient:
	var g = CanvasGradient.new()
	g.kind = "linear"
	g.x0 = float(x0)
	g.y0 = float(y0)
	g.x1 = float(x1)
	g.y1 = float(y1)
	return g

# camelCase aliases (HTML/JS ports)
func createLinearGradient(x0, y0, x1, y1) -> CanvasGradient:
	return create_linear_gradient(x0, y0, x1, y1)

func createRadialGradient(x0, y0, r0, x1, y1, r1) -> CanvasGradient:
	return create_radial_gradient(x0, y0, r0, x1, y1, r1)

func measure_text(text) -> Dictionary:
	var f := _active_font()
	return {"width": f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x}
