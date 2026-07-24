extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var sv := SubViewport.new()
	sv.size = Vector2i(960, 540)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var main = load("res://scenes/main/Main.tscn").instantiate()
	sv.add_child(main)
	for i in range(15):
		await process_frame
	var GS = root.get_node("/root/GameState")
	GS.start_run()
	GS.set_state(GS.State.PLAY)
	var player = root.get_tree().get_first_node_in_group("player")
	if player and "invuln" in player:
		player.invuln = 99999.0
	for i in range(40):
		await process_frame
	if player and "invuln" in player:
		player.invuln = 99999.0
	GS.set_state(GS.State.PAUSED)
	var pause = main.get_node_or_null("UI/PauseMenu")
	if pause and pause.has_method("_center_panel") and pause.panel:
		pause._center_panel(pause.panel as PanelContainer, 380.0)
	for i in range(15):
		await process_frame
		if pause and pause.has_method("_center_panel") and pause.panel:
			pause._center_panel(pause.panel as PanelContainer, 380.0)
	RenderingServer.force_draw(true)
	await process_frame
	var img: Image = sv.get_texture().get_image()
	var path := "user://playtest_shots/godot_flow_pause.png"
	DirAccess.make_dir_recursive_absolute("user://playtest_shots")
	img.save_png(path)
	print("[SHOT] pause-only saved ", ProjectSettings.globalize_path(path))
	quit(0)
