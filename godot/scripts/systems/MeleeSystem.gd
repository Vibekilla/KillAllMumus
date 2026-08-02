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
	var origin := player.global_position
	for e in player.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var dx: float = e.global_position.x - origin.x
		var dy: float = e.global_position.y - origin.y
		var d: float = sqrt(dx * dx + dy * dy)
		var er: float = float(e.get("radius")) if e.get("radius") != null else 15.0
		var is_boss := e.is_in_group("bosses")
		var half_hit := half + (0.3 if is_boss else 0.25)
		if d < reach + er and _ang_diff(atan2(dy, dx), dir) < half_hit:
			hit_any = true
			if e.has_method("take_damage"):
				e.take_damage(dmg)
			if "flash" in e:
				e.flash = 4.0 if is_boss else 6.0
			var nx: float = dx / d if d > 0.5 else 0.0
			var ny: float = dy / d if d > 0.5 else -1.0
			# HTML: mobs kb*2.2; boss kb*0.5
			var kbm := 0.5 if is_boss else 2.2
			e.global_position += Vector2(nx, ny) * kb * kbm
			if not is_boss and CombatHelpers:
				for s in range(5):
					CombatHelpers.particles.append({
						"x": e.global_position.x, "y": e.global_position.y,
						"vx": nx * 3.0 + (randf() - 0.5) * 5.0,
						"vy": ny * 3.0 + (randf() - 0.5) * 5.0,
						"life": 15.0, "c": col if s % 2 == 0 else "#fff",
					})
			if not is_boss and float(e.get("hp")) <= 0.0:
				mkills += 1
				ProgressStore.estats_add("mkills", 1)

	# cancel / shove enemy bullets
	var pool: Variant = player.get("bullet_pool")
	if pool != null and pool.has_method("melee_deflect"):
		pool.melee_deflect(origin, dir, reach, half, cancel)

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

	# swipe sparkle particles
	if CombatHelpers:
		var n_part := 12 + int(ch * 12.0)
		for i in range(n_part):
			var a := dir - half + randf() * float(m.get("arc", half * 2.0))
			var rr := reach * (0.45 + randf() * 0.55)
			CombatHelpers.particles.append({
				"x": origin.x + cos(a) * rr, "y": origin.y + sin(a) * rr,
				"vx": cos(a) * 2.0 + (randf() - 0.5), "vy": sin(a) * 2.0 + (randf() - 0.5),
				"life": 12.0 + randf() * 8.0, "c": col if i % 2 == 0 else "#fff",
			})

	cooldown = float(m.get("cd", 18))
	if hit_any:
		melee_hit.emit(dmg)
		# HTML: mweps bitfield per melee index → melee_all
		var mi := 0
		if DataRegistry:
			for i in range(DataRegistry.melee.size()):
				if str(DataRegistry.melee[i].get("key", "")) == melee_key:
					mi = i
					break
		var mweps := int(ProgressStore.estats.get("mweps", 0))
		mweps = mweps | (1 << mi)
		ProgressStore.estats["mweps"] = mweps
		ProgressStore.progress["estats"] = ProgressStore.estats
		var n_melee := DataRegistry.melee.size() if DataRegistry else 5
		var all_mask := (1 << n_melee) - 1
		if (mweps & all_mask) == all_mask:
			ProgressStore.unlock_emblem("melee_all")
	if mkills > 0:
		ProgressStore.unlock_emblem("melee_first")
		if int(ProgressStore.estats.get("mkills", 0)) >= 300:
			ProgressStore.unlock_emblem("melee_slayer")
	charge = 0.0

func melee_charge_fx(player: Node2D, m: Dictionary, dir: float, reach: float, half: float, dmg: float, kb: float) -> void:
	## HTML meleeChargeFx
	_charge_fx(player, m, dir, reach, half, dmg, kb)

