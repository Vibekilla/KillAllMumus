extends Node
## HTML doMeleeSwipe + charged signature FX parity.

signal melee_hit(damage: float)

var cooldown: float = 0.0  # frames
var charge: float = 0.0
var holding: bool = false
var swipe_fx: Array = []

const FRAME := 60.0

func tick(delta: float) -> void:
	var df := delta * FRAME
	cooldown = maxf(0.0, cooldown - df)
	if holding:
		charge = minf(1.0, charge + delta * 0.85)
	else:
		charge = maxf(0.0, charge - delta * 2.0)
	# HTML: f.t++; filter f.t < f.life (life is fixed duration, t is elapsed)
	var keep: Array = []
	for f in swipe_fx:
		f["t"] = float(f.get("t", 0)) + df
		var life := float(f.get("life", 16))
		if float(f["t"]) < life:
			keep.append(f)
	swipe_fx = keep

func begin_hold() -> void:
	holding = true

func release(player: Node2D, melee_key: String, dir: float = -PI / 2.0) -> void:
	holding = false
	if cooldown > 0.0:
		charge = 0.0
		return
	var m := _def(melee_key)
	var ch := minf(1.0, charge)
	var pw := 0.55 + ch * 0.85
	var reach: float = float(m.get("reach", 155)) * pw
	var kb: float = float(m.get("kb", 5)) * pw
	var dmg: float = maxf(1.0, round(float(m.get("dmg", 6)) * pw))
	var half: float = float(m.get("arc", 2.0)) * 0.5
	var cancel := ch > 0.6
	var col := str(m.get("col", "#ff2b4d"))

	swipe_fx.append({
		"x": player.global_position.x, "y": player.global_position.y,
		"dir": dir, "reach": reach, "half": half, "col": col,
		"key": str(m.get("key", melee_key)), "life": 16.0, "t": 0.0, "charge": ch,
	})

	var mkills := 0
	var hit_any := false
	for e in player.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var dx: float = e.global_position.x - player.global_position.x
		var dy: float = e.global_position.y - player.global_position.y
		var d: float = sqrt(dx * dx + dy * dy)
		var er: float = float(e.get("radius")) if e.get("radius") != null else 15.0
		if d < reach + er and _ang_diff(atan2(dy, dx), dir) < half + 0.25:
			hit_any = true
			if e.has_method("take_damage"):
				e.take_damage(dmg)
			var nx: float = dx / d if d > 0.5 else 0.0
			var ny: float = dy / d if d > 0.5 else -1.0
			e.global_position += Vector2(nx, ny) * kb * 2.2
			if float(e.get("hp")) <= 0.0:
				mkills += 1

	# cancel / shove enemy bullets
	var pool: Variant = player.get("bullet_pool")
	if pool != null and pool.has_method("melee_deflect"):
		pool.melee_deflect(player.global_position, dir, reach, half, cancel)

	if ch >= 0.85:
		melee_charge_fx(player, m, dir, reach, half, dmg, kb)

	# HTML: screenShake + sfx(m.snd||'kill') + sfx('graze')
	if CombatHelpers:
		CombatHelpers.screen_shake = maxf(
			CombatHelpers.screen_shake,
			2.5 + ch * 5.0 + (float(m.get("kb", 5)) / 9.0) * 2.5
		)
	if AudioBus:
		AudioBus.sfx(str(m.get("snd", "slash")))
		AudioBus.sfx("graze")

	cooldown = float(m.get("cd", 18))
	if hit_any:
		melee_hit.emit(dmg)
		if mkills > 0:
			ProgressStore.unlock_emblem("melee_first")
	charge = 0.0

func melee_charge_fx(player: Node2D, m: Dictionary, dir: float, reach: float, half: float, dmg: float, kb: float) -> void:
	## HTML meleeChargeFx
	_charge_fx(player, m, dir, reach, half, dmg, kb)

func _charge_fx(player: Node2D, m: Dictionary, dir: float, reach: float, half: float, dmg: float, kb: float) -> void:
	var fx := str(m.get("fx", "flame"))
	var origin := player.global_position
	match fx:
		"flame":
			ItemSystem.add_burn(origin.x, origin.y, dir, reach * 1.1, half + 0.3, str(m.get("col", "#ff7a2a")), 90.0)
			for e in player.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e):
					continue
				var to: Vector2 = e.global_position - origin
				if to.length() < reach * 1.1 and _ang_diff(to.angle(), dir) < half + 0.3:
					if e.has_method("take_damage"):
						e.take_damage(dmg * 0.5)
		"chain":
			# Prefer melee col for bolt; HTML uses m.col
			var ccol := str(m.get("col", "#b06cff"))
			ItemSystem.chain_lightning(origin.x, origin.y, dmg, 6, ccol)
			# If field empty (dual stills / no targets), still show a whip-chain path
			var has_bolt := false
			for f in swipe_fx:
				if f is Dictionary and bool(f.get("bolt", false)):
					has_bolt = true
					break
			if not has_bolt:
				# Decorative chain for empty-field / dual stills — fan of zigzags up-aim
				var pts: Array = [{"x": origin.x, "y": origin.y}]
				var cx := origin.x
				var cy := origin.y
				var base := dir
				for j in range(6):
					var side := 1.0 if (j % 2 == 0) else -1.0
					cx = origin.x + cos(base) * (36.0 + float(j) * 26.0) + side * (18.0 + float(j) * 4.0)
					cy = origin.y + sin(base) * (36.0 + float(j) * 26.0)
					pts.append({"x": cx, "y": cy})
				var bolt2 := {"bolt": true, "pts": pts, "col": ccol, "life": 14.0, "t": 0.0}
				swipe_fx.append(bolt2)
				if CombatHelpers and "melee_fx" in CombatHelpers:
					CombatHelpers.melee_fx.append(bolt2.duplicate(true))
		"blackhole":
			# pull nearby
			for e in player.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.is_in_group("bosses"):
					continue
				var d: float = origin.distance_to(e.global_position)
				if d < reach * 1.4 and d > 1.0:
					e.global_position += (origin - e.global_position).normalized() * minf(40.0, 80.0 / d)
		"shockwall":
			for e in player.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.is_in_group("bosses"):
					continue
				var to: Vector2 = e.global_position - origin
				if to.length() < reach * 1.2:
					e.global_position += to.normalized() * kb * 4.0
					e.set("stun", 40.0)
		"flurry":
			for e in player.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e):
					continue
				var to: Vector2 = e.global_position - origin
				if to.length() < reach * 1.15 and _ang_diff(to.angle(), dir) < half + 0.4:
					if e.has_method("take_damage"):
						e.take_damage(dmg * 1.8)

func _ang_diff(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))

func _def(key: String) -> Dictionary:
	for m in DataRegistry.melee:
		if str(m.get("key", "")) == key:
			return m
	return DataRegistry.melee[0] if DataRegistry.melee.size() else {}

func get_swipe_fx() -> Array:
	return swipe_fx
