extends SceneTree
## Wynn hell portal uses hell_r/hell_t/hy; lotus/shock fire numbers.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var wd: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if wd.find("hell_r") < 0:
		print("[HELL] FAIL WorldDraw must read hell_r")
		ok = false
	if wd.find("hellR") >= 0 and wd.find("hell_r") < 0:
		print("[HELL] FAIL still only camelCase hellR")
		ok = false
	if wd.find("\"hellScale\"") < 0 and wd.find("hell_scale") < 0:
		print("[HELL] FAIL boss state missing hellScale for drawBoss")
		ok = false
	if wd.find("\"hellSpin\"") < 0 and wd.find("hell_spin") < 0:
		print("[HELL] FAIL boss state missing hellSpin")
		ok = false
	# portal at hy not sink y
	if wd.find("hy_v") < 0 and wd.find("b.hy") < 0:
		print("[HELL] FAIL portal must use hy origin")
		ok = false
	var fs: String = FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	if fs.find("0.03") < 0 or fs.find("62.0") < 0:
		print("[HELL] FAIL lotus main fire curl 0.03 life 62")
		ok = false
	if fs.find("0.55 + float(lv)") < 0 and fs.find("0.55 + float(lv) * 0.09") < 0:
		if fs.find("0.55") < 0:
			print("[HELL] FAIL shock spread 0.55+lv*0.09")
			ok = false
	if fs.find("randf() * 5.0") < 0 and fs.find("* 5.0") < 0:
		# shock spd 13+random*5
		if fs.find("13.0 + randf() * 5") < 0:
			print("[HELL] FAIL shock spd 13+random*5")
			ok = false
	var wc: String = FileAccess.get_file_as_string("res://scripts/render/WorldCanvas.gd")
	if wc.find("hell_r") < 0:
		print("[HELL] FAIL WorldCanvas hell_r")
		ok = false
	if ok:
		print("[HELL] PASS")
		quit(0)
	else:
		print("[HELL] FAIL")
		quit(1)
