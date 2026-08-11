extends Area2D
## Mumu / big / elite — HTML spawnLil/spawnBig/spawnElite parity.

signal killed(enemy)

var max_hp: float = 2.0
var hp: float = 2.0
var bullet_pool: Node
var age_frames: float = 0.0
var kind: String = "lil"  # lil | big | elite
var icy: bool = false
var score_value: int = 100
var vel: Vector2 = Vector2.ZERO
var hover_y: float = 0.0
var radius: float = 15.0
var flash: float = 0.0
var charm: float = 0.0
var stun: float = 0.0
## HTML e.flung — vault hammer flight until wall detonate (px/frame vel)
var flung: float = 0.0
var flung_vel: Vector2 = Vector2.ZERO
var bcol: Color = Color("ff8ac0")
var elite_type: String = ""

const FRAME := 60.0
const TEAM_ENEMY := 1
const BulletPatterns = preload("res://scripts/combat/BulletPatterns.gd")

var ctx: RefCounted
var ported: RefCounted

func _ready() -> void:
	add_to_group("enemies")
	z_index = 15
	z_as_relative = false
	hp = max_hp
	# Drawing moved to WorldDraw (shared CanvasCompat) — no per-enemy ctx
	set_physics_process(false)
	if SimClock and not SimClock.sim_tick.is_connected(_on_sim_tick):
		SimClock.sim_tick.connect(_on_sim_tick)
	if not tree_exiting.is_connected(_disconnect_sim):
		tree_exiting.connect(_disconnect_sim)

func _disconnect_sim() -> void:
	if SimClock and SimClock.sim_tick.is_connected(_on_sim_tick):
		SimClock.sim_tick.disconnect(_on_sim_tick)

func setup(pool: Node, pos: Vector2, opts: Dictionary = {}) -> void:
	bullet_pool = pool
	global_position = pos
	kind = str(opts.get("kind", "lil"))
	icy = bool(opts.get("icy", false))
	max_hp = float(opts.get("hp", 2.0))
	hp = max_hp
	vel = opts.get("vel", Vector2(0, 100)) as Vector2
	radius = float(opts.get("r", 15.0 if kind == "lil" else 30.0))
	# HTML killEnemy score: big → 500, else 100 (elite included)
	score_value = int(opts.get("score", 500 if kind == "big" else 100))
	hover_y = float(opts.get("hover", Config.playfield().position.y + 90.0))
	elite_type = str(opts.get("elite", ""))
	bcol = Color("9fe0ff") if icy else Color("ff7ad1")
	if kind == "elite":
		if opts.has("bcol"):
			bcol = Color.html(str(opts.get("bcol")))
		else:
			bcol = Color("7ed957")
	age_frames = randf() * 100.0
	_sync_collision_radius()

func _sync_collision_radius() -> void:
	## HTML e.r is the hit radius (lil 15 / big+elite 30). pshot check is (e.r+4).
	## Body check is (e.r+p.r+2) with p.r≈3 → e.r+5. Shape = e.r pairs with pshot r=4 / hurt r=5.
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return
	var sh := cs.shape as CircleShape2D
	if sh == null:
		return
	sh = sh.duplicate() as CircleShape2D
	cs.shape = sh
	sh.radius = maxf(4.0, radius)

func _on_sim_tick(delta: float) -> void:
	## HTML enemy AI on fixed sim frames (with FireSystem / ItemSystem / specials)
	_step(delta)

func _physics_process(delta: float) -> void:
	_step(delta)

