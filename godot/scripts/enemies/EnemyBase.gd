extends Area2D
## Generic Mumu.

signal killed(enemy)

@export var max_hp: float = 3.0
@export var speed: float = 60.0
@export var score_value: int = 100
@export var icy: bool = false

var hp: float = 3.0
var bullet_pool: Node
var shoot_cd: float = 1.0
var age: float = 0.0
var kind: String = "mumu"

const TEAM_ENEMY := 1

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp

func setup(pool: Node, pos: Vector2, opts: Dictionary = {}) -> void:
	bullet_pool = pool
	global_position = pos
	max_hp = float(opts.get("hp", max_hp))
	hp = max_hp
	speed = float(opts.get("speed", speed)) * GameState.threat_mul()
	icy = bool(opts.get("icy", false))
	kind = str(opts.get("kind", "mumu"))
	score_value = int(opts.get("score", score_value))
	shoot_cd = randf_range(0.6, 1.4)

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	age += delta
	var pf: Rect2 = Config.PLAYFIELD
	var vx := sin(age * 2.0 + position.x * 0.02) * 30.0
	var vy := speed
	position += Vector2(vx, vy) * delta
	if position.y > pf.end.y + 30:
		queue_free()
		return
	shoot_cd -= delta
	if shoot_cd <= 0.0 and bullet_pool:
		_fire()
		shoot_cd = randf_range(0.9, 1.8) / GameState.threat_mul()
	queue_redraw()

func _fire() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var ang := PI / 2.0
	if player:
		ang = (player.global_position - global_position).angle()
	var spd := 120.0 * GameState.threat_mul()
	var col := Color(0.6, 0.85, 1.0) if icy else Color(1.0, 0.45, 0.55)
	bullet_pool.spawn(global_position, Vector2.from_angle(ang) * spd, 1.0, col, TEAM_ENEMY)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()

func _die() -> void:
	GameState.add_kill(1)
	GameState.add_score(int(score_value * GameState.score_mul()))
	# soft currency drip
	if randf() < 0.15:
		ProgressStore.progress["heads"] = int(ProgressStore.progress.get("heads", 0)) + 1
		ProgressStore.queue_save()
	killed.emit(self)
	queue_free()

func _draw() -> void:
	var col := Color(0.55, 0.8, 1.0) if icy else Color(1.0, 0.55, 0.7)
	draw_circle(Vector2.ZERO, 12, col)
	draw_circle(Vector2(-4, -3), 2.5, Color(0.1, 0.05, 0.1))
	draw_circle(Vector2(4, -3), 2.5, Color(0.1, 0.05, 0.1))
	draw_arc(Vector2(0, 3), 4, 0.2, PI - 0.2, 8, Color(0.2, 0.1, 0.15), 1.5)
