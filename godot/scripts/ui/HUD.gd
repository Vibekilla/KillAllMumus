extends CanvasLayer
## In-run HUD: score, lives, bombs, rank, stage.

@onready var score_l: Label = %ScoreLabel
@onready var lives_l: Label = %LivesLabel
@onready var bombs_l: Label = %BombsLabel
@onready var rank_l: Label = %RankLabel
@onready var stage_l: Label = %StageLabel
@onready var mode_l: Label = %ModeLabel

func _ready() -> void:
	GameState.score_changed.connect(_on_score)
	GameState.state_changed.connect(_on_state)
	_on_state(&"TITLE")

func _on_state(s: StringName) -> void:
	visible = s in [&"PLAY", &"INTRO", &"PAUSED", &"STAGE_CLEAR"]
	_refresh()

func _on_score(_score: int, _kills: int, _rank: String) -> void:
	_refresh()

func _refresh() -> void:
	score_l.text = "SCORE %s" % _fmt(GameState.session_score)
	lives_l.text = "❤ %d" % maxi(0, GameState.lives)
	bombs_l.text = "✸ %d" % GameState.bombs
	rank_l.text = "RANK %s ×%.1f" % [GameState.rank_letter(), GameState.score_mul()]
	var st: Dictionary = DataRegistry.get_stage(GameState.stage_index)
	stage_l.text = str(st.get("title", "STAGE")) + " — " + str(st.get("name", ""))
	mode_l.text = GameState.mode_tag()

func _fmt(n: int) -> String:
	if n < 1000:
		return str(n)
	if n < 1_000_000:
		return "%.1fK" % (n / 1000.0)
	if n < 1_000_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	return "%.2fB" % (n / 1_000_000_000.0)
