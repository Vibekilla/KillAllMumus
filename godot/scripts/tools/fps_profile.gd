extends SceneTree
## Wall-clock FPS profile for Main (title + play + mobs). No illegal direct _draw.
##   xvfb-run -a godot --path godot --script res://scripts/tools/fps_profile.gd

const SAMPLE := 90

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		print("[PROF] FAIL no GameState")
		quit(1)
		return
	var packed = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[PROF] FAIL Main.tscn")
		quit(1)
		return
	var main = packed.instantiate()
	root.add_child(main)
	for _i in range(15):
		await process_frame
	var sg = main.get_node_or_null("UI/SoundGate")
	if sg and sg.has_method("force_dismiss"):
		sg.force_dismiss(false)
	elif sg:
		sg.visible = false

	print("[PROF] renderer=%s" % _renderer_name())
	await _wall("title", null)
	var ts = main.get_node_or_null("UI/TitleScreen")
	if ts and ts.get("last_draw_usec") != null:
		print("[PROF] title_draw_last=%.2fms" % (float(ts.last_draw_usec) / 1000.0))

	gs.start_run()
	gs.set_state(gs.State.PLAY)
	var sf = root.get_node_or_null("/root/StageFlow")
	if sf and sf.has_method("on_stage_start"):
		sf.on_stage_start()
	var player = root.get_tree().get_first_node_in_group("player")
	if player and "invuln" in player:
		player.invuln = 99999.0
	gs.lives = 99

	for _j in range(45):
		await process_frame

	var wd = main.get_node_or_null("WorldCanvas")
	if wd:
		_report_cache(wd)
		print("[PROF] play_stride=%s" % str(wd.get("_play_stride")))

	var hudc = main.get_node_or_null("UI/HudCanvas")
	if hudc and hudc.get("last_draw_usec") != null:
		print("[PROF] hud_draw_last=%.2fms" % (float(hudc.last_draw_usec) / 1000.0))
	await _wall("play", player)

	var n_en := root.get_tree().get_nodes_in_group("enemies").size()
	print("[PROF] enemies_alive=%d" % n_en)
	await _wall("play-mobs", player)

	print("[PROF] engine_fps_now=%.1f" % Engine.get_frames_per_second())
	print("[PROF] PASS")
	quit(0)

func _renderer_name() -> String:
	return "video=%s" % str(OS.get_video_adapter_driver_info())

func _wall(label: String, player) -> void:
	var t0 := Time.get_ticks_usec()
	for i in range(SAMPLE):
		await process_frame
		if player and player.get("fire_sys") and player.get("bullet_pool") and (i % 2) == 0:
			player.fire_sys.try_fire(player, player.bullet_pool, false)
	var t1 := Time.get_ticks_usec()
	var ms := float(t1 - t0) / 1000.0
	var avg := ms / float(SAMPLE)
	var fps := 1000.0 / maxf(avg, 0.001)
	print("[PROF] wall %s: avg=%.2fms/frame ~%.1f FPS (n=%d) engine_fps=%.1f" % [
		label, avg, fps, SAMPLE, Engine.get_frames_per_second()
	])

func _report_cache(wd: Node) -> void:
	var bc = wd.get("bobina_cache")
	var sc = wd.get("stage_bg_cache")
	var bn := 0
	var sn := 0
	var bb := 0
	var sb := 0
	var bu := 0
	if bc:
		if bc.get("_ready_tex") != null:
			bn = int(bc._ready_tex.size())
		if bc.get("bake_count") != null:
			bb = int(bc.bake_count)
		if bc.get("bake_usec_total") != null:
			bu = int(bc.bake_usec_total)
	if sc:
		if sc.get("_ready_tex") != null:
			sn = int(sc._ready_tex.size())
		if sc.get("bake_count") != null:
			sb = int(sc.bake_count)
	print("[PROF] cache bobina_entries=%d bobina_bakes=%d bobina_get_image_ms=%.1f stage_bg_bakes=%d" % [
		bn, bb, float(bu) / 1000.0, sb
	])
	if wd.get("last_draw_usec") != null:
		print("[PROF] world_draw_last=%.2fms stride=%s" % [
			float(wd.last_draw_usec) / 1000.0, str(wd.get("_play_stride"))
		])
