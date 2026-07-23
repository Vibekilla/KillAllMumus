extends CharacterBody2D
## Bobina — HTML movement / fire / bomb / focus / special / melee / dash parity.

signal died
signal bombed

const FRAME := 60.0
const SPEED := 6.6 * FRAME        # HTML 6.6 px/frame
const FOCUS_SPEED := 3.5 * FRAME  # HTML 3.5 px/frame
const TEAM_PLAYER := 0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Node2D = $Sprite

var invuln: float = 0.0  # frames
var bomb_fx: float = 0.0
var aim: float = -PI / 2.0
var dash: float = 0.0
var dash_ang: float = 0.0
var dash_cd: float = 0.0
var knock: float = 0.0
var focus: bool = false
var bullet_pool: Node
var specials: Node
var melee: Node
var consumables: Node
var emblems: Node
var fire_sys: Node
var phase_t: float = 0.0
var shield_t: float = 0.0
var rapid_t: float = 0.0  # HTML player.rapidT (Monke's Frenzy)
var vial_t: float = 0.0   # HTML player.vialT (Unholy Vial window)
var vial_hits: int = 0    # HTML player.vialHits
var trail: Array = []  # dash comet trail (local points)
var slash_dash: bool = false
var armed_special: int = 0
var _shift_tap_t: float = 999.0

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	specials = preload("res://scripts/systems/SpecialSystem.gd").new()
	melee = preload("res://scripts/systems/MeleeSystem.gd").new()
	consumables = preload("res://scripts/systems/ConsumableSystem.gd").new()
	emblems = preload("res://scripts/systems/EmblemSystem.gd").new()
	fire_sys = preload("res://scripts/combat/FireSystem.gd").new()
	add_child(specials)
	add_child(melee)
	add_child(consumables)
	add_child(emblems)
	add_child(fire_sys)
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
	if consumables:
		consumables.tick(delta)

	var df := delta * FRAME
	if invuln > 0.0:
		invuln -= df
		sprite.modulate.a = 0.4 + 0.6 * absf(sin(invuln * 0.5))
	else:
		sprite.modulate.a = 1.0
	if bomb_fx > 0.0:
		bomb_fx -= df
	if dash_cd > 0.0:
		dash_cd -= df
	if knock > 0.0:
		knock -= df
	if phase_t > 0.0:
		phase_t -= df
	if rapid_t > 0.0:
		rapid_t = maxf(0.0, rapid_t - df)
	if shield_t > 0.0:
		shield_t -= df
	if vial_t > 0.0:
		vial_t = maxf(0.0, vial_t - df)
		if vial_t <= 0.0:
			vial_hits = 0
	_shift_tap_t += df

	focus = Input.is_action_pressed("focus") and dash <= 0.0
	var spd := FOCUS_SPEED if focus else SPEED

	# double-tap focus → dash
	if Input.is_action_just_pressed("focus"):
		if _shift_tap_t < 18.0 and dash_cd <= 0.0 and dash <= 0.0:
			_do_dash()
		_shift_tap_t = 0.0

	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	# HTML joy.active analog stick takes priority on touch
	if JoyPad and JoyPad.active and (absf(JoyPad.vx) > 0.05 or absf(JoyPad.vy) > 0.05):
		dir = Vector2(JoyPad.vx, JoyPad.vy)

	if dash > 0.0:
		dash -= df
		velocity = Vector2.from_angle(dash_ang) * 18.0 * FRAME
		trail.push_front({"wx": global_position.x, "wy": global_position.y})
		if trail.size() > 18:
			trail.resize(18)
		if dash <= 0.0:
			_dash_land()
			slash_dash = false
	elif trail.size():
		# fade trail after dash
		if trail.size() > 0 and int(Engine.get_process_frames()) % 2 == 0:
			trail.pop_back()
	elif knock > 0.0:
		velocity *= 0.9
	elif dir.length() > 0.1:
		velocity = velocity.lerp(dir.normalized() * spd, 0.5)
	else:
		# mouse follow (desktop) — HTML MOUSE.follow / MOUSE.speed
		var mouse := get_global_mouse_position()
		var pf: Rect2 = Config.playfield()
		if pf.grow(40).has_point(mouse):
			var base_f := Config.mouse_follow if Config else 0.55
			var spd_mul := Config.mouse_speed if Config else 1.12
			var f := maxf(0.28, base_f * 0.5) if focus else base_f
			velocity = (mouse - global_position) * f * spd_mul * FRAME
		else:
			velocity = velocity.lerp(Vector2.ZERO, 0.3)

	move_and_slide()
	_clamp_to_playfield()

	# aim toward movement or mouse
	var mouse2 := get_global_mouse_position()
	if (mouse2 - global_position).length() > 4.0:
		aim = lerp_angle(aim, (mouse2 - global_position).angle(), 0.25)
	elif velocity.length() > 10.0:
		aim = lerp_angle(aim, velocity.angle(), 0.15)
	else:
		aim = lerp_angle(aim, -PI / 2.0, 0.08)

	# fire — HTML autoFire (default on) or hold shoot / LMB
	var autofire := true
	if ProgressStore:
		var st: Dictionary = ProgressStore.progress.get("settings", {})
		autofire = bool(st.get("autofire", true))
	var want_fire := autofire or Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if want_fire and fire_sys:
		if fire_sys.try_fire(self, bullet_pool, focus):
			AudioBus.sfx("shoot")
		GameState.special_meter = minf(100.0, GameState.special_meter + delta * 6.5)

	if Input.is_action_just_pressed("bomb"):
		_try_bomb()
	if Input.is_action_just_pressed("special") and GameState.specials.size():
		var key := str(GameState.specials[0])
		if specials:
			specials.use(key, self, bullet_pool)
	# HTML: swap weapon / cycle special
	if Input.is_action_just_pressed("swap"):
		CombatHelpers.swap_weapon()
	if Input.is_action_just_pressed("cycle_special"):
		CombatHelpers.cycle_special()
	# HTML: item_switch cycles consumable; item_use hold handled in consumables.tick
	if Input.is_action_just_pressed("item_switch"):
		if consumables:
			consumables.cycle()
	if Input.is_action_pressed("melee"):
		melee.begin_hold()
	if Input.is_action_just_released("melee"):
		var mk := "katana"
		var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
		var ms: Array = ar.get("m", ["katana"])
		if ms.size():
			mk = str(ms[0])
		melee.release(self, mk, aim)

	# update bobina sprite state — full fields for drawBobina parity
	if has_node("Sprite/BobinaSprite"):
		var bob = get_node("Sprite/BobinaSprite")
		if bob.has_method("set_state"):
			var local_trail: Array = []
			for q in trail:
				local_trail.append({
					"x": float(q.get("wx", global_position.x)) - global_position.x,
					"y": float(q.get("wy", global_position.y)) - global_position.y,
				})
			bob.set_state({
				"x": 0.0,
				"y": 0.0,
				"vx": velocity.x / 60.0,
				"vy": velocity.y / 60.0,
				"face": aim,
				"aim": aim,
				"focus": focus,
				"iframe": invuln,
				"dash": dash > 0.0,
				"slashDash": slash_dash,
				"trail": local_trail,
				"bomb_fx": bomb_fx,
				"bombFx": bomb_fx,
				"outfit": GameState.selected_outfit,
				"power": GameState.power,
				"lean": clampf(velocity.x / 200.0, -1.0, 1.0),
				"tick": SimClock.sim_frame if SimClock else 0,
				"pose": int(ProgressStore.progress.get("pose", 0)),
			})

