extends CharacterBody2D
## Bobina — movement, shoot, bomb, focus, specials, melee.

signal died
signal bombed

const SPEED := 280.0
const FOCUS_SPEED := 140.0
const TEAM_PLAYER := 0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Node2D = $Sprite

var invuln: float = 0.0
var fire_cd: float = 0.0
var bullet_pool: Node
var specials: Node
var melee: Node
var consumables: Node
var emblems: Node

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	specials = preload("res://scripts/systems/SpecialSystem.gd").new()
	melee = preload("res://scripts/systems/MeleeSystem.gd").new()
	consumables = preload("res://scripts/systems/ConsumableSystem.gd").new()
	emblems = preload("res://scripts/systems/EmblemSystem.gd").new()
	add_child(specials)
	add_child(melee)
	add_child(consumables)
	add_child(emblems)
	# Bobina sprite
	var bob := preload("res://scripts/player/BobinaSprite.gd").new()
	bob.name = "BobinaSprite"
	sprite.add_child(bob)
	bob.set_outfit(GameState.selected_outfit)

func setup(pool: Node) -> void:
	bullet_pool = pool

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	if emblems:
		emblems.tick_play()
	if specials:
		specials.tick(delta)
	if melee:
		melee.tick(delta)

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

	fire_cd = maxf(0.0, fire_cd - delta)
	if Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_fire()
	if Input.is_action_just_pressed("bomb"):
		_try_bomb()
	if Input.is_action_just_pressed("special") and GameState.specials.size():
		var key := str(GameState.specials[0])
		if specials.use(key, self, bullet_pool):
			pass
	if Input.is_action_pressed("melee"):
		melee.begin_hold()
	if Input.is_action_just_released("melee"):
		var mk := "katana"
		var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
		var ms: Array = ar.get("m", ["katana"])
		if ms.size():
			mk = str(ms[0])
		melee.release(self, mk)
	# build special meter slowly while shooting
	if Input.is_action_pressed("shoot"):
		GameState.special_meter = minf(100.0, GameState.special_meter + delta * 8.0)

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
		bullet_pool.spawn(global_position + Vector2(0, -10), Vector2.from_angle(ang) * 520.0, 1.0 + GameState.power * 0.2, col, TEAM_PLAYER)
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
