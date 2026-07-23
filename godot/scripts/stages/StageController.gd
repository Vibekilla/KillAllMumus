extends Node
## Intro → waves → boss → clear portal/shop field → stage clear → next intro.

signal request_intro(stage: Dictionary)
signal request_boss(stage: Dictionary)

var spawner: Node
var bullet_pool: Node
var _starting: bool = false

const BossScene := preload("res://scenes/enemies/Boss.tscn")

func setup(s: Node, pool: Node) -> void:
	spawner = s
	bullet_pool = pool
	if spawner and spawner.has_signal("stage_ready_for_boss"):
		spawner.stage_ready_for_boss.connect(_on_ready_boss)

func begin_current_stage() -> void:
	if _starting:
		return
	_starting = true
	if StageFlow:
		StageFlow.on_stage_start()
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	request_intro.emit(stage)
	if bullet_pool:
		bullet_pool.clear_all()
	if spawner:
		spawner.clear()
	# Wait for intro (HTML introTimer) — FlowUI advance also can skip
	await get_tree().create_timer(0.05).timeout
	_starting = false
	# stay in INTRO until player advances; if already PLAY, start waves
	if GameState.state == GameState.State.PLAY:
		_start_waves()

func start_waves_if_ready() -> void:
	if GameState.state == GameState.State.PLAY:
		_start_waves()

func _start_waves() -> void:
	if spawner and spawner.has_method("start_stage"):
		spawner.start_stage(GameState.stage_index)

func _on_ready_boss() -> void:
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	request_boss.emit(stage)
	await get_tree().create_timer(0.4).timeout
	_spawn_boss(stage)

func _spawn_boss(stage: Dictionary) -> void:
	var boss = BossScene.instantiate()
	var pf: Rect2 = Config.PLAYFIELD
	get_parent().get_node("Playfield").add_child(boss)
	boss.setup(bullet_pool, Vector2(pf.get_center().x, pf.position.y + 70), stage)
	boss.defeated.connect(func(_id):
		# HTML spawnClearGate (portal + shop on field)
		if StageFlow:
			StageFlow.spawn_clear_gate()
		elif GameState.stage_index >= DataRegistry.stages.size() - 1:
			GameState.end_run(true)
		else:
			GameState.set_state(GameState.State.SHOP)
	)
