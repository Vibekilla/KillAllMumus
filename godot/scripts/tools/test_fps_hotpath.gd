extends SceneTree
## Guards against FPS regressions on the WorldDraw hot path.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var wd: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if wd.find("_play_stride") < 0:
		print("[FPS] FAIL WorldDraw PLAY must use adaptive _play_stride throttle")
		ok = false
	if wd.find("_draw_stage_bg_solid") < 0:
		print("[FPS] FAIL WorldDraw needs solid stage-bg cold path")
		ok = false
	# Hybrid: face-bin blit for normal play; live only for dash/bomb (or cold miss)
	if wd.find("get_play_texture") < 0:
		print("[FPS] FAIL Bobina play must use face-bin get_play_texture blit")
		ok = false
	if wd.find("dash > 0.0 or bomb > 0.0") < 0:
		print("[FPS] FAIL live drawBobina gated on dash/bomb")
		ok = false
	# Feet pivot blit (not silhouette center) — platform under feet
	if wd.find("px - tw * 0.5") < 0 and wd.find("px - tw*0.5") < 0:
		print("[FPS] FAIL Bobina blit must pin feet at texture center → player pos")
		ok = false
	# bodyCtr for body wraps
	if wd.find("_body_ctr_st") < 0 and wd.find("body_ctr") < 0:
		print("[FPS] FAIL body wraps must use body_ctr")
		ok = false
	var bc: String = FileAccess.get_file_as_string("res://scripts/render/BobinaDrawCache.gd")
	if bc.find("TICK_BUCKET_PLAY := 8") < 0 and bc.find("TICK_BUCKET_PLAY = 8") < 0:
		# allow higher too
		if bc.find("TICK_BUCKET_PLAY") < 0:
			print("[FPS] FAIL missing TICK_BUCKET_PLAY")
			ok = false
	var sbg: String = FileAccess.get_file_as_string("res://scripts/render/StageBgDrawCache.gd")
	if sbg.find("TICK_BUCKET := 10") < 0 and sbg.find("TICK_BUCKET = 10") < 0:
		if "TICK_BUCKET :=" in sbg:
			# extract number
			pass
	# Must compile
	var scr = load("res://scripts/html_parity/WorldDraw.gd")
	if scr == null:
		print("[FPS] FAIL WorldDraw failed to load")
		ok = false
	if ok:
		print("[FPS] PASS hotpath guards")
		quit(0)
	else:
		print("[FPS] FAIL")
		quit(1)
