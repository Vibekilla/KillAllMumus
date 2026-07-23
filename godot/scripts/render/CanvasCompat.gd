extends RefCounted
class_name CanvasCompat
## Canvas2D-compatible drawing API for 1:1 ports of HTML draw* code.
## Attach to a CanvasItem via bind(node); call begin_frame() before drawing; node.queue_redraw().

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
		var col: Color
		if color is Color:
			col = color
		else:
			col = CanvasCompat.static_parse_color(color)
		stops.append({"t": t, "c": col})
		stops.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))

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

func _c(col: Color) -> Color:
	var c := col
	c.a *= _alpha
	# Approximate Canvas GCO on Godot CanvasItem (no true blend modes mid-draw)
	match _gco:
		"lighter", "screen", "plus-lighter":
			# brighten: lift alpha + slight channel boost for glow FX
			c.a = minf(1.0, c.a * 1.35 + 0.08)
			c.r = minf(1.0, c.r * 1.08 + 0.04)
			c.g = minf(1.0, c.g * 1.08 + 0.04)
			c.b = minf(1.0, c.b * 1.08 + 0.04)
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
	if c is Color:
		return c
	var s := str(c).strip_edges().replace("'", "").replace('"', '')
	if s.begins_with("rgba(") or s.begins_with("rgb("):
		var inner := s.trim_prefix("rgba(").trim_prefix("rgb(").trim_suffix(")")
		var parts := inner.split(",")
		if parts.size() >= 3:
			var r := float(parts[0].strip_edges()) / 255.0
			var g := float(parts[1].strip_edges()) / 255.0
			var b := float(parts[2].strip_edges()) / 255.0
			var a := float(parts[3].strip_edges()) if parts.size() > 3 else 1.0
			if float(parts[0].strip_edges()) <= 1.0 and float(parts[1].strip_edges()) <= 1.0:
				r = float(parts[0].strip_edges())
				g = float(parts[1].strip_edges())
				b = float(parts[2].strip_edges())
			return Color(r, g, b, a)
	if s.begins_with("hsla(") or s.begins_with("hsl("):
		var inner2 := s.trim_prefix("hsla(").trim_prefix("hsl(").trim_suffix(")")
		var parts2 := inner2.split(",")
		if parts2.size() >= 3:
			var h := float(parts2[0].strip_edges())
			var sat := float(parts2[1].strip_edges().replace("%", "")) / 100.0
			var lit := float(parts2[2].strip_edges().replace("%", "")) / 100.0
			var a2 := float(parts2[3].strip_edges()) if parts2.size() > 3 else 1.0
			return Color.from_hsv(fposmod(h, 360.0) / 360.0, sat, lit, a2)
	if s.begins_with("#"):
		return Color.html(s)
	return Color.WHITE

func _parse_color(c) -> Color:
	return static_parse_color(c)

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

func global_alpha(a: float) -> void:
	_alpha = a

func get_alpha() -> float:
	return _alpha

func shadow_color(c) -> void:
	if c is Color:
		_shadow_col = c
	elif c is String:
		_shadow_col = Color.html(str(c))

func shadow_blur(b: float) -> void:
	_shadow_blur = b

func font(f) -> void:
	# e.g. 'bold 12px monospace'
	var s := str(f)
	var m := RegEx.new()
	m.compile("(\\d+)px")
	var r := m.search(s)
	if r:
		_font_size = int(r.get_string(1))

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
	if a1f >= 6.0 and a0f == 0.0:
		a1f = TAU
	var rxf: float = float(rx)
	var ryf: float = float(ry)
	var rotf: float = float(rot)
	var steps := 24
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang: float = a0f + (a1f - a0f) * t
		if ccw:
			ang = a0f - (a1f - a0f) * t
		var lp := Vector2(cos(ang) * rxf, sin(ang) * ryf).rotated(rotf) + Vector2(float(x), float(y))
		_path.append(_xform * lp)

func round_rect(x, y, w, h, r) -> void:
	# simple rect path
	move_to(x+r, y)
	line_to(x+w-r, y)
	line_to(x+w, y+r)
	line_to(x+w, y+h-r)
	line_to(x+w-r, y+h)
	line_to(x+r, y+h)
	line_to(x, y+h-r)
	line_to(x, y+r)
	close_path()

func rect(x, y, w, h) -> void:
	move_to(x,y); line_to(x+w,y); line_to(x+w,y+h); line_to(x,y+h); close_path()

