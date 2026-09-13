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
	# HTML drawBobina every play frame (breath/blink/walk) — no frozen face-bin blit
	if wd.find("ported.drawBobina") < 0:
		print("[FPS] FAIL play Bobina must call live drawBobina")
		ok = false
	if wd.find("No frozen blit") < 0 and wd.find("ported.drawBobina(st)") < 0:
		print("[FPS] FAIL play must not prefer frozen cache blit over live drawBobina")
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
	if sbg.find("create_from_image") >= 0:
		print("[FPS] FAIL StageBg must blit ViewportTexture (no ImageTexture snapshot)")
		ok = false
	if sbg.find("_vp.get_texture()") < 0:
		print("[FPS] FAIL StageBg must return SubViewport texture")
		ok = false
	if sbg.find("TICK_BUCKET") < 0:
		print("[FPS] FAIL missing StageBg TICK_BUCKET")
		ok = false
	var bc2: String = FileAccess.get_file_as_string("res://scripts/render/BobinaDrawCache.gd")
	var title_src: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawTitle.gd")
	if title_src.find("_bobina.drawBobina") < 0:
		print("[FPS] FAIL title mini Bobina must live-draw drawBobina")
		ok = false
	if title_src.find("get_texture") >= 0 and title_src.find("_blit_title_bobina") >= 0:
		# blit helper must not short-circuit to cache
		var blit := title_src.substr(title_src.find("func _blit_title_bobina"))
		if blit.find("get_texture") >= 0:
			print("[FPS] FAIL title mini must not cache-blit (frozen idle)")
			ok = false
	# Must compile
	var bullet_src: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawBullet.gd")
	if bullet_src.find("fill_circle") < 0:
		print("[FPS] FAIL drawBullet must use native fill_circle (crowd path)")
		ok = false
	var pool_src: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if pool_src.find("var _active") < 0:
		print("[FPS] FAIL BulletPool must keep an _active list (no 600-slot scan)")
		ok = false
	var cc: String = FileAccess.get_file_as_string("res://scripts/render/CanvasCompat.gd")
	if cc.find("_ci_tri_cols") < 0 or cc.find("add_target") < 0:
		print("[FPS] FAIL CanvasCompat needs vertex-colored gradients + additive target")
		ok = false
	var wd2: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if wd2.find("BLEND_MODE_ADD") < 0:
		print("[FPS] FAIL WorldDraw needs additive GCO layer")
		ok = false
	var sg: String = FileAccess.get_file_as_string("res://scripts/ui/SoundGate.gd")
	if sg.find("set_music_volume(0.0)") >= 0:
		print("[FPS] FAIL mute must not zero musicVol (HTML lofiOn=false keeps volume)")
		ok = false
	var ts_ui: String = FileAccess.get_file_as_string("res://scripts/ui/TitleScreen.gd")
	if ts_ui.find("SocialBar") < 0:
		print("[FPS] FAIL title must host HTML #social as SocialBar Control")
		ok = false
	if title_src.find("skip_canvas_social") < 0:
		print("[FPS] FAIL title chrome must skip canvas social when DOM bar is on")
		ok = false
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
