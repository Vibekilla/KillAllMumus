extends Node
## Object pool for bullets.

const BulletScene := preload("res://scenes/bullets/Bullet.tscn")
const POOL_SIZE := 400

var _pool: Array = []

func _ready() -> void:
	for i in POOL_SIZE:
		var b = BulletScene.instantiate()
		b.deactivate()
		add_child(b)
		_pool.append(b)

func spawn(pos: Vector2, vel: Vector2, damage: float, color: Color, team: int):
	for b in _pool:
		if not b.active:
			b.activate(pos, vel, damage, color, team)
			return b
	var b2 = BulletScene.instantiate()
	add_child(b2)
	_pool.append(b2)
	b2.activate(pos, vel, damage, color, team)
	return b2

func clear_enemy() -> void:
	for b in _pool:
		if b.active and int(b.team) == 1:
			b.deactivate()

func clear_all() -> void:
	for b in _pool:
		if b.active:
			b.deactivate()
