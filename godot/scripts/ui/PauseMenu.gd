extends Control
## Pause — canvas overlay drawn by HudCanvas; thin input handler for resume/menu.

func _ready() -> void:
	visible = false  # visual pause is HudCanvas
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		if c is CanvasItem:
			c.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameState.state != GameState.State.PAUSED:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			get_tree().paused = false
			GameState.return_to_title()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			var help = get_tree().get_first_node_in_group("help_canvas")
			if help and help.has_method("open_help"):
				help.open_help()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause") or event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			GameState.set_state(GameState.State.PLAY)
			get_tree().paused = false
			get_viewport().set_input_as_handled()

func _on_resume() -> void:
	GameState.set_state(GameState.State.PLAY)
	get_tree().paused = false

func _on_menu() -> void:
	get_tree().paused = false
	GameState.return_to_title()

func _on_display() -> void:
	var dm := get_tree().get_first_node_in_group("display_menu")
	if dm and dm.has_method("open_menu"):
		dm.open_menu()

func _on_settings() -> void:
	get_tree().paused = false
	GameState.set_state(GameState.State.SETTINGS)
