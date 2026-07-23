extends SceneTree
## Headless Godot visual capture via SubViewport + Xvfb (GL).
##   xvfb-run -a godot --path godot --script res://scripts/tools/screenshot_playtest.gd

const OUT_SUB := "playtest_shots"
const VIEW_W := 960
const VIEW_H := 540

var _sv: SubViewport
var _main: Node

func _init() -> void:
	call_deferred("_run")

func _A(n: String) -> Node:
	return root.get_node_or_null("/root/" + n)

func _shot_dir() -> String:
	var d := "user://" + OUT_SUB
	DirAccess.make_dir_recursive_absolute(d)
	return d

func _force_ui_size(main: Node) -> void:
	var ui = main.get_node_or_null("UI")
	if ui == null:
		return
	for c in ui.get_children():
		if c is Control:
			var ctrl := c as Control
			ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
			ctrl.offset_left = 0
			ctrl.offset_top = 0
			ctrl.offset_right = 0
			ctrl.offset_bottom = 0
			ctrl.size = Vector2(VIEW_W, VIEW_H)
			ctrl.position = Vector2.ZERO
			ctrl.queue_redraw()

func _save(name: String) -> void:
	for _i in range(3):
		await process_frame
	RenderingServer.force_draw(true)
	await process_frame
	var tex: ViewportTexture = _sv.get_texture()
	if tex == null:
		print("[SHOT] FAIL no SubViewport texture ", name)
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		print("[SHOT] FAIL empty image ", name)
		return
	if img.get_width() != VIEW_W or img.get_height() != VIEW_H:
		img.resize(VIEW_W, VIEW_H, Image.INTERPOLATE_NEAREST)
	var path := _shot_dir().path_join(name + ".png")
	var err := img.save_png(path)
	print("[SHOT] ", name, " err=", err, " ", img.get_width(), "x", img.get_height(),
		" path=", ProjectSettings.globalize_path(path))

func _run() -> void:
	await process_frame
	var GameState = _A("GameState")
	var StageFlow = _A("StageFlow")
	if GameState == null:
		print("[SHOT] FAIL no GameState")
		quit(1)
		return

	_sv = SubViewport.new()
	_sv.name = "ShotViewport"
	_sv.size = Vector2i(VIEW_W, VIEW_H)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	_sv.handle_input_locally = false
	_sv.gui_disable_input = true
	root.add_child(_sv)

	var packed = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[SHOT] FAIL Main.tscn")
		quit(1)
		return
	_main = packed.instantiate()
	_sv.add_child(_main)
	_force_ui_size(_main)
	var pf = _main.get_node_or_null("Playfield")
	if pf:
		pf.z_index = 5
	var fx = _main.get_node_or_null("FxLayer")
	if fx:
		fx.z_index = 10
	var border = _main.get_node_or_null("PlayfieldBorder")
	if border and border is CanvasItem:
		(border as CanvasItem).z_index = -1
	var bg = _main.get_node_or_null("Background")
	if bg and bg is CanvasItem:
		(bg as CanvasItem).z_index = -2
	for _i in range(8):
		await process_frame

	var fast := OS.get_environment("PLAYTEST_FAST") != "0"
	if OS.get_environment("PLAYTEST_FULL") == "1":
		fast = false
	var play_frames := 90 if fast else 200
	var fire_frames := 40 if fast else 100

	# Title
	GameState.set_state(GameState.State.TITLE)
	_force_ui_size(_main)
	for _i in range(8 if fast else 12):
		await process_frame
	await _save("godot_title")

	# Play
	GameState.difficulty = 0
	GameState.ng_plus = 0
	GameState.start_run()
	GameState.set_state(GameState.State.PLAY)
	if StageFlow and StageFlow.has_method("on_stage_start"):
		StageFlow.on_stage_start()
	var player = _sv.get_tree().get_first_node_in_group("player")
	if player == null:
		player = root.get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(304, 400)
		player.z_index = 20
		var spr = player.get_node_or_null("Sprite")
		if spr:
			spr.z_index = 20
	for i in range(play_frames):
		await process_frame
		if player and player.get("fire_sys") and player.get("bullet_pool"):
			player.fire_sys.try_fire(player, player.bullet_pool, false)
	print("[SHOT] enemies=", root.get_tree().get_nodes_in_group("enemies").size(),
		" player=", player != null, " pos=", player.global_position if player else Vector2.ZERO)
	await _save("godot_play")

	if not fast:
		for outfit in ["og", "maid", "honeypot", "cabal"]:
			GameState.selected_outfit = outfit
			GameState.set_state(GameState.State.TITLE)
			_force_ui_size(_main)
			var bob = _sv.find_child("BobinaSprite", true, false)
			if bob and bob.has_method("set_outfit"):
				bob.set_outfit(outfit)
			for _i in range(8):
				await process_frame
			await _save("godot_outfit_" + outfit)

		GameState.set_state(GameState.State.PLAY)
		GameState.power = 6.0
		player = root.get_tree().get_first_node_in_group("player")
		for i in range(fire_frames):
			await process_frame
			if player and player.get("fire_sys") and player.get("bullet_pool"):
				player.fire_sys.try_fire(player, player.bullet_pool, false)
		await _save("godot_play_power6")

	print("[SHOT] done dir=", ProjectSettings.globalize_path(_shot_dir()))
	print("[SHOT] PASS")
	quit(0)
