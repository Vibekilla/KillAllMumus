extends RefCounted
## 1:1 port of HTML drawStageBg + drawStageBgFx.

var ctx
var tick: int = 0
var bg_seed: float = 1.7
var bg_hue_seed: float = 0.0
var bg_petals: int = 5

func setup(c) -> void:
	ctx = c
	bg_seed = randf() * TAU
	bg_hue_seed = randf() * 40.0
	bg_petals = 3 + randi() % 5

func set_tick(t: int) -> void:
	tick = t

func drawStageBg() -> void:
	## HTML drawStageBg
	var s = GameState.stage_index if GameState else 0
	var sc = float(tick)
	if StageFlow and StageFlow.get("kills_this_stage") != null:
		# stageTime not always tracked; tick is fine for scroll
		sc = float(tick)
	var top = "#0b2412"
	var bot = "#193f1f"
	match s:
		1:
			top = "#0b1a30"
			bot = "#1c3f60"
		2:
			top = "#0d200d"
			bot = "#1f501c"
		3:
			top = "#150826"
			bot = "#2c1648"
		4:
			top = "#241808"
			bot = "#3f2c0d"
		5:
			top = "#0a0a1e"
			bot = "#1b1746"
		6:
			top = "#240812"
			bot = "#4e1019"
	var pf: Rect2 = Config.playfield()
	# HTML: createLinearGradient(0, PF.y, 0, PF.y+PF.h) + stops top→bot
	var g = ctx.create_linear_gradient(0, pf.position.y, 0, pf.position.y + pf.size.y)
	g.addColorStop(0, top)
	g.addColorStop(1, bot)
	ctx.fill_style(g)
	ctx.fill_rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	drawStageBgFx(s)
	# scrolling environment motif
	var speed = 1.4 if s == 1 else 2.0
	var off = fmod(sc * speed, 80.0)
	ctx.global_alpha(0.11)
	var y = -80.0
	while y < pf.size.y + 80.0:
		var x = 0.0
		while x < pf.size.x:
			var px = pf.position.x + x
			var py = pf.position.y + fmod(y + off, pf.size.y + 80.0)
			_motif(s, px, py, sc)
			x += 80.0
		y += 80.0
	ctx.global_alpha(1.0)

func _motif(s: int, px: float, py: float, sc: float) -> void:
	match s:
		0:
			ctx.fill_style("#7cbf5a")
			ctx.begin_path()
			ctx.ellipse(px + 40, py + 40, 26, 10, 0.5, 0, TAU)
			ctx.fill()
		1:
			ctx.fill_style("#bfe6ff")
			ctx.begin_path()
			ctx.move_to(px + 40, py + 20)
			ctx.line_to(px + 48, py + 40)
			ctx.line_to(px + 40, py + 60)
			ctx.line_to(px + 32, py + 40)
			ctx.close_path()
			ctx.fill()
		2:
			ctx.fill_style("#8fd35a")
			ctx.begin_path()
			ctx.move_to(px + 40, py + 22)
			ctx.quadratic_curve_to(px + 58, py + 40, px + 40, py + 58)
			ctx.quadratic_curve_to(px + 22, py + 40, px + 40, py + 22)
			ctx.fill()
		3:
			ctx.save()
			ctx.translate(px + 40, py + 40)
			ctx.rotate(-0.5)
			ctx.fill_style("#9945ff")
			ctx.fill_rect(-15, -9, 30, 4)
			ctx.fill_style("#14f195")
			ctx.fill_rect(-15, -1, 30, 4)
			ctx.fill_style("#9945ff")
			ctx.fill_rect(-15, 7, 30, 4)
			ctx.restore()
		4:
			ctx.fill_style("#e0a850")
			ctx.fill_rect(px + 30, py + 28, 20, 16)
			ctx.fill_style("#3a2e18")
			ctx.fill_rect(px + 33, py + 31, 14, 8)
			ctx.fill_style("#e0a850")
			ctx.fill_rect(px + 37, py + 44, 6, 4)
		5:
			ctx.save()
			ctx.translate(px + 40, py + 40)
			ctx.rotate(sc * 0.008)
			ctx.fill_style("#b48ce0")
			ctx.begin_path()
			ctx.move_to(0, -13)
			ctx.line_to(3, -3)
			ctx.line_to(13, 0)
			ctx.line_to(3, 3)
			ctx.line_to(0, 13)
			ctx.line_to(-3, 3)
			ctx.line_to(-13, 0)
			ctx.line_to(-3, -3)
			ctx.close_path()
			ctx.fill()
			ctx.fill_style("#e0b84a")
			ctx.begin_path()
			ctx.arc(0, 0, 2.4, 0, TAU)
			ctx.fill()
			ctx.restore()
		_:
			ctx.fill_style("#ff5b6e")
			ctx.fill_rect(px + 30, py + 20, 20, 44)

