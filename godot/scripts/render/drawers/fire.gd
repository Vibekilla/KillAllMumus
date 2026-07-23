extends RefCounted
## 1:1 port of HTML fire() — delegates to FireSystem when available,
## otherwise mirrors the weapon shot table for headless/preview use.

var ctx
var tick: int = 0

func setup(c = null) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func fire(player: Node2D = null, pool: Node = null, focus: bool = false) -> void:
	## HTML fire()
	# Prefer live FireSystem on the player
	if player and player.get("fire_sys") != null:
		var fs = player.fire_sys
		if fs and fs.has_method("try_fire"):
			if fs.try_fire(player, pool if pool else player.get("bullet_pool"), focus):
				if AudioBus:
					AudioBus.sfx("shoot")
			return
	# Standalone table (parity with HTML fire + FireSystem._fire)
	if player == null or pool == null:
		return
	if not pool.has_method("spawn_player") and not pool.has_method("spawn"):
		return
	_fire_table(player, pool, focus)
	if AudioBus:
		AudioBus.sfx("shoot")

func _fire_table(player: Node2D, pool: Node, focus: bool) -> void:
	var ppos: Vector2 = player.global_position
	var lv = CombatHelpers.shot_level() if CombatHelpers else clampi(int(floor(GameState.power)), 1, 5)
	var aim = CombatHelpers.aim_angle(player) if CombatHelpers else float(player.get("aim") if player.get("aim") != null else -PI / 2.0)
	var wep = GameState.current_weapon
	var shot = func(off: float, spd: float, dmg: float, extra: Dictionary = {}):
		var a = aim + off
		var pos = ppos + Vector2(cos(a), sin(a)) * 10.0
		var vel = Vector2(cos(a), sin(a)) * spd * 60.0
		_spawn(pool, pos, vel, dmg, extra)

	if wep == "laser":
		if focus:
			shot.call(0.0, 20.0, 3.0, {"foc": true, "laser": true})
			if lv >= 2:
				shot.call(-0.05, 20.0, 2.0, {"laser": true})
				shot.call(0.05, 20.0, 2.0, {"laser": true})
		else:
			var n = mini(5, 1 + lv)
			for i in n:
				shot.call((float(i) - float(n - 1) * 0.5) * 0.06, 18.0, 2.0, {"laser": true})
	elif wep == "homing":
		var n2 = lv + 1
		for i in n2:
			shot.call((float(i) - float(n2 - 1) * 0.5) * 0.42, 6.0, 1.0, {"home": true})
	elif wep == "wave":
		var ph = float(tick) * 0.4
		shot.call(0.0, 11.0, 1.0, {"wv": 2.6 + lv * 0.4, "wph": ph})
		shot.call(0.0, 11.0, 1.0, {"wv": 2.6 + lv * 0.4, "wph": ph + PI})
		if lv >= 3:
			shot.call(0.0, 11.0, 1.0, {"wv": 4.0 + lv * 0.4, "wph": ph + PI * 0.5})
	elif wep == "scatter":
		var n3 = 3 + lv * 2
		for i in n3:
			var off = (float(i) - float(n3 - 1) * 0.5) * 0.14 + randf_range(-0.03, 0.03)
			shot.call(off, 10.0 + randf() * 3.0, 1.0, {"life": 22.0})
	elif wep == "gatling":
		var barrels = mini(5, 2 + int(floor(float(lv) / 1.5)))
		var perp = Vector2(-sin(aim), cos(aim))
		var cax = Vector2(cos(aim), sin(aim))
		for b in barrels:
			var lat = (float(b) - float(barrels - 1) * 0.5) * 6.0 + sin(float(tick) * 0.9 + float(b) * 1.6) * 2.6
			_spawn(pool, ppos + perp * lat + cax * 8.0, cax * 20.0 * 60.0, 2.0, {"gat": true})
	elif wep == "grenade":
		var n4 = 3 if lv >= 5 else (2 if lv >= 4 else 1)
		for i in n4:
			var off2 = (float(i) - float(n4 - 1) * 0.5) * 0.16
			shot.call(off2, 7.0 + lv * 0.4, 2.0 + floor(float(lv) / 2.0), {"nade": true, "life": 30.0 + lv * 3.0})
		if AudioBus:
			AudioBus.sfx("thud")
	elif wep == "voidripper":
		var lanes = mini(5, 1 + int(floor(float(lv) / 1.2)))
		var perp2 = Vector2(-sin(aim), cos(aim))
		var cax2 = Vector2(cos(aim), sin(aim))
		for i in lanes:
			var lat2 = (float(i) - float(lanes - 1) * 0.5) * 18.0
			_spawn(pool, ppos + perp2 * lat2 + cax2 * 8.0, cax2 * 15.0 * 60.0, 3.0 + lv, {"vrip": true, "pierce": true})
	elif wep == "lotus":
		var n5 = 6 + lv * 2
		var spread = 1.5 + lv * 0.4
		for i in n5:
			var off3 = (float(i) - float(n5 - 1) * 0.5) * (spread / maxf(1.0, float(n5 - 1)))
			shot.call(off3, 6.2 + randf() * 1.4, 1.0, {"petal": true, "curl": (-1.0 if off3 < 0.0 else 1.0) * 0.03, "life": 62.0})
	elif wep == "shock":
		var n6 = 2 + lv
		for i in n6:
			shot.call(randf_range(-0.5, 0.5) * (0.55 + lv * 0.09), 13.0 + randf() * 5.0, 2.0, {"zap": true})
	else:
		if focus:
			var n7 = 1 + lv
			for i in n7:
				shot.call((float(i) - float(n7 - 1) * 0.5) * 0.05, 16.0, 2.0, {"foc": true})
		else:
			var table = [
				[0.0],
				[-0.13, 0.13],
				[-0.2, 0.0, 0.2],
				[-0.26, -0.09, 0.09, 0.26],
				[-0.32, -0.14, 0.0, 0.14, 0.32],
			]
			var spreadA: Array = table[clampi(lv - 1, 0, 4)]
			for off4 in spreadA:
				shot.call(float(off4), 13.0, 1.0)
			if lv >= 4:
				shot.call(-0.5, 9.0, 1.0, {"home": true})
				shot.call(0.5, 9.0, 1.0, {"home": true})
	# option familiars
	for o in _option_offsets(lv):
		var q = ppos + Vector2(float(o.get("x", 0)), float(o.get("y", 0)))
		_spawn(pool, q + Vector2(cos(aim), sin(aim)) * 4.0, Vector2(cos(aim), sin(aim)) * 13.0 * 60.0, 1.0, {})

func _option_offsets(lv: int) -> Array:
	if lv <= 1:
		return []
	if lv == 2:
		return [{"x": -28.0, "y": 8.0}, {"x": 28.0, "y": 8.0}]
	if lv == 3:
		return [{"x": -32.0, "y": 6.0}, {"x": 32.0, "y": 6.0}, {"x": 0.0, "y": 22.0}]
	return [{"x": -36.0, "y": 4.0}, {"x": 36.0, "y": 4.0}, {"x": -18.0, "y": 20.0}, {"x": 18.0, "y": 20.0}]

func _spawn(pool: Node, pos: Vector2, vel: Vector2, dmg: float, extra: Dictionary) -> void:
	if pool.has_method("spawn_player"):
		pool.spawn_player(pos, vel, dmg, extra)
	elif pool.has_method("spawn"):
		pool.spawn(pos, vel, dmg, extra)
