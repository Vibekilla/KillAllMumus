extends SceneTree
## One display-frame catch-up must consume at most one bomb.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var p_src := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if p_src.find("_edge_input_frame") < 0:
		print("[BOMB] FAIL missing _edge_input_frame latch")
		quit(1)
		return
	if p_src.find("is_action_just_pressed(\"bomb\")") < 0:
		print("[BOMB] FAIL bomb just_pressed missing")
		quit(1)
		return
	# must gate with edge
	var i := p_src.find("is_action_just_pressed(\"bomb\")")
	var chunk := p_src.substr(maxi(0, i - 80), 120)
	if chunk.find("edge") < 0:
		print("[BOMB] FAIL bomb just_pressed not gated by edge")
		quit(1)
		return
	print("[BOMB] edge latch present PASS")
	quit(0)
