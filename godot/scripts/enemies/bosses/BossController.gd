extends Area2D
## Full HTML updateBoss + bossSpecial parity (all 7 stages).

signal defeated(boss_id: String)

const FRAME := 60.0
const BulletPatterns = preload("res://scripts/combat/BulletPatterns.gd")

var boss_id: String = ""
var portrait: String = ""
var max_hp: float = 100.0
var hp: float = 100.0
var bullet_pool: Node
var data: Dictionary = {}
var t: int = 0
var phase: int = 0
var phases: int = 3
var spin: float = 0.0
var intro: float = 90.0
var dead: bool = false
var dead_t: float = 0.0
var flash: float = 0.0
var special_used: bool = false
var special_t: float = 0.0
var stun: float = 0.0
var radius: float = 36.0
var mtx: float = 0.0
var mty: float = 0.0
var dash: bool = false
var face: float = PI / 2.0
var px: float = 0.0
var py: float = 0.0
var twin: bool = false
var active_twin: String = "igor"
var tw: Dictionary = {}
var swap_cd: float = 0.0
var hud_name: String = ""
var color: Color = Color("c9a24b")
var ctx: RefCounted
var ported: RefCounted
## HTML Wynn hell portal sequence (startWynnHell / updateWynnHell)
var hell: bool = false
var hell_t: float = 0.0
var hell_done: float = 0.0
var hell_r: float = 0.0
var hell_spin: float = 0.0
var hell_scale: float = 1.0
var hell_shake: float = 0.0
var hy: float = 0.0

func _ready() -> void:
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	ported = load("res://scripts/render/PortedDraw.gd").new()
	ported.setup(ctx)

func setup(pool: Node, pos: Vector2, stage: Dictionary) -> void:
	bullet_pool = pool
	data = stage.get("boss", {})
	boss_id = str(data.get("name", "boss"))
	portrait = str(data.get("portrait", "ape"))
	hud_name = str(data.get("name", boss_id))
	max_hp = float(data.get("hp", 340)) * (1.0 + GameState.ng_plus * 0.08) * (1.15 if GameState.hard_mode else 1.0)
	hp = max_hp
	global_position = pos
	color = Color.html(str(data.get("color", "#c9a24b")))
	phases = 3 if GameState.stage_index > 0 else 2
	if portrait == "bogdanoff":
		twin = true
		special_used = true  # HTML: twins skip generic special phase
		phases = 1
		tw = {
			"igor": {"hp": max_hp, "max": max_hp, "done": false},
			"grichka": {"hp": max_hp, "max": max_hp, "done": false},
		}
		active_twin = "igor"
		hud_name = "Igor Bogdanoff"
	intro = 20.0 if GameState.speedrun else 90.0
	var pf: Rect2 = Config.playfield()
	mtx = pf.get_center().x
	mty = pf.position.y + 100
	add_to_group("enemies")
	add_to_group("bosses")

var _draw_age: int = 0

