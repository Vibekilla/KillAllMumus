extends SceneTree
## Structural: death/slash/nade pure-despawn vs bulletCancelNear point-drops.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var pool_src: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if pool_src.find("func despawn_enemy_near") < 0:
		print("[BDESPAWN] FAIL missing despawn_enemy_near")
		ok = false
	if pool_src.find("drop_points") < 0:
		print("[BDESPAWN] FAIL clear_enemy_near needs drop_points flag")
		ok = false
	# despawn must not call drop_item
	var d0 := pool_src.find("func despawn_enemy_near")
	var d1 := pool_src.find("func filter_enemy_in_cone")
	if d0 < 0 or d1 < 0 or d1 <= d0:
		print("[BDESPAWN] FAIL cannot slice despawn body")
		ok = false
	else:
		var body := pool_src.substr(d0, d1 - d0)
		if body.find("drop_item") >= 0:
			print("[BDESPAWN] FAIL despawn must not drop point items")
			ok = false
		if body.find("bhp") >= 0 or body.find("hp > 0") >= 0:
			print("[BDESPAWN] FAIL despawn must remove shells too (HTML pure filter)")
			ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("despawn_enemy_near") < 0:
		print("[BDESPAWN] FAIL Player death/slash must use despawn_enemy_near")
		ok = false
	if pl.find("despawn_enemy_near(global_position, 100") < 0 and pl.find("despawn_enemy_near(global_position, 100.0") < 0:
		print("[BDESPAWN] FAIL hitPlayer 100px pure despawn")
		ok = false
	if pl.find("despawn_enemy_near(global_position, 34") < 0 and pl.find("despawn_enemy_near(global_position, 34.0") < 0:
		print("[BDESPAWN] FAIL slashDash 34px pure despawn")
		ok = false
	var it: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	if it.find("despawn_enemy_near") < 0:
		print("[BDESPAWN] FAIL nade/explode must use despawn")
		ok = false
	var end: String = FileAccess.get_file_as_string("res://scripts/ui/EndScreen.gd")
	if end.find("more this run") < 0:
		print("[BDESPAWN] FAIL win emblem list must cap + show overflow")
		ok = false
	if ok:
		print("[BDESPAWN] PASS")
		quit(0)
	else:
		print("[BDESPAWN] FAIL")
		quit(1)
