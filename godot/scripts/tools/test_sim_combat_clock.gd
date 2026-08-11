extends SceneTree
## Combat entities advance on SimClock (HTML single update clock).

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var pool := FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if pool.find("sim_tick") < 0 or pool.find("sim_step") < 0:
		print("[SIMC] FAIL BulletPool must drive bullet sim_step on sim_tick")
		ok = false
	else:
		print("[SIMC] BulletPool sim ok")
	var bul := FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	if bul.find("func sim_step") < 0:
		print("[SIMC] FAIL Bullet.sim_step missing")
		ok = false
	else:
		print("[SIMC] Bullet.sim_step ok")
	var en := FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if en.find("sim_tick") < 0 or en.find("_on_sim_tick") < 0:
		print("[SIMC] FAIL EnemyBase must connect SimClock")
		ok = false
	else:
		print("[SIMC] EnemyBase sim ok")
	var bo := FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if bo.find("sim_tick") < 0 or bo.find("_on_sim_tick") < 0:
		print("[SIMC] FAIL BossController must connect SimClock")
		ok = false
	else:
		print("[SIMC] Boss sim ok")
	var pl := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("sim_tick") < 0 or pl.find("_on_sim_tick") < 0:
		print("[SIMC] FAIL Player must connect SimClock")
		ok = false
	else:
		print("[SIMC] Player sim ok")
	# physics process should be disabled at ready for sim-driven combat
	if pl.find("set_physics_process(false)") < 0:
		print("[SIMC] FAIL Player should disable physics process for sim drive")
		ok = false
	else:
		print("[SIMC] Player physics off ok")
	if ok:
		print("[SIMC] PASS")
		quit(0)
	else:
		print("[SIMC] FAIL")
		quit(1)
