extends RefCounted
## 1:1 port of HTML drawMeleeFx (+ drawMeleeWeapon via drawCombatFx).

var ctx
var tick: int = 0
var combat_fx  # optional drawCombatFx for weapons

func setup(c) -> void:
	ctx = c
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	if combat_fx and combat_fx.has_method("setup"):
		combat_fx.setup(c)

func set_tick(t: int) -> void:
	tick = t
	if combat_fx and combat_fx.has_method("set_tick"):
		combat_fx.set_tick(t)

func drawMeleeWeapon(key, length = 100.0, col = "#fff", charge = 0.0) -> void:
	## HTML drawMeleeWeapon
	if combat_fx and combat_fx.has_method("draw_melee_weapon"):
		combat_fx.draw_melee_weapon(str(key), float(length), str(col), float(charge))

func drawMeleeFx(melee_fx: Array = [], player: Node = null) -> void:
	## HTML drawMeleeFx — pass CombatHelpers.melee_fx or MeleeSystem swipe_fx
	var list: Array = melee_fx
	if list.is_empty() and CombatHelpers:
		list = CombatHelpers.melee_fx
	for f in list:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var life = maxf(1.0, float(f.get("life", 1)))
		var pr = float(f.get("t", 0)) / life
		if bool(f.get("bolt", false)):
			_draw_bolt(f, pr)
			continue
		if bool(f.get("ring", false)):
			_draw_ring(f, pr)
			continue
		_draw_slash(f, pr)
	# charge ring around player while holding melee
	if player == null:
		var tree = Engine.get_main_loop()
		if tree and tree is SceneTree:
			player = (tree as SceneTree).get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var melee = player.get("melee")
		var holding = false
		var chg = 0.0
		if melee:
			holding = bool(melee.get("holding"))
			chg = float(melee.get("charge"))
		if holding and chg > 0.04:
			_draw_charge_ring(player, chg)

func _draw_bolt(f: Dictionary, pr: float) -> void:
	var al = 1.0 - pr
	var pts: Array = f.get("pts", [])
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.stroke_style(str(f.get("col", "#8fd0ff")))
	ctx.shadow_color(str(f.get("col", "#8fd0ff")))
	ctx.shadow_blur(8)
	ctx.line_cap("round")
	ctx.line_join("round")
	ctx.global_alpha(al)
	ctx.line_width(2.4)
	for i in range(1, pts.size()):
		var a: Dictionary = pts[i - 1] if typeof(pts[i - 1]) == TYPE_DICTIONARY else {"x": 0, "y": 0}
		var b: Dictionary = pts[i] if typeof(pts[i]) == TYPE_DICTIONARY else {"x": 0, "y": 0}
		var ax = float(a.get("x", 0))
		var ay = float(a.get("y", 0))
		var bx = float(b.get("x", 0))
		var by = float(b.get("y", 0))
		ctx.begin_path()
		ctx.move_to(ax, ay)
		for s in range(1, 5):
			var tt = float(s) / 4.0
			ctx.line_to(
				ax + (bx - ax) * tt + (randf() - 0.5) * 9.0,
				ay + (by - ay) * tt + (randf() - 0.5) * 9.0
			)
		ctx.stroke()
	ctx.shadow_blur(0)
	ctx.stroke_style("#fff")
	ctx.line_width(1)
	for i in range(1, pts.size()):
		var a2: Dictionary = pts[i - 1] if typeof(pts[i - 1]) == TYPE_DICTIONARY else {"x": 0, "y": 0}
		var b2: Dictionary = pts[i] if typeof(pts[i]) == TYPE_DICTIONARY else {"x": 0, "y": 0}
		ctx.begin_path()
		ctx.move_to(float(a2.get("x", 0)), float(a2.get("y", 0)))
		ctx.line_to(float(b2.get("x", 0)), float(b2.get("y", 0)))
		ctx.stroke()
	ctx.restore()
	ctx.global_alpha(1.0)

