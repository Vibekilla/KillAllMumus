extends Control
## Win / game over + score submit.

@onready var title_l: Label = %TitleLabel
@onready var stats_l: Label = %StatsLabel
@onready var handle_input: LineEdit = %HandleInput
@onready var save_btn: Button = %SaveBtn

func _ready() -> void:
	visible = false
	GameState.state_changed.connect(_on_state)
	GameState.run_ended.connect(_on_ended)

func _on_state(s: StringName) -> void:
	visible = s in [&"WIN", &"GAMEOVER"]

func _on_ended(won: bool) -> void:
	title_l.text = "BOBO IS SAVED!" if won else "DOWN BUT NOT OUT"
	stats_l.text = "Score %s · %d Mumus · Rank %s · %s" % [
		GameState.session_score, GameState.total_kills, GameState.rank_letter(), GameState.mode_tag()
	]
	if ApiClient.authenticated:
		handle_input.placeholder_text = "Linked — saves under Bobina"
		handle_input.editable = false
		_submit()

func _on_save() -> void:
	_submit()

func _submit() -> void:
	var handle := handle_input.text.strip_edges().trim_prefix("@")
	if handle != "":
		ProgressStore.progress["handle"] = handle
	ApiClient.submit_score({
		"handle": handle,
		"score": GameState.session_score,
		"kills": GameState.total_kills,
		"rank": GameState.rank_letter(),
		"mode": GameState.mode_tag(),
		"won": 1 if GameState.state == GameState.State.WIN else 0,
		"outfit": GameState.selected_outfit,
	})
	save_btn.text = "Saved!"

func _on_menu() -> void:
	GameState.return_to_title()

func _on_again() -> void:
	GameState.start_run()
