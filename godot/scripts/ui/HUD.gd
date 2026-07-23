extends CanvasLayer
## Label HUD superseded by HudCanvas panel draw; keep node for scene compat.

func _ready() -> void:
	visible = false
	for c in get_children():
		if c is CanvasItem:
			c.visible = false
