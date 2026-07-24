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
## HTML death / respawn cycle (p.dead, p.respawn)
var dead: bool = false
var respawn: float = 0.0
const HURT_LINES := [
	"Ngh—!", "Ow!", "Tch—!", "That stings!", "Is that all?!", "Not today!",
	"Rugged?! Never!", "Down bad — not down out.", "That’s a dip, not a top.",
	"Cope — I respawn.", "Paper hands? Me? Never.", "Buy the dip… of my HP.",
	"Bobo needs me — get up!", "Not my final form.", "Comeback loading…",
	"You call that a candle?", "Diamond paws, diamond will.",
]

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
	# Dual screenshot lock: pin pose/facing; no mouse-follow / fire / move.
	# Does NOT clear dash/trail/bomb — playtest sets those for stills.
	if has_meta("dual_lock_pose") and bool(get_meta("dual_lock_pose")):
		velocity = Vector2.ZERO
		if has_meta("dual_aim"):
			aim = float(get_meta("dual_aim"))
		else:
			aim = -PI / 2.0
		if has_meta("dual_focus"):
			focus = bool(get_meta("dual_focus"))
		# Hold still timers when dual_hold_fx is set (stable aura stills)
		var hold_fx := has_meta("dual_hold_fx") and bool(get_meta("dual_hold_fx"))
		if not hold_fx:
			if invuln > 0.0 and invuln < 9000.0:
				invuln = maxf(0.0, invuln - delta * FRAME)
			if bomb_fx > 0.0:
				bomb_fx = maxf(0.0, bomb_fx - delta * FRAME)
			if shield_t > 0.0:
				shield_t = maxf(0.0, shield_t - delta * FRAME)
			if rapid_t > 0.0:
				rapid_t = maxf(0.0, rapid_t - delta * FRAME)
			if vial_t > 0.0:
				vial_t = maxf(0.0, vial_t - delta * FRAME)
			if phase_t > 0.0:
				phase_t = maxf(0.0, phase_t - delta * FRAME)
			if dash > 0.0:
				dash = maxf(0.0, dash - delta * FRAME)
		if specials:
			specials.tick(delta)
		if melee:
			melee.tick(delta)
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
	# HTML: while dead, only tick respawn then re-init
	if dead:
		velocity = Vector2.ZERO
		respawn = maxf(0.0, respawn - df)
		sprite.modulate.a = 0.25
		if respawn <= 0.0 and GameState.lives >= 0:
			_respawn_player()
		return

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
	# Hardware gamepad stick already feeds move_* via InputMap (GamepadMap)

	if dash > 0.0:
		dash -= df
		velocity = Vector2.from_angle(dash_ang) * 18.0 * FRAME
		trail.push_front({"wx": global_position.x, "wy": global_position.y})
		if trail.size() > 16:
			trail.resize(16)
		_dash_plow()
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

	# Unified fire: hold shoot or LMB (same on desktop / touch / Steam — no separate autofire mode).
	# Touch FIRE button holds shoot via Main._inject_action.
	var want_fire := (
		Input.is_action_pressed("shoot")
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	)
	if want_fire and fire_sys:
		if fire_sys.try_fire(self, bullet_pool, focus):
			AudioBus.sfx("shoot")
		# Special meter is HTML trickle +0.012/frame (GameState sim) + graze/kills — not per-fire

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
	# HTML: item_switch cycles; item_use is tap-to-consume (ConsumableSystem.tick)
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
	## HTML doDash — face/mouse aim, slash-dash on full melee hold
	if dash > 0.0 or dash_cd > 0.0:
		return
	var ang := aim if aim != 0.0 else -PI / 2.0
	var mouse := get_global_mouse_position()
	var dmouse := mouse - global_position
	if dmouse.length() > 8.0:
		ang = dmouse.angle()
	# HTML: slash = meleeHeld && meleeChg >= 0.99
	var slash := melee != null and bool(melee.get("holding")) and float(melee.get("charge")) >= 0.99
	dash_ang = ang
	slash_dash = slash
	dash = 16.0 if slash else 12.0
	dash_cd = 52.0 if slash else 40.0
	invuln = maxf(invuln, 22.0 if slash else 15.0)
	trail.clear()
	ProgressStore.estats_add("dashes", 1)
	if int(ProgressStore.estats.get("dashes", 0)) >= 50:
		ProgressStore.unlock_emblem("dash_50")
	if slash:
		if CombatHelpers:
			CombatHelpers.flash("✦ SLASH DASH!", 42.0)
			CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 6.0)
		ProgressStore.unlock_emblem("slash_dash")
		var mk := "katana"
		var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
		var ms: Array = ar.get("m", ["katana"])
		if ms.size():
			mk = str(ms[0])
		# HTML doMeleeSwipe(1.0, ang) at dash start, then lock melee CD
		if melee.has_method("release"):
			melee.holding = true
			melee.charge = 1.0
			melee.cooldown = 0.0
			melee.release(self, mk, ang)
			melee.cooldown = maxf(float(melee.cooldown), 24.0)
		if AudioBus:
			AudioBus.sfx("card")
			AudioBus.sfx(str(_melee_def(mk).get("snd", "slash")))
		if CombatHelpers:
			for i in range(24):
				CombatHelpers.particles.append({
					"x": global_position.x, "y": global_position.y,
					"vx": -cos(ang) * 4.0 + (randf() - 0.5) * 3.6,
					"vy": -sin(ang) * 4.0 + (randf() - 0.5) * 3.6,
					"life": 22.0, "c": "#ffe08a",
				})
	else:
		if AudioBus:
			AudioBus.sfx("graze")
			AudioBus.sfx("power")
		if CombatHelpers:
			for i in range(14):
				CombatHelpers.particles.append({
					"x": global_position.x, "y": global_position.y,
					"vx": -cos(ang) * 4.0 + (randf() - 0.5) * 2.5,
					"vy": -sin(ang) * 4.0 + (randf() - 0.5) * 2.5,
					"life": 18.0, "c": "#9ad4ff",
				})