func _want_redraw() -> void:
	_draw_age += 1
	# Throttle redraw requests (was accidentally recursive)
	if _draw_age % 2 == 0:
		queue_redraw()

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	# Dual stills: freeze AI / face-tracking / patterns (godot-master: presentation doesn't thrash entity)
	if has_meta("dual_freeze") and bool(get_meta("dual_freeze")):
		_want_redraw()
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var pf: Rect2 = Config.playfield()

	if intro > 0.0:
		intro -= delta * FRAME
		position.y += (mty - position.y) * 0.06
		_want_redraw()
		return

	if hell:
		_update_wynn_hell(delta)
		_want_redraw()
		return

	if dead:
		dead_t += delta * FRAME
		# HTML: on first dead frame, rain power/point/life/bomb/fullpower
		if not has_meta("death_loot"):
			set_meta("death_loot", true)
			_drop_death_loot()
		if int(dead_t) % 3 == 0:
			# death burst visual via redraw flash
			flash = 4.0
		# Final boss (Wynn): HTML startWynnHell instead of instant clear
		if portrait == "wynn" and not hell and dead_t > 30.0:
			start_wynn_hell()
			_want_redraw()
			return
		if dead_t > 90.0:
			defeated.emit(boss_id)
			queue_free()
		_want_redraw()
		return

	t += 1
	if flash > 0.0:
		flash -= delta * FRAME
	if swap_cd > 0.0:
		swap_cd -= delta * FRAME

	# twin swap
	if twin and swap_cd <= 0.0:
		var other := "grichka" if active_twin == "igor" else "igor"
		if not bool(tw[other].get("done", false)) and hp > max_hp * 0.16 and t % 300 == 0 and randf() < 0.35:
			_twin_swap(other)

	# roam
	if t % 100 == 0:
		mtx = pf.position.x + 55 + randf() * (pf.size.x - 110)
		mty = pf.position.y + 55 + randf() * (pf.size.y - 135)
		dash = randf() < 0.34
	var ez := 0.055 if dash else 0.03
	position.x += (mtx - position.x) * ez + sin(float(t) * 0.05) * 0.5
	position.y += (mty - position.y) * ez + sin(float(t) * 0.033) * 0.4
	position.x = clampf(position.x, pf.position.x + 40, pf.end.x - 40)
	position.y = clampf(position.y, pf.position.y + 40, pf.end.y - 80)

	# body collision shove
	if p:
		var dp := p.global_position.distance_to(global_position)
		var near := radius + 12.0
		if dp < near and dp > 0.01:
			var nrm := (p.global_position - global_position) / dp
			p.global_position += nrm * (near - dp)
			p.global_position.x = clampf(p.global_position.x, pf.position.x + 8, pf.end.x - 8)
			p.global_position.y = clampf(p.global_position.y, pf.position.y + 8, pf.end.y - 8)

	var bvx := position.x - px
	var bvy := position.y - py
	px = position.x
	py = position.y
	var bface_t := atan2(bvy, bvx) if sqrt(bvx * bvx + bvy * bvy) > 0.4 else PI / 2.0
	face = lerp_angle(face, bface_t, 0.08)

	var cx := position.x
	var cy := position.y
	var s := GameState.stage_index
	var ph := phase
	var hm := (0.7 if GameState.hard_mode else 1.25) * (1.0 - mini(s, 3) * 0.07)

	if stun > 0.0:
		stun -= delta * FRAME
	elif special_t > 0.0:
		special_t -= delta * FRAME
		_boss_special(cx, cy, p)
	else:
		_patterns(s, ph, hm, cx, cy, p)

	# HTML: special at 45% HP — flashMsg, taunt dialog, bullet cancel, particles
	if not special_used and not twin and hp <= max_hp * 0.45:
		_trigger_boss_special()

	# phase transitions
	var per_phase := max_hp / float(phases)
	if hp <= max_hp - per_phase * float(phase + 1) and phase < phases - 1:
		phase += 1
		if bullet_pool:
			bullet_pool.clear_enemy()
		flash = 8.0
		if AudioBus:
			AudioBus.sfx("card")

func _trigger_boss_special() -> void:
	## HTML updateBoss specialUsed block
	special_used = true
	special_t = 200.0
	if bullet_pool:
		bullet_pool.clear_enemy()
	flash = 10.0
	if AudioBus:
		AudioBus.sfx("card")
	var sp_name := str(data.get("special", "SPECIAL"))
	if CombatHelpers:
		CombatHelpers.flash("★ SPECIAL: %s" % sp_name, 120.0)
	# Taunt dialog if present
	var taunt := str(data.get("taunt", ""))
	if taunt != "" and StageFlow and StageFlow.has_method("start_dialog") and StageFlow.dialog == null:
		StageFlow.start_dialog([{"w": 0, "t": taunt}], data)
	# Burst particles
	if CombatHelpers:
		var col := str(data.get("color", "#ffd27a"))
		for i in range(40):
			CombatHelpers.particles.append({
				"x": global_position.x, "y": global_position.y,
				"vx": (randf() - 0.5) * 11.0, "vy": (randf() - 0.5) * 11.0,
				"life": 34.0, "c": col,
			})


