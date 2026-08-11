extends SceneTree
## FireSystem advances tick/CD on SimClock, not display _process.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	if src.find("func _process") >= 0:
		print("[FIRE] FAIL still has _process (display-rate tick)")
		ok = false
	else:
		print("[FIRE] no _process ok")
	if src.find("sim_tick") < 0 or src.find("_on_sim_tick") < 0:
		print("[FIRE] FAIL must connect SimClock.sim_tick")
		ok = false
	else:
		print("[FIRE] sim_tick ok")
	if src.find("fire_cd_frames - 1.0") < 0 and src.find("fire_cd_frames - 1") < 0:
		print("[FIRE] FAIL CD should decrement 1 frame per sim step")
		ok = false
	else:
		print("[FIRE] frame CD ok")
	if src.find("player_down") < 0:
		print("[FIRE] FAIL CD/tick should freeze while player_down")
		ok = false
	else:
		print("[FIRE] death freeze ok")
	if ok:
		print("[FIRE] PASS")
		quit(0)
	else:
		print("[FIRE] FAIL")
		quit(1)
