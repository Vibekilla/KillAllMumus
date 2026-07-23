extends Node
## Wave spawner.

signal wave_cleared
signal stage_ready_for_boss

var bullet_pool: Node
var playfield: Node2D
var wave: int = 0
var enemies_alive: int = 0
var spawning: bool = false

const EnemyScene := preload("res://scenes/enemies/Enemy.tscn")

func setup(pool: Node, pf: Node2D) -> void:
	bullet_pool = pool
	playfield = pf

func start_stage(_stage_index: int) -> void:
	wave = 0
	enemies_alive = 0
	spawning = true
	_spawn_wave()

func _spawn_wave() -> void:
	wave += 1
	var count := 4 + wave + GameState.difficulty * 2 + int(GameState.ng_plus / 10)
	count = mini(count, 18)
	var pf: Rect2 = Config.PLAYFIELD
	for i in count:
		var e = EnemyScene.instantiate()
		playfield.add_child(e)
		var x := pf.position.x + 30 + randf() * (pf.size.x - 60)
		var y := pf.position.y - 20 - randf() * 80
		var icy := GameState.stage_index >= 1 and randf() < 0.25
		e.setup(bullet_pool, Vector2(x, y), {
			"hp": 2.0 + GameState.stage_index * 0.5 + GameState.ng_plus * 0.05,
			"speed": 50.0 + GameState.stage_index * 4.0,
			"icy": icy,
			"score": 100,
		})
		e.killed.connect(_on_enemy_killed)
		enemies_alive += 1

func _on_enemy_killed(_e) -> void:
	enemies_alive = maxi(0, enemies_alive - 1)
	if enemies_alive == 0 and spawning:
		if wave >= 5 + GameState.stage_index:
			spawning = false
			stage_ready_for_boss.emit()
		else:
			await get_tree().create_timer(1.2).timeout
			if GameState.state == GameState.State.PLAY:
				_spawn_wave()

func clear() -> void:
	spawning = false
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	enemies_alive = 0