func _patterns(s: int, ph: int, hm: float, cx: float, cy: float, p: Node2D) -> void:
	if p == null:
		return
	var pxp := p.global_position.x
	var pyp := p.global_position.y
	if s == 0:
		if ph == 0:
			if t % maxi(1, int(floor(40 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 7, 1.0, 2.6, 7, "#e6c65a")
			if t % 90 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 16, 1.8, 6, "#c9a24b", float(t) * 0.05)
			if t % 150 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.0)
		else:
			spin += 0.3
			if t % 3 == 0:
				for a in 3:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 2.094, 2.4, 6, "#ffd27a")
			if t % 70 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 9, 1.2, 3.0, 6, "#e6c65a")
	elif s == 1:
		if ph == 0:
			if t % maxi(1, int(floor(46 * hm))) == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 20, 1.7, 6, "#8fd0ff", float(t) * 0.04)
			if t % 64 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 5, 0.7, 3.2, 7, "#7ea8ff")
		elif ph == 1:
			spin += 0.22
			if t % 3 == 0:
				for a in 4:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.5708, 2.2, 6, "#a0e0ff")
			if t % 140 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.2)
		else:
			if t % maxi(1, int(floor(30 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 11, 1.4, 3.4, 6, "#c7f0ff")
			if t % 100 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 24, 1.9, 5, "#8fd0ff", 0)
	elif s == 2:
		if ph == 0:
			if t % maxi(1, int(floor(42 * hm))) == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 18, 1.7, 6, "#7ed957", float(t) * 0.04)
			if t % 60 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 6, 0.8, 3.2, 7, "#bff58a")
		elif ph == 1:
			spin += 0.2
			if t % 3 == 0:
				for a in 5:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.2566, 2.2, 6, "#9ff06a")
			if t % 130 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.2)
		else:
			if t % maxi(1, int(floor(30 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 11, 1.5, 3.2, 6, "#d6ffa8")
			if t % 96 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 22, 1.9, 5, "#7ed957", 0)
	elif s == 3:
		if ph == 0:
			if t % maxi(1, int(floor(40 * hm))) == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 18, 1.8, 5, "#9945ff", float(t) * 0.05)
			if t % 54 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 7, 0.9, 3.4, 6, "#14f195")
		elif ph == 1:
			spin += 0.24
			if t % 2 == 0:
				for a in 4:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.5708, 2.6, 5, "#14f195")
			if t % 120 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.2)
		else:
			if t % maxi(1, int(floor(26 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 12, 1.5, 3.6, 6, "#c9a0ff")
			if t % 88 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 24, 2.0, 5, "#9945ff", 0)
	elif s == 4:
		if ph == 0:
			if t % maxi(1, int(floor(42 * hm))) == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 20, 1.7, 5, "#e08a2a", float(t) * 0.05)
			if t % 58 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 7, 0.9, 3.2, 6, "#ffd27a")
		elif ph == 1:
			spin += 0.22
			if t % 3 == 0:
				for a in 4:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.5708, 2.4, 5, "#f0a020")
			if t % 64 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 5, 0.7, 3.4, 7, "#ff7a3c")
			if t % 140 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.2)
		else:
			if t % maxi(1, int(floor(28 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 11, 1.4, 3.4, 6, "#ffe0a0")
			if t % 92 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 26, 1.9, 5, "#e08a2a", 0)
	elif s == 5:
		var rage := hp < max_hp * 0.4
		if active_twin == "igor":
			spin += 0.16
			var arms := 6 if rage else 5
			if t % 3 == 0:
				for a in arms:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * (TAU / float(arms)), 2.2, 6, "#b48ce0")
			if t % maxi(1, int(floor(72 * hm))) == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 18, 1.7, 6, "#9d6bff", float(t) * 0.05)
			if rage and t % 42 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 7, 0.9, 3.0, 6, "#c9a0ff")
		else:
			if t % maxi(1, int(floor(40 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 11 if rage else 8, 1.2, 3.2, 7, "#e0b84a")
			if t % 96 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 22, 1.8, 5, "#ffd27a", 0)
			if t % 150 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.2)
			if rage and t % 6 == 0:
				spin += 0.4
				for a in 3:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 2.094, 2.4, 6, "#ffe08a")
	else:
		# Wynn final
		if ph == 0:
			if t % maxi(1, int(floor(38 * hm))) == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 9, 1.2, 3.2, 7, "#ff8a3c")
			if t % 84 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 18, 2.0, 6, "#ff5b7d", float(t) * 0.05)
		elif ph == 1:
			spin += 0.26
			if t % 2 == 0:
				for a in 4:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.5708, 2.5, 6, "#ff6ec7")
			if t % 70 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 7, 1.0, 3.6, 7, "#ffd27a")
			if t % 160 == 0:
				BulletPatterns.heavy_shell(bullet_pool, cx, cy, pxp, pyp, 3.4)
		else:
			spin += 0.16
			if t % 2 == 0:
				for a in 5:
					BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.2566, 2.3, 6, "#ff5b3c")
			if t % 40 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 13, 1.6, 3.6, 6, "#ff9ecb")
			if t % 140 == 0:
				BulletPatterns.ring(bullet_pool, cx, cy, 28, 2.2, 5, "#ff5b7d", 0)

