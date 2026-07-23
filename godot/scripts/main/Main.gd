extends Node2D
## Root controller — wires playfield, UI, stage flow.

@onready var playfield: Node2D = $Playfield
@onready var player = $Playfield/Player
@onready var bullet_pool: Node = $BulletPool
@onready var spawner: Node = $EnemySpawner
@onready var stages: Node = $StageController
@onready var display_menu: Control = $UI/DisplayMenu
@onready var intro_label: Label = $UI/IntroLabel
@onready var debug_label: Label = $UI/DebugLabel

var _last_state: StringName = &""
## HTML keys[k] held via touch buttons (melee/focus/etc.)
var _touch_held: Dictionary = {}  # key -> touch index or true
var _touch_finger_key: Dictionary = {}  # finger id -> key

func _ready() -> void:
	# Stay live while get_tree().paused so pause-button / touch can unpause
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.setup(bullet_pool)
	spawner.setup(bullet_pool, playfield)
	stages.setup(spawner, bullet_pool)
	if stages.has_signal("request_intro"):
		stages.request_intro.connect(_on_intro)
	GameState.state_changed.connect(_on_state)
	GameState.run_started.connect(_on_run_started)
	if SimClock:
		SimClock.reset()
	ApiClient.refresh_me()
	display_menu.add_to_group("display_menu")
	_on_state(&"TITLE")

func _input(event: InputEvent) -> void:
	## HTML pdown/pmove/pup + joyStart/joyMove/joyEnd for touch
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var pos := st.position
		if st.pressed:
			JoyPad.pdown(pos)
			if GameState.state == GameState.State.PLAY and JoyPad.touch_ui_on:
				# right-rail / pause chip first (HTML .btn / #pausebtn)
				var k := _touch_button_at(pos)
				if k != "":
					_touch_down(k, st.index)
					return
				# left half → virtual stick
				if pos.x < Config.W * 0.46:
					JoyPad.joy_start(pos, st.index)
		else:
			_touch_up_finger(st.index)
			JoyPad.pup()
			JoyPad.joy_end(st.index)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		JoyPad.pmove(sd.position)
		JoyPad.joy_move(sd.position, sd.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			JoyPad.pdown(event.position)
			# desktop testing of touch chrome when ui=touch
			if GameState.state == GameState.State.PLAY and JoyPad and JoyPad.touch_ui_on:
				var k2 := _touch_button_at(event.position)
				if k2 != "":
					_touch_down(k2, -1)
		else:
			_touch_up_finger(-1)
			JoyPad.pup()
	elif event is InputEventMouseMotion:
		JoyPad.pmove(event.position)

func _touch_button_at(pos: Vector2) -> String:
	var hud := get_node_or_null("UI/HudCanvas")
	if hud == null:
		hud = get_tree().get_first_node_in_group("hud_canvas") if get_tree() else null
	if hud and hud.has_method("touch_hit"):
		return str(hud.touch_hit(pos))
	return ""

func _touch_down(k: String, finger) -> void:
	## HTML touchstart on .btn → keys[k]=true + keyPress(k)
	_touch_finger_key[finger] = k
	_touch_held[k] = true
	_inject_action(k, true)
	if InputRouter:
		InputRouter.key_press(k)

func _touch_up_finger(finger) -> void:
	if not _touch_finger_key.has(finger):
		return
	var k: String = str(_touch_finger_key[finger])
	_touch_finger_key.erase(finger)
	_touch_held.erase(k)
	_inject_action(k, false)

func _inject_action(k: String, pressed: bool) -> void:
	## Map HTML key names onto InputMap actions for hold buttons
	var action := k
	match k:
		"cycle":
			action = "cycle_special"
		"fire", "pause", "start", "menu", "tweet":
			# one-shot via key_press only
			return
	if not InputMap.has_action(action):
		return
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _process(_delta: float) -> void:
	if Config.debug_layer:
		debug_label.visible = true
		var sim_t := SimClock.tick if SimClock else 0
		debug_label.text = "state=%s score=%d kills=%d stage=%d fps=%.0f sim=%d" % [
			GameState.State.keys()[GameState.state],
			GameState.session_score,
			GameState.total_kills,
			GameState.stage_index + 1,
			Engine.get_frames_per_second(),
			sim_t,
		]
	else:
		debug_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.state == GameState.State.PLAY:
			GameState.set_state(GameState.State.PAUSED)
			get_tree().paused = true
		elif GameState.state == GameState.State.PAUSED:
			GameState.set_state(GameState.State.PLAY)
			get_tree().paused = false

func _on_state(s: StringName) -> void:
	intro_label.visible = false  # canvas FlowUI draws intro 1:1
	if s == &"INTRO":
		stages.begin_current_stage()
	elif s == &"PLAY":
		# Intro advanced → start waves
		if stages.has_method("start_waves_if_ready"):
			stages.start_waves_if_ready()
	_last_state = s

func _on_run_started() -> void:
	if SimClock:
		SimClock.reset()
	player.global_position = Config.playfield().get_center() + Vector2(0, 160)
	if player.has_node("Sprite/BobinaSprite"):
		player.get_node("Sprite/BobinaSprite").set_outfit(GameState.selected_outfit)
	bullet_pool.clear_all()
	spawner.clear()
	# start_run already sets INTRO → _on_state begins stage

func _on_intro(stage: Dictionary) -> void:
	intro_label.text = "%s\n%s" % [stage.get("title", ""), stage.get("name", "")]

func _on_pause_display() -> void:
	if display_menu.has_method("open_menu"):
		display_menu.open_menu()
