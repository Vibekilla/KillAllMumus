extends Control
## Title menu — start run, leaderboard, settings, Bobina login.

signal start_pressed
signal leaderboard_pressed
signal settings_pressed
signal outfits_pressed
signal emblems_pressed
signal arsenal_pressed
signal ng_pressed
signal login_pressed

@onready var subtitle: Label = %Subtitle
@onready var mode_btn: Button = %ModeBtn
@onready var auth_label: Label = %AuthLabel
@onready var login_btn: Button = %LoginBtn

func _ready() -> void:
	_refresh()
	ApiClient.auth_changed.connect(func(_a): _refresh())
	GameState.state_changed.connect(func(s):
		visible = (s == &"TITLE")
		if visible:
			_refresh()
	)
	visible = GameState.state == GameState.State.TITLE

func _refresh() -> void:
	mode_btn.text = "MODE: %s" % GameState.mode_tag()
	if ApiClient.authenticated:
		auth_label.text = "Signed in as @%s" % str(ApiClient.me.get("username", "Bobina"))
		login_btn.text = "Cloud sync ready · Sign out via web"
	else:
		auth_label.text = "Play as guest — or link Bobina for cloud saves"
		login_btn.text = "Sign in with Bobina"

func _on_start_pressed() -> void:
	start_pressed.emit()
	GameState.start_run()

func _on_mode_pressed() -> void:
	GameState.difficulty = (GameState.difficulty + 1) % 3
	GameState.apply_difficulty()
	ProgressStore.progress["difficulty"] = GameState.difficulty
	ProgressStore.queue_save()
	_refresh()

func _on_ng_pressed() -> void:
	ng_pressed.emit()
	# Cycle NG+ for scaffold
	if ProgressStore.ng_unlocked > 0:
		GameState.ng_plus = (GameState.ng_plus + 1) % (ProgressStore.ng_unlocked + 1)
		ProgressStore.progress["ngPlus"] = GameState.ng_plus
		ProgressStore.queue_save()
		_refresh()

func _on_leaderboard_pressed() -> void:
	leaderboard_pressed.emit()
	GameState.set_state(GameState.State.LEADERBOARD)
	ApiClient.fetch_scores()

func _on_settings_pressed() -> void:
	settings_pressed.emit()
	GameState.set_state(GameState.State.SETTINGS)

func _on_login_pressed() -> void:
	login_pressed.emit()
	ApiClient.open_login()

func _on_outfits_pressed() -> void:
	outfits_pressed.emit()

func _on_emblems_pressed() -> void:
	emblems_pressed.emit()

func _on_arsenal_pressed() -> void:
	arsenal_pressed.emit()
