extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var b: String = FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	var ok := true
	if b.find("_destroy_enemy_projectile") < 0:
		print("[PSHOT] FAIL missing destroy path")
		ok = false
	if b.find("80.0") < 0 or b.find("5.0") < 0:
		print("[PSHOT] FAIL shell 80 / soft 5 score")
		ok = false
	if b.find("drop_item") < 0:
		print("[PSHOT] FAIL shell kill point drop")
		ok = false
	var w: String = FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if w.find("ff3b8e") < 0 or w.find("focus") < 0:
		print("[PSHOT] FAIL focus hitbox ring")
		ok = false
	if ok:
		print("[PSHOT] PASS")
		quit(0)
	else:
		print("[PSHOT] FAIL")
		quit(1)
