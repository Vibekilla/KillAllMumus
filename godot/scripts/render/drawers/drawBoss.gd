extends RefCounted
## 1:1 port of HTML drawBoss + drawHellPortal.

var ctx
var tick: int = 0
## Optional portrait drawers (set by PortedDraw via set_drawers)
var drawers: Dictionary = {}

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func set_drawers(d: Dictionary) -> void:
	drawers = d

func drawHellPortal(b) -> void:
	## HTML drawHellPortal
	var R = float(b.get("hellR", b.get("hell_r", 0)))
	if R <= 1.0:
		return
	var cx = float(b.get("x", 0))
	var cy = float(b.get("hy", b.get("y", 0)))
	ctx.save()
	ctx.translate(cx, cy)
	ctx.save()
	ctx.shadow_color("#ff2a00")
	ctx.shadow_blur(42)
	ctx.global_alpha(0.5)
	ctx.fill_style("#3a0008")
	ctx.begin_path()
	ctx.ellipse(0, 0, R * 1.16, R * 0.76, 0, 0, TAU)
	ctx.fill()
	ctx.restore()
	var sp = float(b.get("hellT", b.get("hell_t", 0))) * 0.12
	var cols = ["#ff5a1a", "#ff2a00", "#c01020", "#7a0818", "#3a0410"]
	for i in range(5):
		var rr = R * (1.0 - float(i) * 0.16)
		ctx.stroke_style(cols[i])
		ctx.line_width(3)
		ctx.global_alpha(0.9)
		ctx.begin_path()
		var a = 0.0
		var first = true
		while a <= 6.3:
			var r = rr + sin(a * 3.0 + sp + float(i)) * R * 0.05
			var px = cos(a + sp + float(i) * 0.5) * r
			var py = sin(a + sp + float(i) * 0.5) * r * 0.66
			if first:
				ctx.move_to(px, py)
				first = false
			else:
				ctx.line_to(px, py)
			a += 0.3
		ctx.close_path()
		ctx.stroke()
	ctx.global_alpha(1.0)
	ctx.fill_style("#08020a")
	ctx.begin_path()
	ctx.ellipse(0, 0, R * 0.4, R * 0.26, 0, 0, TAU)
	ctx.fill()
	ctx.restore()

func drawBoss(b) -> void:
	## HTML drawBoss
	var d: Dictionary = b.get("data", {})
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
	var flash: bool = float(b.get("flash", 0)) > 0.0
	var hell: bool = bool(b.get("hell", false))
	if hell:
		drawHellPortal(b)
	ctx.save()
	var hx = float(b.get("x", 0))
	if hell:
		hx += float(b.get("hellShake", b.get("hell_shake", 0)))
	ctx.translate(hx, float(b.get("y", 0)))
	if hell:
		ctx.rotate(float(b.get("hellSpin", b.get("hell_spin", 0))))
		var s = 1.0
		if b.get("hellScale") != null:
			s = float(b.get("hellScale"))
		elif b.get("hell_scale") != null:
			s = float(b.get("hell_scale"))
		ctx.scale(s, s)
	else:
		ctx.save()
		var col = str(d.get("color", "#c9a24b"))
		ctx.shadow_color(col)
		ctx.shadow_blur(30)
		ctx.global_alpha(0.35)
		ctx.fill_style(col)
		ctx.begin_path()
		ctx.arc(0, 0, float(b.get("r", 36)) * 1.2, 0, TAU)
		ctx.fill()
		ctx.restore()
		var face = float(b.get("face", PI / 2.0))
		ctx.rotate(face - PI / 2.0)
	var portrait = str(d.get("portrait", b.get("portrait", "ape")))
	_dispatch_portrait(portrait, b, flash)
	ctx.restore()
	if bool(b.get("dead", false)) and not hell:
		ctx.save()
		ctx.global_alpha(0.5 + 0.5 * sin(float(tick) * 0.3))
		ctx.fill_style("#fff")
		ctx.begin_path()
		ctx.arc(
			float(b.get("x", 0)),
			float(b.get("y", 0)),
			float(b.get("r", 36)) * (1.0 + float(b.get("deadT", b.get("dead_t", 0))) * 0.02),
			0,
			TAU
		)
		ctx.fill()
		ctx.restore()

func _dispatch_portrait(portrait: String, b, flash: bool) -> void:
	match portrait:
		"ape":
			_call_drawer("ape", "drawApe", b, flash)
		"robotnik":
			_call_drawer("robotnik", "drawRobotnik", b, flash)
		"mumina":
			_call_drawer("mumina", "drawMumina", b, flash)
		"lily":
			_call_drawer("lily", "drawLily", b, flash)
		"police":
			_call_drawer("police", "drawPolice", b, flash)
		"bogdanoff":
			_call_drawer("bogdanoff", "drawBogdanoff", b, flash)
		"devil":
			_call_drawer("devil", "drawDevil", b, flash)
		_:
			_call_drawer("wynn", "drawWynn", b, flash)

func _call_drawer(key: String, method: String, b, flash: bool) -> void:
	var dr = drawers.get(key)
	if dr and dr.has_method(method):
		dr.call(method, b, flash)
	elif dr and dr.has_method(method.to_lower()):
		dr.call(method.to_lower(), b, flash)