func _step(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	# Dual stills: freeze AI / fire / drift so elite art is readable
	if has_meta("dual_freeze") and bool(get_meta("dual_freeze")):
		vel = Vector2.ZERO
		return
	# HTML: if(p.dead) early-return whole play update — freeze mobs during death window
	if GameState.player_down:
		return
	# HTML Sixth Sense: skip this frame for mobs/elites per slowAcc gates
	if CombatHelpers and CombatHelpers.has_method("slowmo_allows_enemy"):
		if not CombatHelpers.slowmo_allows_enemy(kind):
			return
	age_frames += delta * FRAME
	if flash > 0.0:
		flash -= delta * FRAME
	var pf: Rect2 = Config.playfield()
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var sfr := 1.0 - GameState.stage_index * 0.13
	var hm := GameState.hard_mode

	if charm > 0.0:
		charm -= delta * FRAME
		if int(age_frames) % 8 == 0:
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == self or not is_instance_valid(o):
					continue
				if o.get("charm") != null and float(o.charm) > 0.0:
					continue
				if global_position.distance_to(o.global_position) < 54.0 and o.has_method("take_damage"):
					o.take_damage(3.0)
		if charm <= 0.0:
			_die(true)
		return

	# HTML hammer-flung: fly until wall, then enemyExplode; still body-check player
	if flung > 0.0:
		var df_f := delta * FRAME
		flung = maxf(0.0, flung - df_f)
		global_position += flung_vel * df_f
		flung_vel *= pow(0.92, df_f)
		if global_position.x <= pf.position.x + 12.0 \
				or global_position.x >= pf.end.x - 12.0 \
				or global_position.y <= pf.position.y + 10.0 \
				or global_position.y >= pf.end.y - 10.0:
			_die(true)  # charmed path → _enemy_explode
			return
		_touch_player(p)
		return

	if stun > 0.0:
		stun -= delta * FRAME
		_touch_player(p)
		return

	# HTML: attacks and body-hits require !p.dead (no fire/contact while Bobina is down)
	var p_alive := p != null and not bool(p.get("dead"))

	if kind == "lil":
		position += vel * delta
		vel.x += sin(age_frames * 0.06 + position.x * 0.01) * 0.05 * FRAME
		if p_alive and position.y < pf.position.y + pf.size.y * 0.6:
			vel.x += signf(p.global_position.x - position.x) * 0.012 * FRAME
		vel.x = clampf(vel.x * 0.99, -2.4 * FRAME, 2.4 * FRAME)
		if position.x < pf.position.x + 12:
			position.x = pf.position.x + 12
			vel.x = absf(vel.x)
		if position.x > pf.end.x - 12:
			position.x = pf.end.x - 12
			vel.x = -absf(vel.x)
		var fire_iv := maxi(70, int(round((150.0 if hm else 190.0) * sfr)))
		if int(age_frames) % fire_iv == 0 and p_alive and position.y < pf.position.y + pf.size.y * 0.7:
			var n := (2 + GameState.stage_index) if icy else (1 + GameState.stage_index)
			BulletPatterns.fan_at(bullet_pool, position.x, position.y, p.global_position.x, p.global_position.y,
				n, 0.5 + GameState.stage_index * 0.12, 2.4 if icy else 2.8, 6.0, "#9fe0ff" if icy else "#ff7ad1")
	else:
		# big / elite — hover and ring-fire
		if position.y < hover_y:
			position.y += vel.y * delta
		else:
			position.y = hover_y + sin(age_frames * 0.05) * 8.0
			var drift := sin(age_frames * 0.02) * 0.9 * FRAME
			if p_alive:
				drift += signf(p.global_position.x - position.x) * 0.4 * FRAME
			position.x += drift * delta
			position.x = clampf(position.x, pf.position.x + 30, pf.end.x - 30)
		var riv := maxi(40, int(round((70.0 if hm else 95.0) * sfr)))
		if int(age_frames) % riv == 0 and p_alive:
			var cnt := (9 if icy else 7) + GameState.stage_index * 2
			# HTML: e.bcol || (icy ? '#8fd0ff' : '#ff8ac0') — elite has bcol; big uses icy fallback
			var ring_col: Variant = bcol if kind == "elite" else ("#8fd0ff" if icy else "#ff8ac0")
			BulletPatterns.ring(bullet_pool, position.x, position.y, cnt, 1.7, 6.0, ring_col, age_frames * 0.1)
		var hiv := maxi(90, int(round((150.0 if hm else 200.0) * sfr)))
		if int(age_frames) % hiv == 0 and p_alive:
			BulletPatterns.heavy_shell(bullet_pool, position.x, position.y, p.global_position.x, p.global_position.y, 2.5)

	if p_alive:
		_touch_player(p)

	if position.y > pf.end.y + 50 or position.x < pf.position.x - 60 or position.x > pf.end.x + 60:
		queue_free()
		return
	# Redraw ~15 Hz unless flash hit-flash (was every physics frame → major FPS sink)

func _touch_player(p: Node2D) -> void:
	if p == null or not p.has_method("take_hit"):
		return
	# HTML: if(!p.dead) body-check; no contact damage while Bobina is down
	if bool(p.get("dead")):
		return
	# HTML: (e.r + p.r + 2) with p.r = 3 → e.r + 5
	if global_position.distance_to(p.global_position) < radius + 5.0:
		# HTML: hitPlayer(e.kind==='elite'?eliteHearts():1)
		var hearts: float = 1.0
		if kind == "elite":
			if ItemSystem and ItemSystem.has_method("elite_hearts"):
				hearts = float(ItemSystem.elite_hearts())
			else:
				hearts = float(mini(5, 2 + GameState.difficulty + GameState.ng_plus))
		p.take_hit(hearts)

func take_damage(amount: float, opts: Dictionary = {}) -> void:
	hp -= amount
	flash = 5.0
	if hp <= 0.0:
		# HTML doBomb: killEnemy(e, true) — silent mass kills
		_die(false, bool(opts.get("silent", false)))

func _die(charmed: bool = false, silent: bool = false) -> void:
	# HTML killEnemy / enemyExplode (Kiss Me charm expiry)
	if charmed:
		_enemy_explode()
		return
	GameState.add_kill(1)
	if StageFlow:
		StageFlow.note_kill()
	# HTML killEnemy owns score (big 500 / else 100 × scoreMult) — avoid double-add
	ItemSystem.kill_enemy({
		"x": global_position.x, "y": global_position.y,
		"kind": kind, "icy": icy,
	}, silent)
	killed.emit(self)
	queue_free()

func _enemy_explode() -> void:
	## HTML enemyExplode — charm burst AoE + bullet clear + loot
	if has_meta("_exploded") and bool(get_meta("_exploded")):
		return
	set_meta("_exploded", true)
	hp = 0.0
	var px := global_position.x
	var py := global_position.y
	if CombatHelpers:
		for i in range(12):
			CombatHelpers.particles.append({
				"x": px, "y": py,
				"vx": (randf() - 0.5) * 9.0, "vy": (randf() - 0.5) * 9.0,
				"life": 22.0, "c": "#ffd27a" if (i % 2) == 0 else "#fff",
			})
	# AoE 6 dmg within 46px (other living enemies)
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or not is_instance_valid(o):
			continue
		if o.is_in_group("bosses"):
			continue
		if global_position.distance_to(o.global_position) < 46.0 and o.has_method("take_damage"):
			o.take_damage(6.0)
			if "flash" in o:
				o.flash = 5.0
	# HTML enemyExplode: pure filter + floaters (no free point drops)
	var pool: Node = bullet_pool
	if pool == null and get_tree():
		pool = get_tree().get_first_node_in_group("bullet_pool")
	if pool and pool.has_method("despawn_enemy_near"):
		pool.despawn_enemy_near(global_position, 42.0, 12.0, 0.3)
	elif pool and pool.has_method("clear_enemy_near"):
		pool.clear_enemy_near(global_position, 42.0)
	# HTML enemyExplode: screenShake 3.5 + hit sfx
	if CombatHelpers:
		CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 3.5)
	if AudioBus:
		AudioBus.sfx("hit")
	GameState.add_kill(1)
	if StageFlow:
		StageFlow.note_kill()
	# Prefer kill_enemy score path when available
	if ItemSystem and ItemSystem.has_method("kill_enemy"):
		ItemSystem.kill_enemy({"x": px, "y": py, "kind": kind, "icy": icy}, false)
	else:
		GameState.add_score(int(float(score_value) * GameState.score_mul()))
		if ItemSystem:
			ItemSystem.drop_loot({"x": px, "y": py, "kind": kind})
	killed.emit(self)
	queue_free()

func _draw() -> void:
	## Visuals owned by WorldDraw (full drawMumu/drawElite). This node is sim/collision only.
	pass