func drawStageBgFx(s: int = -1) -> void:
	## HTML drawStageBgFx
	if s < 0:
		s = GameState.stage_index if GameState else 0
	var t = float(tick)
	var pf: Rect2 = Config.playfield()
	var cx = pf.position.x + pf.size.x * 0.5
	var cy = pf.position.y + pf.size.y * 0.42
	var H = pf.size.y
	var W = pf.size.x
	var bi = 0.5
	var tree = Engine.get_main_loop()
	if tree and tree is SceneTree:
		var boss = (tree as SceneTree).get_first_node_in_group("bosses")
		if boss and is_instance_valid(boss) and not bool(boss.get("dead")):
			var intro_v = boss.get("intro")
			if intro_v == null or float(intro_v) <= 0.0:
				var rage = 0.8
				var st2 = boss.get("special_t")
				if st2 != null and float(st2) > 0.0:
					rage += 0.4
				var mhp = boss.get("max_hp")
				var hp = boss.get("hp")
				if mhp != null and hp != null and float(mhp) > 0.0:
					rage += (1.0 - float(hp) / float(mhp)) * 0.35
				bi = minf(1.4, rage)
	var drift = sin(t * 0.006 + bg_seed) * 30.0 + bg_hue_seed
	ctx.save()
	ctx.begin_path()
	ctx.rect(pf.position.x, pf.position.y, pf.size.x, pf.size.y)
	ctx.clip()
	match s:
		0:
			_fx_jungle(t, cx, cy, H, W, bi, drift, pf)
		1:
			_fx_frozen(t, cx, cy, H, bi, drift)
		2:
			_fx_kingdom(t, cx, cy, H, bi, drift)
		3:
			_fx_solana(t, pf, H, W, bi, drift)
		4:
			_fx_callcenter(t, cx, cy, H, W, bi, drift)
		5:
			_fx_akashic(t, cx, cy, H, W, bi, drift)
		_:
			_fx_lair(t, cx, cy, H, bi, drift)
	ctx.restore()

func _fx_jungle(t, cx, cy, H, W, bi, drift, pf: Rect2) -> void:
	for L in range(4):
		var rr = (0.2 + float(L) * 0.2) * H * (1.0 + sin(t * 0.01 + float(L) + bg_seed) * 0.05)
		var a0 = t * 0.003 * (1.0 if L % 2 else -1.0) + float(L) * 0.6 + bg_seed
		var N = 5 + L
		ctx.stroke_style("hsla(%d,55%%,%d%%,%s)" % [140 + L * 16 + int(drift), 18 + L * 5, str(0.13 + 0.07 * bi)])
		ctx.line_width(2.4)
		ctx.begin_path()
		for i in range(N + 1):
			var a = a0 + float(i) / float(N) * TAU
			var x = cx + cos(a) * rr
			var y = cy + sin(a) * rr * 0.92
			if i == 0:
				ctx.move_to(x, y)
			else:
				ctx.line_to(x, y)
		ctx.close_path()
		ctx.stroke()
	for i in range(16):
		var px = pf.position.x + fmod(float(i) * 83.0 + t * 0.6, W)
		var py = pf.position.y + fmod(float(i) * 127.0 + t * 1.4, H)
		var r = 5.0 + float(i % 4) * 3.0
		ctx.fill_style("hsla(%d,50%%,24%%,%s)" % [115 + i * 6 + int(drift), str(0.09 + 0.05 * bi)])
		ctx.save()
		ctx.translate(px, py)
		ctx.rotate(t * 0.02 + float(i))
		ctx.begin_path()
		ctx.move_to(0, -r)
		ctx.line_to(r, r)
		ctx.line_to(-r, r)
		ctx.close_path()
		ctx.fill()
		ctx.restore()

