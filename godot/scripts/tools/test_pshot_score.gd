extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var b: String = FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	var sf: String = FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	var fs: String = FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	var ok := true
	if b.find("80.0") < 0 or b.find("5.0") < 0:
		print("[PS] FAIL shell/soft scores")
		ok = false
	if sf.find("next_intro_frames") < 0 or sf.find("120.0") < 0:
		print("[PS] FAIL stageclear intro 120")
		ok = false
	if fs.find("0.035") < 0 or fs.find("58.0") < 0:
		print("[PS] FAIL lotus curl/life HTML")
		ok = false
	if ok:
		print("[PS] PASS")
		quit(0)
	else:
		print("[PS] FAIL")
		quit(1)