func fill() -> void:
	if node == null or _path.size() < 3:
		return
	var pts := _dedupe_path(_path)
	# Close open paths (HTML often omits closePath before fill)
	if pts.size() >= 3 and pts[0].distance_to(pts[pts.size() - 1]) > 0.05:
		pts.append(pts[0])
	if pts.size() < 3:
		return
	pts = _clip_poly(pts)
	if pts.size() < 3:
		return
	# Gradient fills on free paths: sample mid color (full band fill would need mesh UV)
	var col := _c(_fill_grad.mid_color() if _fill_grad != null else _fill)
	# Prefer simple closed polyline fill via triangle fan from centroid when path is well-formed;
	# otherwise thick outline. Avoid Geometry2D.decompose (engine ERROR spam on bad paths).
	var n := pts.size()
	if n >= 3 and n <= 64:
		var c := Vector2.ZERO
		for p in pts:
			c += p
		c /= float(n)
		var drew := false
		for i in range(n - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var area2 := absf((a.x - c.x) * (b.y - c.y) - (b.x - c.x) * (a.y - c.y))
			if area2 < 0.02:
				continue
			# Per-triangle sample for linear gradients (centroid of triangle)
			var fill_col := col
			if _fill_grad != null:
				var mid := (c + a + b) / 3.0
				fill_col = _c(_sample_grad_at_local(mid))
			node.draw_colored_polygon(PackedVector2Array([c, a, b]), fill_col)
			drew = true
		if drew:
			return
	node.draw_polyline(pts, col, maxf(_lw, 2.0), true)

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
		# Keep stroke segments roughly inside clip AABB (full segment clip is heavy)
		var ab := _clip_aabb()
		if ab.size.x > 0.0 and ab.size.y > 0.0:
			var kept := PackedVector2Array()
			for p in pts:
				if ab.grow(2.0).has_point(p):
					kept.append(p)
			if kept.size() < 2:
				return
			pts = kept
	node.draw_polyline(pts, _c(_stroke), _lw, true)

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
				node.draw_colored_polygon(pts, col)
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
	var p := _xform * Vector2(x, y)
	var f := ThemeDB.fallback_font
	var sz := _font_size
	var w := f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if _align == "center":
		p.x -= w * 0.5
	elif _align == "right":
		p.x -= w
	# Canvas text baseline ~alphabetic: Godot draws from top-left of glyphs
	p.y -= sz * 0.15
	node.draw_string(f, p, str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, _c(_fill))

func stroke_text(text, x, y) -> void:
	if node == null:
		return
	var p := _xform * Vector2(x, y)
	var f := ThemeDB.fallback_font
	var sz := _font_size
	var w := f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if _align == "center":
		p.x -= w * 0.5
	elif _align == "right":
		p.x -= w
	p.y -= sz * 0.15
	var col := _c(_stroke)
	# Approximate stroke via offset fills (Godot has no font outline API here)
	var o := maxf(1.0, _lw * 0.35)
	for d in [Vector2(-o, 0), Vector2(o, 0), Vector2(0, -o), Vector2(0, o), Vector2(-o, -o), Vector2(o, -o), Vector2(-o, o), Vector2(o, o)]:
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
	if _clip.is_empty() or pts.size() < 3:
		return pts
	match str(_clip.get("kind", "")):
		"rect":
			var r: Rect2 = _clip.rect
			var clip_poly := PackedVector2Array([
				r.position,
				r.position + Vector2(r.size.x, 0),
				r.position + r.size,
				r.position + Vector2(0, r.size.y),
				r.position,
			])
			var inter = Geometry2D.intersect_polygons(pts, clip_poly)
			if inter is Array and inter.size() > 0:
				return inter[0] as PackedVector2Array
			return PackedVector2Array()
		"circle":
			var c: Vector2 = _clip.c
			var rad: float = float(_clip.r)
			var circ := PackedVector2Array()
			var segs := 28
			for i in range(segs + 1):
				var ang := float(i) / float(segs) * TAU
				circ.append(c + Vector2(cos(ang), sin(ang)) * rad)
			var inter2 = Geometry2D.intersect_polygons(pts, circ)
			if inter2 is Array and inter2.size() > 0:
				return inter2[0] as PackedVector2Array
			return PackedVector2Array()
		"poly":
			var inter3 = Geometry2D.intersect_polygons(pts, _clip.poly)
			if inter3 is Array and inter3.size() > 0:
				return inter3[0] as PackedVector2Array
			return PackedVector2Array()
	return pts

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
		# Textured circle fan (HTML clip+drawImage for portraits / peephole)
		var c: Vector2 = _clip.c
		var rad: float = float(_clip.r)
		var segs := 32
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		pts.append(c)
		# UV for center relative to dest rect
		var uvc := Vector2(
			(c.x - dest.position.x) / maxf(dest.size.x, 0.001),
			(c.y - dest.position.y) / maxf(dest.size.y, 0.001)
		)
		uvs.append(uvc)
		for i in range(segs + 1):
			var ang := float(i) / float(segs) * TAU
			var wp := c + Vector2(cos(ang), sin(ang)) * rad
			pts.append(wp)
			uvs.append(Vector2(
				(wp.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(wp.y - dest.position.y) / maxf(dest.size.y, 0.001)
			))
		var cols := PackedColorArray()
		cols.resize(pts.size())
		for i in pts.size():
			cols[i] = Color(1, 1, 1, _alpha)
		node.draw_polygon(pts, cols, uvs, tex)
		return
	if str(_clip.get("kind", "")) == "rect":
		var r: Rect2 = _clip.rect
		var inter := dest.intersection(r)
		if inter.size.x <= 0.0 or inter.size.y <= 0.0:
			return
		# Source region of texture corresponding to intersection
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
	# poly clip: textured polygon from clip poly
	if str(_clip.get("kind", "")) == "poly":
		var poly: PackedVector2Array = _clip.poly
		if poly.size() < 3:
			return
		var uvs2 := PackedVector2Array()
		for wp in poly:
			uvs2.append(Vector2(
				(wp.x - dest.position.x) / maxf(dest.size.x, 0.001),
				(wp.y - dest.position.y) / maxf(dest.size.y, 0.001)
			))
		var cols2 := PackedColorArray()
		cols2.resize(poly.size())
		for i in poly.size():
			cols2[i] = Color(1, 1, 1, _alpha)
		node.draw_polygon(poly, cols2, uvs2, tex)
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
	var f := ThemeDB.fallback_font
	return {"width": f.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x}
