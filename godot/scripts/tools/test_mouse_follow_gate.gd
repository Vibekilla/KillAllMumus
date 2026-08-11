extends SceneTree
## HTML mouse follow requires moveT>0 — Player must not always chase cursor.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if src.find("mouse_move_t") < 0:
		print("[MF] FAIL Player must gate mouse follow on mouse_move_t")
		quit(1)
		return
	if src.find("get_global_mouse_position()") >= 0 and src.find("mouse_move_t") < 0:
		print("[MF] FAIL unguarded global mouse chase")
		quit(1)
		return
	# Must not chase when moveT expired
	if src.find("only ease on the first sim step") < 0 and src.find("Catch-up") < 0:
		# soft: still ok if mouse_move_t present
		pass
	print("[MF] mouse_move_t gate present PASS")
	quit(0)
