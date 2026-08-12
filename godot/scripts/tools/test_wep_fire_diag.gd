extends SceneTree
## Diagnose weapon dual fire: does try_fire spawn active pshots?
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	await process_frame
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var GS = root.get_node_or_null("/root/GameState")
	GS.start_run()
	GS.set_state(GS.State.PLAY)
	GS.power = 6.0
	GS.weapons = ["spread","laser","homing","wave","scatter","gatling","grenade","voidripper","lotus","shock"]
	GS.current_weapon = "spread"
	await process_frame
	var player = root.get_tree().get_first_node_in_group("player")
	if player == null:
		print("[DIAG] no player"); quit(1); return
	player.global_position = Vector2(304, 400)
	player.aim = -PI/2
	player.invuln = 99999.0
	var pool = player.get("bullet_pool")
	var fire = player.get("fire_sys")
	print("[DIAG] player=", player, " pool=", pool, " fire=", fire)
	print("[DIAG] fire methods=", fire.get_method_list().map(func(m): return m.name) if fire else [])
	if fire and "fire_cd_frames" in fire:
		fire.fire_cd_frames = 0.0
	var ok = false
	if fire and pool:
		ok = fire.try_fire(player, pool, false)
	print("[DIAG] try_fire returned ", ok)
	await process_frame
	var n = 0
	var pshots = 0
	if pool and pool.has_method("iter_active"):
		for b in pool.iter_active():
			n += 1
			var team = b.get("team") if b.get("team") != null else -1
			var ps = b.get("pshot") if b.get("pshot") != null else b.get_meta("pshot", false) if b.has_meta("pshot") else false
			print("[DIAG] bullet team=", team, " pshot=", ps, " pos=", b.global_position if b is Node2D else "?", " vel=", b.get("velocity"))
			if int(team) == 0:
				pshots += 1
	print("[DIAG] active=", n, " pshots=", pshots)
	# fire 10 times like dual
	for i in range(10):
		if fire and "fire_cd_frames" in fire:
			fire.fire_cd_frames = 0.0
		fire.try_fire(player, pool, false)
		await process_frame
	n = 0
	if pool and pool.has_method("iter_active"):
		for b in pool.iter_active():
			n += 1
	print("[DIAG] after 10 bursts active=", n)
	quit(0 if n > 0 else 2)
