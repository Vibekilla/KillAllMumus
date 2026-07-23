extends Node
## Intro → waves → boss → next stage.

signal request_intro(stage: Dictionary)
signal request_boss(stage: Dictionary)

var spawner: Node
var bullet_pool: Node

const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")

func setup(s: Node, pool: Node) -> void:
	spawner = s
	bullet_pool = pool
	if spawner and spawner.has_signal("stage_ready_for_boss"):
		spawner.stage_ready_for_boss.connect(_on_ready_boss)

func begin_current_stage() -> void:
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	request_intro.emit(stage)
	if bullet_pool:
		bullet_pool.clear_all()
	if spawner:
		spawner.clear()
	await get_tree().create_timer(1.5 if not GameState.speedrun else 0.3).timeout
	if GameState.state == GameState.State.INTRO:
		GameState.set_state(GameState.State.PLAY)
		spawner.start_stage(GameState.stage_index)

func _on_ready_boss() -> void:
	var stage: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	request_boss.emit(stage)
	await get_tree().create_timer(0.5).timeout
	_spawn_simple_boss(stage)

func _spawn_simple_boss(stage: Dictionary) -> void:
	var boss = EnemyScene.instantiate()
	var pf: Rect2 = Config.PLAYFIELD
	get_parent().get_node("Playfield").add_child(boss)
	boss.setup(bullet_pool, Vector2(pf.get_center().x, pf.position.y + 80), {
		"hp": 80.0 + GameState.stage_index * 40.0 + GameState.ng_plus * 5.0,
		"speed": 10.0,
		"score": 2000,
		"kind": "boss",
	})
	boss.scale = Vector2(2.2, 2.2)
	boss.killed.connect(func(_e):
		ProgressStore.estats_add("bosses", 1)
		GameState.add_score(int(5000 * GameState.score_mul()))
		GameState.clear_stage()
	)
