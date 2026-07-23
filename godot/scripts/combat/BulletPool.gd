extends Node
## Object pool for bullets + utility ops matching HTML bulletCancel*.

const BulletScene := preload("res://scenes/bullets/Bullet.tscn")
const POOL_SIZE := 600

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
			if int(team) == 1:
				b.add_to_group("enemy_bullet")
			else:
				if b.is_in_group("enemy_bullet"):
					b.remove_from_group("enemy_bullet")
			return b
	var b2 = BulletScene.instantiate()
	add_child(b2)
	_pool.append(b2)
	b2.activate(pos, vel, damage, color, team)
	if int(team) == 1:
		b2.add_to_group("enemy_bullet")
	return b2

func clear_enemy() -> void:
	for b in _pool:
		if b.active and int(b.team) == 1:
			b.deactivate()

func clear_enemy_near(pos: Vector2, radius: float) -> void:
	for b in _pool:
		if b.active and int(b.team) == 1 and b.global_position.distance_to(pos) <= radius:
			b.deactivate()

func clear_all() -> void:
	for b in _pool:
		if b.active:
			b.deactivate()

func iter_active() -> Array:
	## Active bullets for WorldDraw single-pass (HTML bullets/pshots arrays)
	var out: Array = []
	for b in _pool:
		if b.active:
			out.append(b)
	return out

func melee_deflect(origin: Vector2, dir: float, reach: float, half: float, cancel: bool) -> void:
	for b in _pool:
		if not b.active or int(b.team) != 1:
			continue
		var dx: float = b.global_position.x - origin.x
		var dy: float = b.global_position.y - origin.y
		var d: float = sqrt(dx * dx + dy * dy)
		if d < reach + 18.0 and (d < 46.0 or absf(wrapf(atan2(dy, dx) - dir, -PI, PI)) < half + 0.4):
			if cancel or d < 30.0:
				b.deactivate()
			else:
				var sp: float = maxf(2.6 * 60.0, b.velocity.length())
				var nx: float = dx / d if d > 0.5 else 0.0
				var ny: float = dy / d if d > 0.5 else -1.0
				b.velocity = Vector2(nx, ny) * sp
