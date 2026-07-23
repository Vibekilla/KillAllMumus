extends Control

@onready var list: ItemList = %ScoreList
@onready var status: Label = %StatusLabel

func _ready() -> void:
	visible = false
	ApiClient.scores_received.connect(_on_scores)
	GameState.state_changed.connect(func(s):
		visible = (s == &"LEADERBOARD")
		if visible:
			status.text = "Loading…"
			ApiClient.fetch_scores()
	)

func _on_scores(scores: Array) -> void:
	list.clear()
	if scores.is_empty():
		status.text = "No scores yet."
		return
	status.text = "Top Mumu Slayers"
	var i := 1
	for row in scores:
		var name := str(row.get("name", "Anon"))
		var score := int(row.get("score", 0))
		var rank := str(row.get("rank", "-"))
		var mode := str(row.get("mode", "NORMAL"))
		var linked := bool(row.get("linked", false))
		var mark := "🐻" if linked else "𝕏"
		list.add_item("%2d. %s %s  %s  [%s] %s" % [i, mark, name, _fmt(score), rank, mode])
		i += 1

func _fmt(n: int) -> String:
	if n >= 1_000_000:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)

func _on_back() -> void:
	GameState.return_to_title()
