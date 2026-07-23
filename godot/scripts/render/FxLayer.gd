extends Node2D
## World-space FX: particles, score pops, flash msg, melee swipe weapons.

var ctx: RefCounted
var combat_fx: RefCounted
var item_draw: RefCounted
var ported: RefCounted
var tick: int = 0

func _ready() -> void:
	z_index = 50
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	combat_fx = load("res://scripts/render/drawers/drawCombatFx.gd").new()
	combat_fx.setup(ctx)
	item_draw = load("res://scripts/render/drawers/drawItem.gd").new()
	item_draw.setup(ctx)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)
	set_process(true)

func _process(delta: float) -> void:
	if CombatHelpers:
		CombatHelpers.tick_fx(delta)
	if ItemSystem:
		ItemSystem.tick(delta)
	if SimClock:
		tick = SimClock.tick
	queue_redraw()

func _draw() -> void:
	if ctx == null:
		return
	ctx.begin_frame()
	if combat_fx:
		combat_fx.set_tick(tick)
	# particles
	if CombatHelpers:
		for p in CombatHelpers.particles:
			var life := float(p.get("life", 0))
			var a := clampf(life / 26.0, 0.0, 1.0)
			ctx.global_alpha(a)
			ctx.fill_style(str(p.get("c", "#ff8ac0")))
			ctx.begin_path()
			ctx.arc(float(p.get("x", 0)), float(p.get("y", 0)), 2.2, 0, TAU)
			ctx.fill()
		ctx.global_alpha(1.0)
		# score texts
		for s in CombatHelpers.score_texts:
			var life2 := float(s.get("life", 0))
			ctx.global_alpha(clampf(life2 / 44.0, 0.0, 1.0))
			ctx.fill_style(str(s.get("color", "#fff")))
			ctx.font("bold 14px Trebuchet MS")
			ctx.text_align("center")
			ctx.fill_text(str(s.get("txt", "")), float(s.get("x", 0)), float(s.get("y", 0)))
		ctx.global_alpha(1.0)
		ctx.text_align("left")
		# flash banner
		if CombatHelpers.flash_msg.has("txt") and float(CombatHelpers.flash_msg.get("t", 0)) > 0.0:
			var ft := float(CombatHelpers.flash_msg.get("t", 0))
			ctx.global_alpha(minf(1.0, ft / 20.0))
			ctx.fill_style("#ffe08a")
			ctx.font("900 20px Trebuchet MS")
			ctx.text_align("center")
			var pf: Rect2 = Config.playfield()
			ctx.fill_text(str(CombatHelpers.flash_msg.get("txt", "")), pf.get_center().x, pf.position.y + 36)
			ctx.text_align("left")
			ctx.global_alpha(1.0)

	# world items + floaters + burns
	if ItemSystem and item_draw:
		item_draw.set_tick(tick)
		for it in ItemSystem.items:
			item_draw.drawItem(it)
		for f in ItemSystem.floaters:
			_draw_floater(f)
		for bn in ItemSystem.burns:
			_draw_burn(bn)
	_draw_specials()
	# HTML drawFx specials (laser / blackhole / tentacle / etc.)
	if ported and ported.has_method("draw_fx"):
		ported.set_tick(tick)
		ported.draw_fx()
	# HTML drawMeleeFx (rings, bolts, charge meter)
	var player := get_tree().get_first_node_in_group("player")
	if ported and ported.has_method("draw_melee_fx"):
		var mfx: Array = []
		if CombatHelpers:
			mfx = CombatHelpers.melee_fx.duplicate()
		if player and player.get("melee") != null:
			var melee = player.melee
			if melee and melee.has_method("get_swipe_fx"):
				for f in melee.get_swipe_fx():
					mfx.append(f)
		ported.draw_melee_fx(mfx, player)
	elif player and player.get("melee") != null:
		var melee2 = player.melee
		if melee2 and melee2.has_method("get_swipe_fx"):
			for f2 in melee2.get_swipe_fx():
				_draw_swipe(f2)

