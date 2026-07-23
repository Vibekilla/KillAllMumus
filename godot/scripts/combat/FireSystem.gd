extends Node
## 1:1 port of HTML fire() + optionShot + weapon shot types.

const FRAME := 60.0
const TEAM_PLAYER := 0

var tick: int = 0
var fire_cd_frames: float = 0.0

func reset_run() -> void:
	## Clear fire cooldown at run start (HTML p.cd = 0)
	tick = 0
	fire_cd_frames = 0.0

func _process(delta: float) -> void:
	if GameState.state == GameState.State.PLAY:
		tick += 1
	fire_cd_frames = maxf(0.0, fire_cd_frames - delta * FRAME)

func shot_level() -> int:
	return CombatHelpers.shot_level() if CombatHelpers else clampi(int(floor(GameState.power)), 1, 5)

func aim_angle(player: Node2D) -> float:
	return CombatHelpers.aim_angle(player) if CombatHelpers else (-PI / 2.0)

func fire_rate_frames(wep: String, focus: bool, player: Node = null) -> float:
	# HTML: p.cd = (p.focus ? 4 : 6) * (rapidT>0 ? 0.5 : 1) * (grenade ? 3.2 : 1)
	var base = 4.0 if focus else 6.0
	var wcd = 3.2 if wep == "grenade" else 1.0
	var rapid = 1.0
	if player != null and float(player.get("rapid_t")) > 0.0:
		rapid = 0.5
	return base * wcd * rapid

func try_fire(player: Node2D, pool: Node, focus: bool) -> bool:
	if pool == null or player == null:
		return false
	if fire_cd_frames > 0.0:
		return false
	var wep = GameState.current_weapon
	fire_cd_frames = fire_rate_frames(wep, focus, player)
	_fire(player, pool, wep, focus)
	# options / familiars
	var lv = shot_level()
	var aim = aim_angle(player)
	for o in option_offsets(lv):
		var q = option_pos(player, o)
		option_shot(pool, q.x + cos(aim) * 4.0, q.y + sin(aim) * 4.0, aim, wep)
	return true

func _fire(player: Node2D, pool: Node, wep: String, focus: bool) -> void:
	var ppos: Vector2 = player.global_position
	var lv = shot_level()
	var aim = aim_angle(player)
	var shot = func(off: float, spd: float, dmg: float, extra: Dictionary = {}):
		var a = aim + off
		var pos = ppos + Vector2(cos(a), sin(a)) * 10.0
		var vel = Vector2(cos(a), sin(a)) * spd * FRAME
		_spawn_pshot(pool, pos, vel, dmg, extra)

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
			var pos = ppos + perp * lat + cax * 8.0
			_spawn_pshot(pool, pos, cax * 20.0 * FRAME, 2.0, {"gat": true})
	elif wep == "grenade":
		var n4 = 3 if lv >= 5 else (2 if lv >= 4 else 1)
		for i in n4:
			var off = (float(i) - float(n4 - 1) * 0.5) * 0.16
			shot.call(off, 7.0 + lv * 0.4, 2.0 + floor(float(lv) / 2.0), {"nade": true, "life": 30.0 + lv * 3.0})
	elif wep == "voidripper":
		var lanes = mini(5, 1 + int(floor(float(lv) / 1.2)))
		var perp2 = Vector2(-sin(aim), cos(aim))
		var cax2 = Vector2(cos(aim), sin(aim))
		for i in lanes:
			var lat = (float(i) - float(lanes - 1) * 0.5) * 18.0
			var pos = ppos + perp2 * lat + cax2 * 8.0
			_spawn_pshot(pool, pos, cax2 * 15.0 * FRAME, 3.0 + lv, {"vrip": true, "pierce": true})
	elif wep == "lotus":
		var n5 = 6 + lv * 2
		var spread = 1.5 + lv * 0.4
		for i in n5:
			var off = (float(i) - float(n5 - 1) * 0.5) * (spread / maxf(1.0, float(n5 - 1)))
			shot.call(off, 6.2 + randf() * 1.4, 1.0, {"petal": true, "curl": (-1.0 if off < 0.0 else 1.0) * 0.03, "life": 62.0})
	elif wep == "shock":
		var n6 = 2 + lv
		for i in n6:
			var off = randf_range(-0.5, 0.5) * (0.55 + lv * 0.09)
			shot.call(off, 13.0 + randf() * 5.0, 2.0, {"zap": true})
	else:
		# spread (default Emblem Amulets)
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
			for off in spreadA:
				shot.call(float(off), 13.0, 1.0)
			if lv >= 4:
				shot.call(-0.5, 9.0, 1.0, {"home": true})
				shot.call(0.5, 9.0, 1.0, {"home": true})

