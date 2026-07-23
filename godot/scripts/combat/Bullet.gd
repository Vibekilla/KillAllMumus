extends Area2D
## Pooled projectile — enemy or player.

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.ENEMY
var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var lifetime: float = 4.0
var radius: float = 4.0
var color: Color = Color(1, 0.4, 0.6)
var active: bool = false
var grazeable: bool = true
var grazed: bool = false

func activate(pos: Vector2, vel: Vector2, dmg: float, col: Color, t: Team) -> void:
	global_position = pos
	velocity = vel
	damage = dmg
	color = col
	team = t
	lifetime = 5.0
	grazed = false
	active = true
	show()
	set_physics_process(true)
	monitoring = true
	monitorable = true
	queue_redraw()

func deactivate() -> void:
	active = false
	hide()
	set_physics_process(false)
	monitoring = false
	monitorable = false
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not active:
		return
	position += velocity * delta
	lifetime -= delta
	var pf: Rect2 = Config.PLAYFIELD
	if lifetime <= 0.0 or not pf.grow(40).has_point(position):
		deactivate()
		return
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color.WHITE)

func _ready() -> void:
	area_entered.connect(_on_area)

func _on_area(a: Area2D) -> void:
	if not active:
		return
	if team == Team.PLAYER and a.is_in_group("enemies"):
		if a.has_method("take_damage"):
			a.take_damage(damage)
		deactivate()
	elif team == Team.ENEMY and a.is_in_group("player_hurtbox"):
		var p := a.get_parent()
		if p and p.has_method("take_hit"):
			p.take_hit(damage)
		deactivate()
