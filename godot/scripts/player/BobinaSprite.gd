extends Node2D
## Bobina presentation is owned by WorldDraw → full drawBobina.gd (HTML 1:1).
## This node hides legacy Polygon2D children; Player owns movement/collision.
## Never reintroduce simplified presentation or circle stand-ins here.

var outfit_key: String = "og"
var player_state: Dictionary = {}

func _ready() -> void:
	z_index = 25
	z_as_relative = false
	var parent := get_parent()
	if parent:
		parent.z_index = 25
		for c in parent.get_children():
			if c != self and (c is Polygon2D or c is Sprite2D):
				c.visible = false
	# No self-draw — WorldDraw.draw_bobina is the single presentation path

func set_outfit(key: String) -> void:
	outfit_key = key
	player_state["outfit"] = key

func set_state(st: Dictionary) -> void:
	player_state = st
	if st.has("outfit"):
		outfit_key = str(st["outfit"])

func _draw() -> void:
	pass