func _draw_ring(f: Dictionary, pr: float) -> void:
	var r = float(f.get("r0", 5)) + (float(f.get("r1", 42)) - float(f.get("r0", 5))) * pr
	var al = 1.0 - pr
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.line_width(5.0 * (1.0 - pr) + 1.0)
	if bool(f.get("rainbow", false)):
		var base = float((tick * 4) % 360)
		var segs = 24
		for s in range(segs):
			var a0 = float(s) / float(segs) * TAU
			var a1 = float(s + 1) / float(segs) * TAU + 0.02
			var hue = fmod(base + float(s) / float(segs) * 360.0, 360.0)
			ctx.stroke_style("hsla(%d,100%%,64%%,%s)" % [int(hue), str(al * 0.85)])
			ctx.begin_path()
			ctx.arc(0, 0, r, a0, a1)
			ctx.stroke()
	else:
		var col = str(f.get("col", "#fff"))
		ctx.stroke_style(col)
		ctx.shadow_color(col)
		ctx.shadow_blur(16)
		ctx.global_alpha(al * 0.75)
		ctx.begin_path()
		ctx.arc(0, 0, r, 0, TAU)
		ctx.stroke()
		ctx.global_alpha(al)
		ctx.stroke_style("#fff")
		ctx.line_width(1.5)
		ctx.begin_path()
		ctx.arc(0, 0, r * 0.96, 0, TAU)
		ctx.stroke()
	ctx.restore()
	ctx.global_alpha(1.0)

func _draw_slash(f: Dictionary, pr: float) -> void:
	var rad = float(f.get("reach", 120)) * (0.55 + pr * 0.45)
	var a0 = float(f.get("dir", -PI / 2.0)) - float(f.get("half", 1.0))
	var a1 = float(f.get("dir", -PI / 2.0)) + float(f.get("half", 1.0))
	var al = 1.0 - pr
	var col = str(f.get("col", "#ff2b4d"))
	var charge = float(f.get("charge", 0))
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.translate(float(f.get("x", 0)), float(f.get("y", 0)))
	ctx.line_cap("round")
	ctx.line_join("round")
	ctx.global_alpha(al * 0.8)
	ctx.stroke_style(col)
	ctx.line_width(6.0 + charge * 9.0)
	ctx.shadow_color(col)
	ctx.shadow_blur(16)
	ctx.begin_path()
	ctx.arc(0, 0, rad, a0, a1)
	ctx.stroke()
	ctx.global_alpha(al)
	ctx.stroke_style("#fff")
	ctx.line_width(2.2)
	ctx.begin_path()
	ctx.arc(0, 0, rad * 0.98, a0, a1)
	ctx.stroke()
	var swing = a0 + minf(1.0, pr * 1.2) * (a1 - a0)
	ctx.rotate(swing)
	ctx.global_alpha(maxf(0.22, 1.0 - pr * 0.62))
	ctx.shadow_blur(10)
	drawMeleeWeapon(str(f.get("key", "katana")), float(f.get("reach", 120)) * 0.92, col, charge)
	ctx.restore()
	ctx.global_alpha(1.0)

func _draw_charge_ring(player: Node, c: float) -> void:
	var mcol = "#ff2b4d"
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {}) if ProgressStore else {}
	var ms: Array = ar.get("m", ["katana"]) if ar else ["katana"]
	var mk = str(ms[0]) if ms.size() else "katana"
	for m in DataRegistry.melee if DataRegistry else []:
		if str(m.get("key")) == mk:
			mcol = str(m.get("col", mcol))
			break
	var pos: Vector2 = player.global_position
	# bodyCtr offset ~ -16 body center
	var mc = pos + Vector2(0, -16)
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.translate(mc.x, mc.y)
	ctx.stroke_style(mcol)
	ctx.shadow_color(mcol)
	ctx.shadow_blur(10)
	ctx.line_cap("round")
	ctx.global_alpha(0.5 + 0.4 * c)
	ctx.line_width(2.6)
	ctx.begin_path()
	ctx.arc(0, 0, 15 + c * 7, -PI / 2.0, -PI / 2.0 + c * PI * 2.0)
	ctx.stroke()
	if c >= 1.0:
		ctx.global_alpha(0.5 + 0.4 * sin(float(tick) * 0.5))
		ctx.line_width(2)
		ctx.begin_path()
		ctx.arc(0, 0, 24, 0, TAU)
		ctx.stroke()
	ctx.restore()
	ctx.global_alpha(1.0)
