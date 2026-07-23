extends SceneTree
## Phase 1.4: headless FPS / frame-time probe for Main scene.
##   xvfb-run -a godot --path godot --script res://scripts/tools/fps_probe.gd
## Prints avg process_frame ms and estimated FPS for title + play samples.

const VIEW_W := 960
const VIEW_H := 540
const SAMPLE_FRAMES := 180

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		print("[FPS] FAIL no GameState")
		quit(1)
		return
	var packed = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[FPS] FAIL Main.tscn")
		quit(1)
		return
	var main = packed.instantiate()
	root.add_child(main)
	for _i in range(12):
		await process_frame

	# dismiss soundgate if present
	var sg = main.get_node_or_null("UI/SoundGate")
	if sg and sg.has_method("force_dismiss"):
		sg.force_dismiss(false)
	elif sg:
		sg.visible = false

	print("[FPS] sample_frames=", SAMPLE_FRAMES)
	await _sample("title", gs, null)
	gs.start_run()
	gs.set_state(gs.State.PLAY)
	var sf = root.get_node_or_null("/root/StageFlow")
	if sf and sf.has_method("on_stage_start"):
		sf.on_stage_start()
	var player = root.get_tree().get_first_node_in_group("player")
	if player:
		if "invuln" in player:
			player.invuln = 99999.0
		gs.lives = 99
	await _sample("play", gs, player)
	print("[FPS] PASS")
	quit(0)

func _sample(label: String, gs, player) -> void:
	var t0 := Time.get_ticks_usec()
	for i in range(SAMPLE_FRAMES):
		await process_frame
		if player and player.get("fire_sys") and player.get("bullet_pool") and (i % 2) == 0:
			player.fire_sys.try_fire(player, player.bullet_pool, false)
	var t1 := Time.get_ticks_usec()
	var ms := float(t1 - t0) / 1000.0
	var avg := ms / float(SAMPLE_FRAMES)
	var fps := 1000.0 / maxf(avg, 0.001)
	print("[FPS] %s: total=%.1fms frames=%d avg=%.2fms/frame ~%.1f FPS (wall clock includes idle wait)" % [
		label, ms, SAMPLE_FRAMES, avg, fps
	])
	print("[FPS] %s state=%s" % [label, gs.State.keys()[gs.state] if gs else "?"])
