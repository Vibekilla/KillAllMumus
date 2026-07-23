extends SceneTree
func _init():
	call_deferred("go")
func go():
	await process_frame
	var GS = root.get_node("/root/GameState")
	GS.set_state(GS.State.PLAY)
	GS.power = 3.0
	GS.set_meta("stage_cleared", false)
	var p0 = GS.power
	# simulate ~1 second at 60fps = 60 * 0.00085
	for i in range(60):
		GS._process(1.0/60.0)
	print("[BLEED] power ", p0, " -> ", GS.power, " expected ~", 3.0 - 0.00085*60)
	GS.set_meta("stage_cleared", true)
	var p1 = GS.power
	for i in range(60):
		GS._process(1.0/60.0)
	print("[BLEED] cleared freeze ", p1, " -> ", GS.power, " (should equal)")
	print("[BLEED] PASS" if absf(GS.power - p1) < 0.00001 and GS.power < p0 else "[BLEED] FAIL")
	quit()
