extends CharacterBody2D
## Bobina — movement, shoot, bomb, focus.

signal died
signal bombed

const SPEED := 280.0
const FOCUS_SPEED := 140.0
const TEAM_PLAYER := 0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Node2D = $Sprite

var invuln: float = 0.0
var fire_cd: float = 0.0
var facing: float = -PI / 2
var bullet_pool: Node

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")

func setup(pool: Node) -> void:
	bullet_pool = pool

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	if invuln > 0.0:
		invuln -= delta
		sprite.modulate.a = 0.4 + 0.6 * abs(sin(invuln * 20.0))
	else:
		sprite.modulate.a = 1.0

	var focus := Input.is_action_pressed("focus")
	var spd := FOCUS_SPEED if focus else SPEED
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length() < 0.1:
		var mouse := get_global_mouse_position()
		var to := mouse - global_position
		if to.length() > 6.0:
			dir = to.normalized()
			spd *= clampf(to.length() / 80.0, 0.2, 1.0)
	velocity = dir.normalized() * spd if dir.length() > 0.0 else Vector2.ZERO
	move_and_slide()
	_clamp_to_playfield()

	if dir.length() > 0.1:
		facing = dir.angle()

	fire_cd = maxf(0.0, fire_cd - delta)
	if Input.is_action_pressed("shoot"):
		_try_fire()
	# Soft auto-fire when mouse held / always light fire for desktop feel
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_fire()
	if Input.is_action_just_pressed("bomb"):
		_try_bomb()

func _clamp_to_playfield() -> void:
	var pf: Rect2 = Config.PLAYFIELD
	global_position.x = clampf(global_position.x, pf.position.x + 12, pf.end.x - 12)
	global_position.y = clampf(global_position.y, pf.position.y + 12, pf.end.y - 12)

func _try_fire() -> void:
	if fire_cd > 0.0 or bullet_pool == null:
		return
	fire_cd = 0.04 if GameState.current_weapon == "gatling" else 0.08
	var base_ang := -PI / 2.0
	var shots: Array = [0.0]
	match GameState.current_weapon:
		"spread":
			shots = [-0.35, -0.18, 0.0, 0.18, 0.35]
		"wave":
			shots = [-0.2, 0.0, 0.2]
		"scatter":
			shots = [-0.5, -0.25, 0.0, 0.25, 0.5]
		_:
			shots = [0.0]
	var col := Color(1.0, 0.6, 0.8)
	for off in shots:
		var ang: float = base_ang + float(off)
		var vel := Vector2.from_angle(ang) * 520.0
		bullet_pool.spawn(global_position + Vector2(0, -10), vel, 1.0 + GameState.power * 0.2, col, TEAM_PLAYER)
	if GameState.current_weapon == "laser":
		bullet_pool.spawn(global_position + Vector2(0, -14), Vector2(0, -700), 1.5, Color(0.5, 0.85, 1.0), TEAM_PLAYER)

func _try_bomb() -> void:
	if not GameState.use_bomb():
		return
	if bullet_pool:
		bullet_pool.clear_enemy()
	invuln = 1.2
	bombed.emit()

func take_hit(_dmg: float = 1.0) -> void:
	if invuln > 0.0:
		return
	invuln = 2.0
	GameState.player_hit()
	if GameState.lives < 0:
		died.emit()