func _boss_special(cx: float, cy: float, p: Node2D) -> void:
	if p == null:
		return
	var port := portrait
	var pxp := p.global_position.x
	var pyp := p.global_position.y
	if port == "ape":
		if t % 6 == 0:
			spin += 0.5
			for a in 8:
				BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 0.785, 2.6, 7, "#ffd27a")
		if t % 30 == 0:
			BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 9, 1.0, 3.2, 7, "#e6c65a")
	elif port == "robotnik":
		if t % 16 == 0:
			for k in range(1, 4):
				BulletPatterns.ring(bullet_pool, cx, cy, 18, 1.4 + k * 0.5, 6, "#a0e0ff", float(t) * 0.05 + k)
	elif port == "mumina":
		spin += 0.16
		if t % 3 == 0:
			for a in 6:
				BulletPatterns.eb(bullet_pool, cx, cy, spin + a * 1.047, 2.2, 6, "#7ed957")
		if t % 40 == 0:
			BulletPatterns.fan_at(bullet_pool, cx, cy, pxp, pyp, 11, 1.4, 3.0, 6, "#bff58a")
	else:
		if t % 40 < 20:
			if t % 5 == 0:
				BulletPatterns.fan_at(bullet_pool, cx, cy, cx, Config.playfield().position.y - 20, 7, 0.6, -3.4, 7, "#ff8a3c")
		else:
			if t % 4 == 0:
				for a in 9:
					BulletPatterns.eb(bullet_pool, cx, cy, float(a) / 9.0 * TAU, 2.0, 6, "#ff5b3c")

func _twin_swap(other: String) -> void:
	if StageFlow:
		StageFlow.twin_swap(self)
	tw[active_twin]["hp"] = hp
	active_twin = other
	hp = float(tw[other].get("hp", max_hp))
	max_hp = float(tw[other].get("max", max_hp))
	hud_name = ("Igor" if other == "igor" else "Grichka") + " Bogdanoff"
	swap_cd = 480 + randi() % 180
	flash = 14.0
	if bullet_pool:
		bullet_pool.clear_enemy()

func take_damage(amount: float, opts: Dictionary = {}) -> void:
	## amount is raw shot dmg; opts may include voidbolt (already-scaled path from Bullet preferred)
	if intro > 0.0 or dead:
		return
	var dmg := amount
	# If caller already scaled (opts.pre_scaled), use raw amount; else apply HTML muls here
	if not bool(opts.get("pre_scaled", false)):
		var is_vb := bool(opts.get("voidbolt", false))
		var wep := str(opts.get("weapon", GameState.current_weapon if GameState else ""))
		if CombatHelpers and CombatHelpers.has_method("scale_boss_shot_damage"):
			dmg = CombatHelpers.scale_boss_shot_damage(amount, is_vb, wep)
		else:
			dmg = amount * _boss_dmg_mul() * (1.0 if is_vb else _boss_wep_mul())
	hp -= dmg
	flash = 3.0
	if twin:
		tw[active_twin]["hp"] = hp
	if hp <= 0.0:
		_on_hp_zero()

func _boss_dmg_mul() -> float:
	## Fallback if CombatHelpers unavailable — match HTML bossDmgMul
	if CombatHelpers and CombatHelpers.has_method("boss_dmg_mul"):
		return CombatHelpers.boss_dmg_mul()
	return 1.0 - minf(0.55, (GameState.power - 1.0) * 0.11)

