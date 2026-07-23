extends Control
## NgSelectUI — superseded by canvas MenuCanvas host (TitleScreen).
## Kept so packed scenes load; all drawing/input is on TitleScreen.

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.state_changed.connect(func(_s):
		visible = false
	)
