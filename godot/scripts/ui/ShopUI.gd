extends Control
## Superseded by canvas FlowUI shop (1:1 drawShop).

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.state_changed.connect(func(_s): visible = false)
