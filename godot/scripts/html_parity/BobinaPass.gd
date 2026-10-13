extends Node2D
## Source-over Bobina. Above AddBack (soap-bubble aura) and below AddLayer (post FX).

func _draw() -> void:
	var world := get_parent()
	if world and world.has_method("draw_bobina_pass"):
		world.draw_bobina_pass()