func _fx_frozen(t, cx, cy, H, bi, drift) -> void:
	ctx.translate(cx, cy)
	var arms = 6
	var rot = t * 0.004 + bg_seed
	for a_i in range(arms):
		ctx.save()
		ctx.rotate(rot + float(a_i) / float(arms) * TAU)
		ctx.stroke_style("hsla(%d,50%%,30%%,%s)" % [205 + int(drift), str(0.13 + 0.07 * bi)])
		ctx.line_width(2)
		ctx.begin_path()
		ctx.move_to(0, 0)
		var r = 0.0
		while r < H * 0.52:
			ctx.line_to(sin(r * 0.06 + t * 0.03) * 10.0, -r)
			r += 14.0
		ctx.stroke()
		r = 28.0
		while r < H * 0.5:
			var w = sin(r * 0.06 + t * 0.03) * 10.0
			ctx.begin_path()
			ctx.move_to(w, -r)
			ctx.line_to(w + 11, -r + 8)
			ctx.move_to(w, -r)
			ctx.line_to(w - 11, -r + 8)
			ctx.stroke()
			r += 34.0
		ctx.restore()
	for i in range(8):
		var a = t * 0.01 + float(i) * 0.785 + bg_seed
		var rr = H * 0.18 + sin(t * 0.02 + float(i)) * H * 0.14
		ctx.fill_style("hsla(330,60%%,42%%,%s)" % str(0.07 + 0.05 * bi))
		ctx.begin_path()
		ctx.arc(cos(a) * rr, sin(a) * rr, 3, 0, TAU)
		ctx.fill()

func _fx_kingdom(t, cx, cy, H, bi, drift) -> void:
	ctx.translate(cx, cy)
	var k = float(bg_petals)
	for L in range(2):
		var scale = (0.3 + float(L) * 0.12) * H
		var hue = 280 if L else 130
		ctx.stroke_style("hsla(%d,55%%,%d%%,%s)" % [hue + int(drift), 20 + L * 6, str(0.12 + 0.07 * bi)])
		ctx.line_width(2)
		ctx.begin_path()
		var a = 0.0
		var first = true
		while a <= 6.4:
			var r = cos(k * a + t * 0.01 * (-1.0 if L else 1.0) + bg_seed) * scale
			var x = cos(a) * r
			var y = sin(a) * r
			if first:
				ctx.move_to(x, y)
				first = false
			else:
				ctx.line_to(x, y)
			a += 0.05
		ctx.stroke()

func _fx_solana(t, pf: Rect2, H, W, bi, drift) -> void:
	var hx = 52.0
	var hy = 46.0
	var ph = t * 0.5
	var gy = -1.0
	while gy < H / hy + 1.0:
		var gx = -1.0
		while gx < W / hx + 1.0:
			var ox = (int(gy) & 1) * hx * 0.5
			var bx = pf.position.x + gx * hx + ox
			var by = pf.position.y + fmod(gy * hy + ph, H + hy)
			var pulse = 0.5 + 0.5 * sin((gx + gy) * 0.6 + t * 0.05 + bg_seed)
			ctx.stroke_style("hsla(%d,60%%,%d%%,%s)" % [
				268 + int(pulse * 50) + int(drift),
				16 + int(pulse * 20),
				str((0.07 + 0.08 * bi) * (0.35 + pulse * 0.65))
			])
			ctx.line_width(1.4)
			ctx.begin_path()
			for i in range(6):
				var a = float(i) / 6.0 * TAU + 0.52
				var x = bx + cos(a) * 15.0
				var y = by + sin(a) * 15.0
				if i == 0:
					ctx.move_to(x, y)
				else:
					ctx.line_to(x, y)
			ctx.close_path()
			ctx.stroke()
			gx += 1.0
		gy += 1.0