func _charge_fx(player: Node2D, m: Dictionary, dir: float, reach: float, half: float, dmg: float, kb: float) -> void:
	var fx := str(m.get("fx", "flame"))
	var origin := player.global_position
	match fx:
		"flame":
			# HTML: burns only (no extra hit) — half+0.15, reach*1.05, life 78
			ItemSystem.add_burn(origin.x, origin.y, dir, reach * 1.05, half + 0.15, str(m.get("col", "#ff7a2a")), 78.0)
			if AudioBus:
				AudioBus.sfx("bomb")
		"chain":
			# Prefer melee col for bolt; HTML uses m.col
			var ccol := str(m.get("col", "#b06cff"))
			ItemSystem.chain_lightning(origin.x, origin.y, dmg, 6, ccol)
			if AudioBus:
				AudioBus.sfx("graze")
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
			# HTML: hurl a moving black hole (SpecialSystem.fx updates pull)
			var colb := str(m.get("col", "#3ae66a"))
			var bh := {
				"type": "blackhole", "t": 96.0, "dt": 0.0,
				"x": origin.x + cos(dir) * 18.0,
				"y": origin.y + sin(dir) * 18.0,
				"vx": cos(dir) * 5.5, "vy": sin(dir) * 5.5,
				"r": 0.0, "col": colb,
			}
			if player.get("specials") != null and player.specials.get("fx") is Array:
				player.specials.fx.append(bh)
			if AudioBus:
				AudioBus.sfx("whip")
				AudioBus.sfx("power")
		"shockwall":
			# HTML: ring FX + fling + stun 70 + vaporize bullets in reach*1.2
			if CombatHelpers and "melee_fx" in CombatHelpers:
				CombatHelpers.melee_fx.append({
					"ring": true, "x": origin.x, "y": origin.y,
					"r0": reach * 0.4, "r1": reach * 1.6,
					"col": str(m.get("col", "#ffd27a")), "life": 22.0, "t": 0.0,
				})
			for e in player.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.is_in_group("bosses"):
					continue
				var to2: Vector2 = e.global_position - origin
				if to2.length() < reach * 1.4:
					var sx: float = 1.0 if to2.x >= 0.0 else -1.0
					var sy: float = 1.0 if to2.y >= 0.0 else -1.0
					# HTML: e.vx/vy px/frame, e.flung=44, e.stun=70 — fly until wall detonate
					if "flung" in e:
						e.flung = 44.0
					else:
						e.set("flung", 44.0)
					if "flung_vel" in e:
						e.flung_vel = Vector2(sx * (13.0 + randf() * 4.0), sy * (3.0 + randf() * 3.0))
					else:
						e.set("flung_vel", Vector2(sx * (13.0 + randf() * 4.0), sy * (3.0 + randf() * 3.0)))
					if "stun" in e:
						e.stun = maxf(float(e.stun), 70.0)
					else:
						e.set("stun", 70.0)
			var pool2: Variant = player.get("bullet_pool")
			var vap: int = 0
			var rc: int = 0
			if pool2 != null:
				for b in pool2.iter_active() if pool2.has_method("iter_active") else []:
					if not is_instance_valid(b) or int(b.team) != 1:
						continue
					if b.global_position.distance_to(origin) < reach * 1.2:
						vap += 1
						if ItemSystem:
							ItemSystem.floaters.append({
								"x": b.global_position.x, "y": b.global_position.y,
								"life": 14.0, "vy": -0.5, "scale": 0.34,
							})
							if rc < 44:
								ItemSystem.drop_item(b.global_position.x, b.global_position.y, "point")
								rc += 1
						b.deactivate()
			if vap >= 20:
				ProgressStore.unlock_emblem("melee_shock")
			if CombatHelpers:
				CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 8.0)
			if AudioBus:
				AudioBus.sfx("bomb")
		"flurry":
			# HTML: p.flurry=30; p.flurryDir=dir; p.flurryDmg=max(1,round(dmg*0.5))
			if "flurry" in player:
				player.flurry = 30.0
			else:
				player.set("flurry", 30.0)
			if "flurry_dir" in player:
				player.flurry_dir = dir
			else:
				player.set("flurry_dir", dir)
			if "flurry_dmg" in player:
				player.flurry_dmg = maxf(1.0, round(dmg * 0.5))
			else:
				player.set("flurry_dmg", maxf(1.0, round(dmg * 0.5)))
			if AudioBus:
				AudioBus.sfx("slash")

func _ang_diff(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))

func _def(key: String) -> Dictionary:
	for m in DataRegistry.melee:
		if str(m.get("key", "")) == key:
			return m
	return DataRegistry.melee[0] if DataRegistry.melee.size() else {}

func get_swipe_fx() -> Array:
	return swipe_fx
