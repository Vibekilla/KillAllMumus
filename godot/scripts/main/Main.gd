extends Node2D
## Root controller.

@onready var playfield: Node2D = $Playfield
@onready var player = $Playfield/Player
@onready var bullet_pool: Node = $BulletPool
@onready var spawner: Node = $EnemySpawner
@onready var stages: Node = $StageController
@onready var title: Control = $UI/TitleScreen
@onready var pause_menu: Control = $UI/PauseMenu
@onready var display_menu: Control = $UI/DisplayMenu
@onready var intro_label: Label = $UI/IntroLabel
@onready var debug_label: Label = $UI/DebugLabel

func _ready() -> void:
	player.setup(bullet_pool)
	spawner.setup(bullet_pool, playfield)
	stages.setup(spawner, bullet_pool)
	if stages.has_signal("request_intro"):
		stages.request_intro.connect(_on_intro)
	GameState.state_changed.connect(_on_state)
	GameState.run_started.connect(_on_run_started)
	ApiClient.refresh_me()
	display_menu.add_to_group("display_menu")
	_on_state(&"TITLE")

func _process(_delta: float) -> void:
	if Config.debug_layer:
		debug_label.visible = true
		debug_label.text = "state=%s score=%d kills=%d stage=%d fps=%.0f" % [
			GameState.State.keys()[GameState.state],
			GameState.session_score,
			GameState.total_kills,
			GameState.stage_index + 1,
			Engine.get_frames_per_second(),
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
	intro_label.visible = (s == &"INTRO")
	if s == &"STAGE_CLEAR":
		await get_tree().create_timer(1.0).timeout
		GameState.advance_stage()
		if GameState.state == GameState.State.INTRO:
			stages.begin_current_stage()

func _on_run_started() -> void:
	player.global_position = Config.PLAYFIELD.get_center() + Vector2(0, 160)
	bullet_pool.clear_all()
	spawner.clear()
	stages.begin_current_stage()

func _on_intro(stage: Dictionary) -> void:
	intro_label.text = "%s\n%s" % [stage.get("title", ""), stage.get("name", "")]
	intro_label.visible = true

func _on_pause_display() -> void:
	if display_menu.has_method("open_menu"):
		display_menu.open_menu()
