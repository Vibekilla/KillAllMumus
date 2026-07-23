extends Node
## Intro → waves → boss → next stage / shop.

signal request_intro(stage: Dictionary)
signal request_boss(stage: Dictionary)

var spawner: Node
var bullet_pool: Node

const BossScene := preload("res://scenes/enemies/Boss.tscn")

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
	await get_tree().create_timer(0.4).timeout
	_spawn_boss(stage)

func _spawn_boss(stage: Dictionary) -> void:
	var boss = BossScene.instantiate()
	var pf: Rect2 = Config.PLAYFIELD
	var bid := str(stage.get("boss", {}).get("id", "boss"))
	var hp := 100.0 + GameState.stage_index * 50.0 + GameState.ng_plus * 8.0
	get_parent().get_node("Playfield").add_child(boss)
	boss.setup(bullet_pool, Vector2(pf.get_center().x, pf.position.y + 90), bid, hp)
	boss.defeated.connect(func(_id):
		# Award heads, open shop every stage except last
		ProgressStore.progress["heads"] = int(ProgressStore.progress.get("heads", 0)) + 10 + GameState.stage_index * 5
		ProgressStore.queue_save()
		if GameState.stage_index >= DataRegistry.stages.size() - 1:
			GameState.end_run(true)
		else:
			GameState.set_state(GameState.State.SHOP)
	)