func _draw_swipe(f: Dictionary) -> void:
	if combat_fx == null:
		return
	var life := float(f.get("life", 0))
	var t := float(f.get("t", 0))
	var a := clampf(life / 16.0, 0.0, 1.0)
	var dir := float(f.get("dir", -PI / 2.0))
	var reach := float(f.get("reach", 120))
	var half := float(f.get("half", 1.0))
	var col := str(f.get("col", "#ff2b4d"))
	var key := str(f.get("key", "katana"))
	var charge := float(f.get("charge", 0))
	var ox := float(f.get("x", 0))
	var oy := float(f.get("y", 0))
	# arc trail
	ctx.global_alpha(0.35 * a)
	ctx.stroke_style(col)
	ctx.line_width(3.0 + charge * 4.0)
	ctx.begin_path()
	var steps := 12
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		var ang := dir - half + u * half * 2.0
		var px := ox + cos(ang) * reach * (0.55 + 0.45 * a)
		var py := oy + sin(ang) * reach * (0.55 + 0.45 * a)
		if i == 0:
			ctx.move_to(px, py)
		else:
			ctx.line_to(px, py)
	ctx.stroke()
	# weapon blade at leading edge
	var ang2 := dir + half * (1.0 - a * 0.5)
	ctx.global_alpha(a)
	ctx.save()
	ctx.translate(ox + cos(ang2) * 18.0, oy + sin(ang2) * 18.0)
	ctx.rotate(ang2)
	combat_fx.draw_melee_weapon(key, reach * 0.55, col, charge)
	ctx.restore()
	ctx.global_alpha(1.0)


func _draw_floater(f: Dictionary) -> void:
	var life = float(f.get("life", 0))
	ctx.global_alpha(maxf(0.0, life / 30.0))
	var s = float(f.get("scale", 0.7)) * 46.0
	var tex = AssetBank.get_tex("confused") if AssetBank else null
	if tex:
		ctx.draw_image(tex, float(f.x) - s / 2.0, float(f.y) - s / 2.0, s, s)
	else:
		ctx.fill_style("#5a3d2b")
		ctx.begin_path()
		ctx.arc(float(f.x), float(f.y), s / 2.0, 0, TAU)
		ctx.fill()
	ctx.global_alpha(1.0)

func _draw_burn(bn: Dictionary) -> void:
	var lifeF = float(bn.life) / maxf(1.0, float(bn.get("max", bn.life)))
	var a0 = float(bn.dir) - float(bn.half)
	var a1 = float(bn.dir) + float(bn.half)
	ctx.save()
	ctx.global_composite_operation("lighter")
	ctx.translate(float(bn.x), float(bn.y))
	ctx.fill_style("rgba(255,140,50,%s)" % str(0.16 * lifeF))
	ctx.begin_path()
	ctx.move_to(0, 0)
	# cone arc
	var r = float(bn.reach)
	var steps = 16
	for i in range(steps + 1):
		var u = float(i) / float(steps)
		var ang = a0 + (a1 - a0) * u
		var px = cos(ang) * r
		var py = sin(ang) * r
		ctx.line_to(px, py)
	ctx.close_path()
	ctx.fill()
	ctx.restore()


func _draw_specials() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.get("specials") == null:
		return
	var sp = player.specials
	if sp == null or not ("fx" in sp):
		return
	if ported and ported.has_method("set_tick"):
		ported.set_tick(tick)
	for f in sp.fx:
		var typ = str(f.get("type", ""))
		var life = float(f.get("t", 0))
		if typ == "mech" and ported:
			var fade = clampf(life / 40.0, 0.0, 1.0) * clampf((240.0 - life) / 20.0, 0.0, 1.0) if life < 240 else 1.0
			# simpler alpha
			var alpha = clampf(life / 30.0, 0.0, 1.0)
			if life > 210:
				alpha = clampf((240.0 - life) / 30.0, 0.0, 1.0)
			ported.draw_mech(float(f.get("x", 0)), float(f.get("y", 0)), alpha, 0.0)
		elif typ == "bearzooka" and ported:
			var alpha2 = clampf(life / 20.0, 0.0, 1.0)
			if life > 130:
				alpha2 = clampf((156.0 - life) / 20.0, 0.0, 1.0)
			ported.draw_bobo(float(f.get("x", 0)), float(f.get("y", 0)), 1.1, true)
		elif typ == "kiss":
			ctx.global_alpha(clampf(life / 48.0, 0.0, 0.6))
			ctx.fill_style("#ff6ec7")
			ctx.begin_path()
			ctx.arc(float(f.get("x", 0)), float(f.get("y", 0)), float(f.get("r", 40)), 0, TAU)
			ctx.fill()
			ctx.global_alpha(1.0)