func _boss_wep_mul() -> float:
	if CombatHelpers and CombatHelpers.has_method("boss_wep_mul"):
		return CombatHelpers.boss_wep_mul()
	return 1.0

func _drop_death_loot() -> void:
	## HTML updateBoss deadT===1 drops
	if ItemSystem == null:
		return
	var px := global_position.x
	var py := global_position.y
	for i in range(12):
		ItemSystem.drop_item(px + (randf() - 0.5) * 40.0, py, "power")
	for i in range(8):
		ItemSystem.drop_item(px + (randf() - 0.5) * 50.0, py, "point")
	ItemSystem.drop_item(px, py, "life")
	ItemSystem.drop_item(px - 10.0, py, "bomb")
	ItemSystem.drop_weapon(px + 14.0, py)

func _on_hp_zero() -> void:
	if twin:
		tw[active_twin]["hp"] = 0
		tw[active_twin]["done"] = true
		var other := "grichka" if active_twin == "igor" else "igor"
		if not bool(tw[other].get("done", false)):
			_twin_swap(other)
			hp = float(tw[other].get("max", max_hp))
			tw[other]["hp"] = hp
			return
	dead = true
	hp = 0
	dead_t = 0.0
	if bullet_pool:
		bullet_pool.clear_enemy()
	ProgressStore.estats_add("bosses", 1)
	GameState.add_score(int(5000 * GameState.score_mul()))
	# HTML grants loot rain (not a flat power+1); loot pickups apply via add_power/fullpower
	GameState.lives = mini(DataRegistry.max_lives(), GameState.lives + 1)
	GameState.bombs = mini(DataRegistry.max_bombs(), GameState.bombs + 1)
	if portrait == "wynn":
		# defer portal until short death flash, then startWynnHell
		pass

func start_wynn_hell() -> void:
	## HTML startWynnHell
	hell = true
	hell_t = 0.0
	hell_done = 0.0
	hell_r = 0.0
	hell_spin = 0.0
	hell_scale = 1.0
	hell_shake = 0.0
	hy = global_position.y
	if StageFlow:
		StageFlow.start_dialog([
			{"w": 1, "t": "That’s the sound of the house going bankrupt. Dank Memes plus Time. Bolieve it."},
			{"w": 2, "t": "James Wynn. Your ledger is settled. The Cabal’s debt comes due — in full."},
			{"w": 0, "t": "N-NO! I RUN this town! UNHAND me, you— NO!! NOT THE PORTAL!!"},
			{"w": 0, "t": "CURSE YOU BOBINA! CURSE YOU REKT! CURSE YOU VIBE! TO HELL WITH BOBO!!!! AAGGGH!!"},
		], data)

func _update_wynn_hell(delta: float) -> void:
	## HTML updateWynnHell
	var df := delta * FRAME
	hell_t += df
	hell_r = minf(82.0, hell_t * 0.7)
	if int(hell_t) % 2 == 0 and CombatHelpers:
		var cols := ["#ff3b1a", "#ff7a2a", "#ffc030"]
		CombatHelpers.particles.append({
			"x": global_position.x + (randf() - 0.5) * hell_r * 1.5,
			"y": hy + (randf() - 0.4) * hell_r,
			"vx": (randf() - 0.5) * 2.0,
			"vy": -1.0 - randf() * 2.4,
			"life": 26.0,
			"c": cols[randi() % 3],
		})
	hell_shake = sin(hell_t * 0.7) * minf(3.5, hell_t * 0.03) if hell_t < 210.0 else 0.0
	var dialog_open := StageFlow != null and StageFlow.dialog != null
	if not dialog_open:
		hell_done += df
		hell_spin += 0.42 * df
		global_position.y = hy + hell_done * 0.5
		hell_scale = maxf(0.0, 1.0 - hell_done / 74.0)
		if hell_done > 96.0:
			hell = false
			if StageFlow:
				StageFlow.on_boss_defeated()
			defeated.emit(boss_id)
			queue_free()

func _draw() -> void:
	## Visuals owned by WorldDraw.drawBoss — AI/collision only here.
	pass

