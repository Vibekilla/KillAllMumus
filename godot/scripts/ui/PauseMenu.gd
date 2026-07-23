extends Control

signal resume_pressed
signal menu_pressed
signal display_pressed
signal settings_pressed

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(func(s):
		visible = (s == &"PAUSED")
	)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume() -> void:
	GameState.set_state(GameState.State.PLAY)
	get_tree().paused = false
	resume_pressed.emit()

func _on_menu() -> void:
	get_tree().paused = false
	GameState.return_to_title()
	menu_pressed.emit()

func _on_display() -> void:
	display_pressed.emit()

func _on_settings() -> void:
	settings_pressed.emit()
