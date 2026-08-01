extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var src: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	var ok := true
	if src.find("drop_item") < 0 or src.find("point") < 0:
		print("[BCANCEL] FAIL clear_enemy must drop point items")
		ok = false
	if src.find("floaters") < 0:
		print("[BCANCEL] FAIL floaters on cancel")
		ok = false
	if src.find("pts < 40") < 0 and src.find("pts <40") < 0:
		print("[BCANCEL] FAIL 40-point cap")
		ok = false
	if src.find("bhp > 0") < 0:
		print("[BCANCEL] FAIL shells with hp survive near-cancel")
		ok = false
	var sf: String = FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if sf.find("neutralize_inputs") < 0:
		print("[BCANCEL] FAIL neutralize_inputs missing")
		ok = false
	if ok:
		print("[BCANCEL] PASS")
		quit(0)
	else:
		print("[BCANCEL] FAIL")
		quit(1)
