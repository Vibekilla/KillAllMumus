extends SceneTree
## Bullet / enemy / boss collision shapes follow HTML hit radii.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var bsrc := FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	if bsrc.find("_sync_collision_radius") < 0:
		print("[COLL] FAIL Bullet missing _sync_collision_radius")
		ok = false
	else:
		print("[COLL] Bullet sync ok")
	if bsrc.find("shell") >= 0 and bsrc.find("radius = 12.0") < 0:
		print("[COLL] FAIL shell radius 12")
		ok = false
	var esrc := FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if esrc.find("_sync_collision_radius") < 0:
		print("[COLL] FAIL EnemyBase missing shape sync")
		ok = false
	else:
		print("[COLL] EnemyBase sync ok")
	var bss := FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if bss.find("_sync_collision_radius") < 0:
		print("[COLL] FAIL BossController missing shape sync")
		ok = false
	else:
		print("[COLL] Boss sync ok")
	if bss.find("radius: float = 38.0") < 0 and bss.find("radius = 38.0") < 0:
		print("[COLL] FAIL boss r must be 38 HTML")
		ok = false
	var psrc := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if psrc.find("_sync_hurt_radius") < 0 or psrc.find("2.2") < 0:
		print("[COLL] FAIL Player focus hitR 2.2/4.2 missing")
		ok = false
	else:
		print("[COLL] Player focus hurt ok")
	if ok:
		print("[COLL] PASS")
		quit(0)
	else:
		print("[COLL] FAIL")
		quit(1)
