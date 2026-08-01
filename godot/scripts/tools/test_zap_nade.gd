extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var b: String = FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	var fs: String = FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	var isrc: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	var ok := true
	if b.find("chain_lightning") < 0 or b.find("zap") < 0:
		print("[ZAP] FAIL zap hit must chain_lightning")
		ok = false
	if isrc.find("screen_shake") < 0 or isrc.find("nade_boom") < 0:
		print("[ZAP] FAIL nade_boom screen shake")
		ok = false
	if fs.find("thud") < 0:
		print("[ZAP] FAIL grenade thud sfx")
		ok = false
	if ok:
		print("[ZAP] PASS")
		quit(0)
	else:
		print("[ZAP] FAIL")
		quit(1)