func option_offsets(lv: int) -> Array:
	# HTML optionOffsets — familiars unlock with power
	if lv <= 1:
		return []
	if lv == 2:
		return [{"x": -28.0, "y": 8.0}, {"x": 28.0, "y": 8.0}]
	if lv == 3:
		return [{"x": -32.0, "y": 6.0}, {"x": 32.0, "y": 6.0}, {"x": 0.0, "y": 22.0}]
	return [{"x": -36.0, "y": 4.0}, {"x": 36.0, "y": 4.0}, {"x": -18.0, "y": 20.0}, {"x": 18.0, "y": 20.0}]

func option_pos(player: Node2D, o: Dictionary) -> Vector2:
	return player.global_position + Vector2(float(o.get("x", 0)), float(o.get("y", 0)))

func option_shot(pool: Node, x: float, y: float, aim: float, wep: String) -> void:
	var extra = {}
	var spd = 13.0
	var dmg = 1.0
	var off = 0.0
	match wep:
		"laser":
			spd = 17.0
			extra = {"laser": true}
		"homing":
			spd = 6.0
			extra = {"home": true}
		"wave":
			spd = 11.0
			extra = {"wv": 3.2, "wph": float(tick) * 0.4}
		"scatter":
			off = randf_range(-0.07, 0.07)
			spd = 10.0 + randf() * 3.0
			extra = {"life": 22.0}
		"gatling":
			spd = 19.0
			dmg = 2.0
			extra = {"gat": true}
		"grenade":
			spd = 8.0
			dmg = 3.0
			extra = {"nade": true, "life": 32.0}
		"voidripper":
			spd = 15.0
			dmg = 2.0
			extra = {"vrip": true, "pierce": true}
		"lotus":
			off = randf_range(-0.35, 0.35)
			spd = 7.0
			extra = {"petal": true, "curl": (-1.0 if off < 0.0 else 1.0) * 0.035, "life": 58.0}
		"shock":
			off = randf_range(-0.25, 0.25)
			spd = 13.0 + randf() * 4.0
			dmg = 2.0
			extra = {"zap": true}
		_:
			spd = 13.0
	var a = aim + off
	_spawn_pshot(pool, Vector2(x, y), Vector2(cos(a), sin(a)) * spd * FRAME, dmg, extra)

func _spawn_pshot(pool: Node, pos: Vector2, vel: Vector2, dmg: float, extra: Dictionary) -> void:
	var c = _weapon_color(GameState.current_weapon)
	if extra.get("laser", false):
		c = Color("ff3b5c")
	elif extra.get("gat", false):
		c = Color("7ed957")
	elif extra.get("vrip", false):
		c = Color("9d6bff")
	elif extra.get("petal", false):
		c = Color("ff8ac0")
	elif extra.get("zap", false):
		c = Color("8fd0ff")
	elif extra.get("nade", false):
		c = Color("b6e34a")
	elif extra.get("home", false):
		c = Color("ffe14a")
	elif extra.get("wv", false):
		c = Color("7ed957")
	var b = pool.spawn(pos, vel, dmg, c, TEAM_PLAYER)
	if b and b.has_method("set_props"):
		var props = extra.duplicate()
		props["pshot"] = true
		b.set_props(props)

func _weapon_color(wep: String) -> Color:
	var w: Dictionary = DataRegistry.get_weapon(wep)
	if w.has("col"):
		return Color.html(str(w["col"]))
	return Color(1.0, 0.75, 0.85)