func _melee_def(key: String) -> Dictionary:
	if DataRegistry:
		for m in DataRegistry.melee:
			if str(m.get("key", "")) == key:
				return m
		if DataRegistry.melee.size():
			return DataRegistry.melee[0]
	return {}

func _dash_plow() -> void:
	## HTML: dash kills mumus / chips boss; slash cuts bullets + trail melee arcs
	var rad := 26.0 if slash_dash else 16.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.is_in_group("bosses"):
			var br: float = 36.0
			if "radius" in e:
				br = float(e.radius)
			var hit_r := br + (18.0 if slash_dash else 14.0)
			if global_position.distance_to(e.global_position) < hit_r:
				if e.has_method("take_damage"):
					e.take_damage(5.0 if slash_dash else 2.0)
					if "flash" in e:
						e.flash = 4.0
			continue
		var er: float = 15.0
		if "radius" in e:
			er = float(e.radius)
		if global_position.distance_to(e.global_position) < er + rad:
			if e.has_method("take_damage"):
				e.take_damage(999.0)
	if slash_dash:
		if bullet_pool and bullet_pool.has_method("clear_enemy_near"):
			bullet_pool.clear_enemy_near(global_position, 34.0)
		# slash arcs every 4 frames along the path
		if int(dash) % 4 == 0:
			var mk2 := "katana"
			var ar2: Dictionary = ProgressStore.progress.get("arsenal", {})
			var ms2: Array = ar2.get("m", ["katana"])
			if ms2.size():
				mk2 = str(ms2[0])
			var m: Dictionary = _melee_def(mk2)
			if CombatHelpers:
				CombatHelpers.melee_fx.append({
					"x": global_position.x, "y": global_position.y,
					"dir": dash_ang,
					"reach": float(m.get("reach", 155)) * 0.9,
					"half": float(m.get("arc", 2.0)) * 0.5,
					"col": str(m.get("col", "#ff2b4d")),
					"key": str(m.get("key", mk2)),
					"life": 12.0, "t": 0.0, "charge": 1.0,
				})

func _dash_land() -> void:
	## HTML dashLandExplosion on touchdown
	if CombatHelpers:
		CombatHelpers.dash_land_explosion(self, slash_dash)

func _try_bomb() -> void:
	## HTML doBomb — clear bullets, chip all enemies, BOBINA BLAST juice
	if not GameState.use_bomb():
		return
	if bullet_pool:
		bullet_pool.clear_enemy()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.is_in_group("bosses"):
			var intro_v := float(e.intro) if "intro" in e else 0.0
			var dead_v := bool(e.dead) if "dead" in e else false
			if e.has_method("take_damage") and intro_v <= 0.0 and not dead_v:
				var mh := float(e.max_hp) if "max_hp" in e else 100.0
				e.take_damage(floorf(mh * 0.09))
				if "flash" in e:
					e.flash = 6.0
		elif e.has_method("take_damage"):
			e.take_damage(8.0)
			if "flash" in e:
				e.flash = 6.0
	invuln = maxf(invuln, 140.0)
	bomb_fx = 46.0
	if AudioBus:
		AudioBus.sfx("bomb")
	if CombatHelpers:
		CombatHelpers.flash("BOBINA BLAST!", 50.0)
		for i in range(60):
			var cols := ["#ff6ec7", "#ffd27a", "#fff"]
			CombatHelpers.particles.append({
				"x": global_position.x, "y": global_position.y,
				"vx": (randf() - 0.5) * 14.0, "vy": (randf() - 0.5) * 14.0,
				"life": 40.0, "c": cols[i % 3],
			})
	if int(ProgressStore.estats.get("bombs", 0)) >= 50:
		ProgressStore.unlock_emblem("bomb_50")
	if StageFlow:
		StageFlow.note_bomb()
	bombed.emit()

