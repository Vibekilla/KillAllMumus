extends SceneTree
## Boss cadence sfx('shoot') every 24 frames (HTML updateBoss).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src: String = FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if src.find("% 24") < 0 and src.find("%24") < 0:
		print("[BOSSFX] FAIL missing t%24 shoot cadence")
		ok = false
	if src.find('sfx("shoot")') < 0 and src.find("sfx('shoot')") < 0:
		print("[BOSSFX] FAIL missing sfx shoot")
		ok = false
	# after patterns / before special trigger is ideal; at least present in live update path
	var idx := src.find('sfx("shoot")')
	if idx < 0:
		idx = src.find("sfx('shoot')")
	var patterns := src.find("func _patterns")
	var special_trig := src.find("_trigger_boss_special")
	if idx > 0 and patterns > 0 and idx > patterns:
		# sfx is after _patterns definition is ok if call site is earlier
		pass
	# call site: look for int(t) % 24 near stun/special block
	if src.find("int(t) % 24") < 0 and src.find("t % 24") < 0:
		print("[BOSSFX] FAIL no int(t)%24 call site")
		ok = false
	else:
		print("[BOSSFX] t%24 shoot ok")
	var scr = load("res://scripts/enemies/bosses/BossController.gd")
	if scr == null:
		print("[BOSSFX] FAIL parse")
		ok = false
	if ok:
		print("[BOSSFX] PASS")
		quit(0)
	else:
		print("[BOSSFX] FAIL")
		quit(1)
