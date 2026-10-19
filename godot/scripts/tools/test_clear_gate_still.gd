extends SceneTree
## S14: clear-gate void is a dark hole, and the hut label is the gold word SHOP.
## Boots Main in a SubViewport so FlowUI draws the live portal. Not a product close.

const VIEW_W := 960
const VIEW_H := 540

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := get_root()
	var sv := SubViewport.new()
	sv.name = "GateViewport"
	sv.size = Vector2i(VIEW_W, VIEW_H)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false
	sv.handle_input_locally = false
	sv.gui_disable_input = true
	root.add_child(sv)
	var packed: PackedScene = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[GATE] FAIL Main.tscn")
		quit(1)
		return
	var main := packed.instantiate()
	sv.add_child(main)
	for _i in range(10):
		await process_frame
	var gs = root.get_node_or_null("GameState")
	var sf = root.get_node_or_null("StageFlow")
	if gs == null or sf == null or not sf.has_method("spawn_clear_gate"):
		print("[GATE] FAIL autoload")
		quit(1)
		return
	gs.stage_index = 0
	gs.set_meta("dual_mode", true)
	gs.set_state(gs.State.PLAY)
	var spawner := main.get_node_or_null("EnemySpawner")
	if spawner:
		spawner.set("dual_lock", true)
	sf.spawn_clear_gate()
	sf.clear_msg_t = 120.0
	var sg := main.get_node_or_null("UI/SoundGate")
	if sg and sg.has_method("force_dismiss"):
		sg.force_dismiss(false)
	elif sg:
		sg.visible = false
	var title := main.get_node_or_null("UI/TitleScreen") as CanvasItem
	if title:
		title.visible = false
	var player := main.get_node_or_null("Playfield/Player") as Node2D
	if player:
		player.global_position = Vector2(-400, -400)
	var flow := main.get_node_or_null("UI/FlowUI")
	if flow:
		flow.set_meta("dual_lock_tick", 40)
		flow.tick = 40
		flow.queue_redraw()
	for _j in range(8):
		await process_frame
		if flow:
			flow.tick = 40
			flow.queue_redraw()
	RenderingServer.force_draw(true)
	await process_frame
	var tex: ViewportTexture = sv.get_texture()
	if tex == null:
		print("[GATE] FAIL no texture")
		quit(1)
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		print("[GATE] FAIL empty image")
		quit(1)
		return
	var path := "/tmp/cleargate_now.png"
	img.save_png(path)
	print("[GATE] state=", gs.State.keys()[gs.state], " portal=", sf.clear_portal, " cleared=", sf.is_field_cleared() if sf.has_method("is_field_cleared") else "?")
	var core := img.get_pixel(304, 169)
	var core_sum := core.r + core.g + core.b
	var dark := 0
	for y in range(161, 177):
		for x in range(296, 312):
			var q := img.get_pixel(x, y)
			if q.r + q.g + q.b < 0.45:
				dark += 1
	# HTML hole is a dark disc. SHOP is a gold word above the hut, not the pot.
	var gold_x0 := 999
	var gold_x1 := 0
	for x in range(430, 500):
		for y in range(246, 262):
			var p := img.get_pixel(x, y)
			if p.r > 0.55 and p.g > 0.32 and p.b < 0.55 and p.r > p.g and p.g > p.b + 0.04:
				if x < gold_x0:
					gold_x0 = x
				if x > gold_x1:
					gold_x1 = x
				break
	var shop_span := gold_x1 - gold_x0 if gold_x1 >= gold_x0 else 0
	var pot := img.get_pixel(458, 264)
	print("[GATE] core=", core, " sum=", snapped(core_sum, 0.001), " dark=", dark, " shop_span=", shop_span, " pot=", pot, " path=", path)
	var ok := true
	if dark < 80:
		print("[GATE] FAIL portal core is not a dark hole")
		ok = false
	if shop_span < 16:
		print("[GATE] FAIL SHOP label is not a wide gold word")
		ok = false
	if pot.r < 0.45 or pot.g < 0.2:
		print("[GATE] FAIL honey pot is missing")
		ok = false
	if ok:
		print("[GATE] PASS")
	quit(0 if ok else 1)