func take_hit(dmg: float = 1.0) -> void:
	## HTML hitPlayer — vial soak, shield chip, death+respawn, power scatter
	if invuln > 0.0 or dead or phase_t > 0.0:
		return
	var hearts := maxi(1, int(round(dmg)))
	# Unholy Vial: absorb next N bullets during vialT
	if vial_t > 0.0 and vial_hits > 0:
		vial_hits -= 1
		invuln = maxf(invuln, 26.0)
		if AudioBus:
			AudioBus.sfx("hit")
		if CombatHelpers:
			for i in range(12):
				CombatHelpers.particles.append({
					"x": global_position.x, "y": global_position.y,
					"vx": (randf() - 0.5) * 6.0, "vy": (randf() - 0.5) * 6.0,
					"life": 18.0, "c": "#9d6bff" if (i % 2) == 0 else "#4a1e7a",
				})
		if vial_hits <= 0:
			vial_t = 0.0
		return
	# Shield absorbs the whole hit, loses 120 frames of shield time
	if shield_t > 0.0:
		shield_t = maxf(0.0, shield_t - 120.0)
		invuln = maxf(invuln, 40.0)
		if AudioBus:
			AudioBus.sfx("hit")
		if CombatHelpers:
			for i in range(10):
				CombatHelpers.particles.append({
					"x": global_position.x, "y": global_position.y,
					"vx": (randf() - 0.5) * 6.0, "vy": (randf() - 0.5) * 6.0,
					"life": 16.0, "c": "#e8a860",
				})
		return
	# Real hit → death cycle (HTML p.dead / p.respawn)
	if StageFlow:
		StageFlow.note_player_hit()
	GameState.player_hit(hearts)
	if AudioBus:
		AudioBus.sfx("hurt")
	dead = true
	respawn = 70.0
	velocity = Vector2.ZERO
	dash = 0.0
	trail.clear()
	if hearts > 1 and CombatHelpers:
		CombatHelpers.flash("✖ ELITE HIT — %d HEARTS!" % hearts, 80.0)
		CombatHelpers.screen_shake = maxf(CombatHelpers.screen_shake, 7.0)
	var line: String = str(HURT_LINES[randi() % HURT_LINES.size()])
	if GameState.lives < 0:
		line = "I won’t give up on Bobo!"
	# HTML bobinaSay(line, frames, true) — dialog bar, not just flash
	if StageFlow and StageFlow.has_method("bobina_say"):
		StageFlow.bobina_say(line, 90.0 if GameState.lives < 0 else 55.0, true)
	elif CombatHelpers:
		CombatHelpers.flash(line, 90.0 if GameState.lives < 0 else 55.0)
	if CombatHelpers:
		for i in range(40):
			CombatHelpers.particles.append({
				"x": global_position.x, "y": global_position.y,
				"vx": (randf() - 0.5) * 9.0, "vy": (randf() - 0.5) * 9.0,
				"life": 36.0, "c": "#ff9ecb",
			})
	# Drop power on death (scatter items)
	var lost := maxf(0.0, GameState.power - 1.0)
	GameState.power = maxf(1.0, GameState.power - 1.0)
	if ItemSystem:
		var n_drop := mini(8, int(round(lost * 10.0)) + 3)
		for i in range(n_drop):
			ItemSystem.drop_item(
				global_position.x + (randf() - 0.5) * 40.0,
				global_position.y - 10.0,
				"power"
			)
	# Push enemy bullets out of a 100px radius
	if bullet_pool and bullet_pool.has_method("clear_enemy_near"):
		bullet_pool.clear_enemy_near(global_position, 100.0)
	if GameState.lives < 0:
		died.emit()

func _respawn_player() -> void:
	## HTML initPlayer after death when lives remain
	dead = false
	respawn = 0.0
	var pf: Rect2 = Config.playfield()
	global_position = Vector2(pf.position.x + pf.size.x * 0.5, pf.position.y + pf.size.y - 70.0)
	invuln = 120.0
	aim = -PI / 2.0
	focus = false
	dash = 0.0
	dash_cd = 0.0
	slash_dash = false
	trail.clear()
	knock = 0.0
	bomb_fx = 0.0
	vial_hits = 0
	vial_t = 0.0
	phase_t = 0.0
	velocity = Vector2.ZERO
	sprite.modulate.a = 1.0
