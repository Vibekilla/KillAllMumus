extends Node
## HTML spawnWaves / spawnLil / spawnBig / spawnElite parity.

signal stage_ready_for_boss

var bullet_pool: Node
var playfield: Node2D
var stage_time: float = 0.0  # frames @ 60 Hz
var spawning: bool = false
var boss_spawned: bool = false
var roll: int = -1  # last pack index spawned (-1 = none yet)
var _next_spawn_at: float = 0.0
## Dual / screenshot stills: hard stop all wave activity
var dual_lock: bool = false

const FRAME := 60.0
const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")

func setup(pool: Node, pf: Node2D) -> void:
	bullet_pool = pool
	playfield = pf
	add_to_group("enemy_spawner")
	if SimClock and not SimClock.sim_tick.is_connected(_on_sim_tick):
		SimClock.sim_tick.connect(_on_sim_tick)

func start_stage(_stage_index: int) -> void:
	if dual_lock:
		return
	stage_time = 0.0
	roll = -1
	_next_spawn_at = 0.0  # first pack immediately
	spawning = true
	boss_spawned = false

func clear() -> void:
	spawning = false
	boss_spawned = false
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.is_in_group("bosses"):
			e.queue_free()

func lock_for_dual() -> void:
	## Pin spawner off for dual screenshots
	dual_lock = true
	spawning = false
	boss_spawned = true
	stage_time = 99999.0
	clear()

func unlock_dual() -> void:
	dual_lock = false

func _on_sim_tick(_dt: float) -> void:
	## Wave timers in HTML frames @ 60 Hz — one unit per fixed sim step.
	if dual_lock or not spawning or GameState.state != GameState.State.PLAY:
		return
	stage_time += 1.0
	_spawn_waves()
	# After waveDur frames → boss
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	var wave_dur := float(stage.get("waveDur", 1500))
	if stage_time >= wave_dur and not boss_spawned:
		boss_spawned = true
		spawning = false
		# clear remaining wave mobs gently
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.is_in_group("bosses"):
				e.queue_free()
		stage_ready_for_boss.emit()

func _spawn_waves() -> void:
	if dual_lock or playfield == null:
		return
	var s := GameState.stage_index
	var st := stage_time
	var hm := 0.62 if GameState.hard_mode else 1.2
	var stage: Dictionary = DataRegistry.get_stage(s)
	var wave_dur := float(stage.get("waveDur", 1500))
	var prog := st / maxf(1.0, wave_dur)
	var base_iv := 70.0 if s == 0 else (60.0 if s == 1 else 52.0)
	var iv := maxf(18.0, floorf(base_iv * hm * (1.0 - prog * 0.32)))
	# Schedule packs by absolute stage_time (robust under float dt)
	if st < _next_spawn_at:
		return
	roll += 1
	_next_spawn_at = st + iv
	var pf: Rect2 = Config.playfield()

	if s == 0:
		if roll % 4 == 3:
			_spawn_big(pf.position.x + 80 + randf() * (pf.size.x - 160), pf.position.y - 30)
		else:
			var cx := pf.position.x + 60 + randf() * (pf.size.x - 120)
			var n := 7 if GameState.hard_mode else 5
			for i in n:
				_spawn_lil(cx + (float(i) - float(n - 1) * 0.5) * 24.0,
					pf.position.y - 30 - absf(float(i) - float(n - 1) * 0.5) * 14.0,
					randf_range(-0.4, 0.4), 1.7 + randf() * 0.5, false)
	elif s == 1:
		if roll % 3 == 2:
			_spawn_big(pf.position.x + 70 + randf() * (pf.size.x - 140), pf.position.y - 30, true)
		else:
			var from_left := roll % 2 == 0
			var n2 := 6 if GameState.hard_mode else 4
			for i in n2:
				_spawn_lil(pf.position.x - 20 if from_left else pf.end.x + 20,
					pf.position.y + 40 + i * 34.0,
					1.8 if from_left else -1.8, 0.7 + randf() * 0.4, true)
	else:
		if roll % 5 == 4:
			_spawn_big(pf.position.x + pf.size.x * 0.5, pf.position.y - 30, roll % 2 == 0)
		var n3 := 9 if GameState.hard_mode else 6
		var cx2 := pf.position.x + 60 + randf() * (pf.size.x - 120)
		for i in n3:
			_spawn_lil(cx2 + (float(i) - float(n3 - 1) * 0.5) * 22.0,
				pf.position.y - 30 - float((i * 11) % 40),
				randf_range(-1.2, 1.2), 1.9 + randf() * 0.7, roll % 3 == 0)

	if roll > 1 and roll % 4 == 2:
		_spawn_elite(pf.position.x + 80 + randf() * (pf.size.x - 160))

func _spawn_lil(x: float, y: float, vx: float, vy: float, icy: bool) -> void:
	var d := GameState.stage_index
	var e = EnemyScene.instantiate()
	playfield.add_child(e)
	e.setup(bullet_pool, Vector2(x, y), {
		"kind": "lil",
		"hp": round((3.0 if icy else 2.0) * (1.0 + d * 0.45)),
		"vel": Vector2(vx * (1.0 + d * 0.1), vy * (1.0 + d * 0.14)) * FRAME,
		"icy": icy,
		"r": 15.0,
		"score": 100,
	})

func _spawn_big(x: float, y: float, icy: bool = false) -> void:
	var d := GameState.stage_index
	var e = EnemyScene.instantiate()
	playfield.add_child(e)
	e.setup(bullet_pool, Vector2(x, y), {
		"kind": "big",
		"hp": round((8.0 if icy else 6.0) * (1.0 + d * 0.5)),
		"vel": Vector2(0, 1.4 * FRAME),
		"icy": icy,
		"r": 22.0,
		"score": 350,
		"hover": Config.playfield().position.y + 80 + randf() * 40,
	})

func _spawn_elite(x: float) -> void:
	var d := GameState.stage_index
	var e = EnemyScene.instantiate()
	playfield.add_child(e)
	e.setup(bullet_pool, Vector2(x, Config.playfield().position.y - 40), {
		"kind": "elite",
		"hp": round(14.0 * (1.0 + d * 0.55)),
		"vel": Vector2(0, 1.2 * FRAME),
		"icy": false,
		"r": 26.0,
		"score": 900,
		"hover": Config.playfield().position.y + 100,
		"elite": str(DataRegistry.get_stage(d).get("boss", {}).get("portrait", "")),
	})