func _fx_callcenter(t, cx, cy, H, W, bi, drift) -> void:
	ctx.translate(cx, cy)
	for k in range(6):
		var ph = fmod(t * 0.01 + float(k) / 6.0 + bg_seed * 0.16, 1.0)
		var rr = ph * H * 0.62
		ctx.stroke_style("hsla(%d,65%%,28%%,%s)" % [
			32 + int(sin(t * 0.02) * 18) + int(drift),
			str((1.0 - ph) * (0.13 + 0.08 * bi))
		])
		ctx.line_width(2)
		ctx.begin_path()
		ctx.arc(0, 0, rr, 0, TAU)
		ctx.stroke()
	ctx.stroke_style("hsla(185,50%%,28%%,%s)" % str(0.06 + 0.04 * bi))
	ctx.line_width(1)
	var sp = fmod(t * 0.6, 22.0)
	var y = -H / 2.0
	while y < H / 2.0:
		ctx.begin_path()
		ctx.move_to(-W / 2.0, y + sp)
		ctx.line_to(W / 2.0, y + sp)
		ctx.stroke()
		y += 22.0

func _fx_akashic(t, cx, cy, H, W, bi, drift) -> void:
	ctx.translate(cx, cy)
	var rot = t * 0.004 + bg_seed
	for L in range(4):
		var rr = (0.16 + float(L) * 0.12) * H
		var hue = 266 if L % 2 else 44
		var ta = rot * (1.0 if L % 2 else -1.0)
		ctx.stroke_style("hsla(%d,58%%,%d%%,%s)" % [hue + int(drift), 20 + L * 4, str(0.12 + 0.07 * bi)])
		ctx.line_width(1.8)
		ctx.begin_path()
		ctx.arc(0, 0, rr, 0, TAU)
		ctx.stroke()
		var ticks = 10 + L * 6
		for i in range(ticks):
			var a = ta + float(i) / float(ticks) * TAU
			ctx.begin_path()
			ctx.move_to(cos(a) * rr, sin(a) * rr)
			ctx.line_to(cos(a) * (rr + 5.0), sin(a) * (rr + 5.0))
			ctx.stroke()
	ctx.stroke_style("hsla(%d,60%%,32%%,%s)" % [45 + int(drift), str(0.05 + 0.05 * bi)])
	ctx.line_width(1.3)
	for k in range(18):
		var a = float(k) / 18.0 * TAU - t * 0.004
		ctx.begin_path()
		ctx.move_to(cos(a) * 24.0, sin(a) * 24.0)
		ctx.line_to(cos(a) * H * 0.52, sin(a) * H * 0.52)
		ctx.stroke()
	for i in range(16):
		var gx = fmod(float(i) * 71.0 + bg_seed * 30.0, W) - W / 2.0
		var gy = fmod(fmod(float(i) * 143.0 - t * 0.6, H) + H, H) - H / 2.0
		var r = 4.0 + float(i % 3) * 2.4
		ctx.save()
		ctx.translate(gx, gy)
		ctx.rotate(t * 0.02 + float(i))
		ctx.stroke_style("hsla(%d,60%%,30%%,%s)" % [(266 if i % 2 else 45) + int(drift), str(0.08 + 0.06 * bi)])
		ctx.line_width(1.3)
		ctx.begin_path()
		ctx.move_to(0, -r)
		ctx.line_to(r, 0)
		ctx.line_to(0, r)
		ctx.line_to(-r, 0)
		ctx.close_path()
		ctx.stroke()
		ctx.begin_path()
		ctx.move_to(-r * 0.5, 0)
		ctx.line_to(r * 0.5, 0)
		ctx.stroke()
		ctx.restore()

func _fx_lair(t, cx, cy, H, bi, drift) -> void:
	ctx.translate(cx, cy)
	var rot = t * 0.005 + bg_seed
	for L in range(4):
		var rr = (0.5 - float(L) * 0.1) * H
		var N = 5
		var a0 = rot * (1.0 if L % 2 else -1.0)
		ctx.stroke_style("hsla(%d,60%%,%d%%,%s)" % [350 + L * 14 + int(drift), 16 + L * 5, str(0.13 + 0.07 * bi)])
		ctx.line_width(2.2)
		ctx.begin_path()
		for i in range(N + 1):
			var a = a0 + float(i) / float(N) * TAU
			var x = cos(a) * rr
			var y = sin(a) * rr
			if i == 0:
				ctx.move_to(x, y)
			else:
				ctx.line_to(x, y)
		ctx.close_path()
		ctx.stroke()
		if L < 2:
			for i in range(N):
				var a2 = a0 + float(i) / float(N) * TAU
				ctx.begin_path()
				ctx.move_to(0, 0)
				ctx.line_to(cos(a2) * rr, sin(a2) * rr)
				ctx.stroke()