func _clamp_to_playfield() -> void:
	var pf: Rect2 = Config.playfield()
	global_position.x = clampf(global_position.x, pf.position.x + 8, pf.end.x - 8)
	global_position.y = clampf(global_position.y, pf.position.y + 8, pf.end.y - 8)

func _do_dash() -> void:
	var mouse := get_global_mouse_position()
	dash_ang = (mouse - global_position).angle()
	dash = 10.0
	dash_cd = 48.0
	invuln = maxf(invuln, 14.0)
	# full-charge melee hold + dash = slash dash (HTML)
	slash_dash = melee != null and float(melee.get("charge")) >= 0.85
	trail.clear()

func _dash_land() -> void:
	# HTML dashLandExplosion + kill nearby mumus on landing
	if CombatHelpers:
		CombatHelpers.dash_land_explosion(self, slash_dash)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.is_in_group("bosses"):
			continue
		if global_position.distance_to(e.global_position) < 48.0 and e.has_method("take_damage"):
			e.take_damage(12.0)

func _try_bomb() -> void:
	if not GameState.use_bomb():
		return
	if bullet_pool:
		bullet_pool.clear_enemy()
	# damage all enemies
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.is_in_group("bosses"):
			if e.has_method("take_damage"):
				e.take_damage(float(e.get("max_hp")) * 0.09)
		elif e.has_method("take_damage"):
			e.take_damage(8.0)
	invuln = 140.0
	bomb_fx = 46.0
	AudioBus.sfx("bomb")
	if StageFlow:
		StageFlow.note_bomb()
	bombed.emit()

func take_hit(_dmg: float = 1.0) -> void:
	if invuln > 0.0 or phase_t > 0.0:
		return
	# HTML Unholy Vial: absorb next N bullets during vialT
	if vial_t > 0.0 and vial_hits > 0:
		vial_hits -= 1
		invuln = maxf(invuln, 20.0)
		if vial_hits <= 0:
			vial_t = 0.0
		return
	if shield_t > 0.0:
		shield_t = 0.0
		invuln = 60.0
		return
	invuln = 120.0
	AudioBus.sfx("hurt")
	GameState.player_hit()
	if StageFlow:
		StageFlow.note_player_hit()
	# HTML hitPlayer: run.power = Math.max(1, run.power - 1.0)
	GameState.power = maxf(1.0, GameState.power - 1.0)
	if GameState.lives < 0:
		died.emit()
