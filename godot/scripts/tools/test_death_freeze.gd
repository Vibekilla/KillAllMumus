extends SceneTree
## HTML freezes combat while p.dead (only respawn + updateItems).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var gs: String = FileAccess.get_file_as_string("res://autoload/GameState.gd")
	if gs.find("player_down") < 0:
		print("[DFREEZE] FAIL GameState.player_down missing")
		ok = false
	if gs.find("if player_down") < 0 and gs.find("player_down:") < 0:
		# must gate sim tick
		if gs.find("player_down") >= 0 and gs.find("_on_sim_tick") >= 0:
			var i := gs.find("func _on_sim_tick")
			var chunk := gs.substr(i, 800)
			if chunk.find("player_down") < 0:
				print("[DFREEZE] FAIL sim tick must early-return when player_down")
				ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("GameState.player_down = true") < 0:
		print("[DFREEZE] FAIL Player must set player_down on death")
		ok = false
	if pl.find("GameState.player_down = false") < 0:
		print("[DFREEZE] FAIL Player must clear player_down on respawn")
		ok = false
	# combat systems gate
	for path in [
		"res://scripts/enemies/EnemyBase.gd",
		"res://scripts/enemies/bosses/BossController.gd",
		"res://scripts/combat/Bullet.gd",
		"res://scripts/enemies/EnemySpawner.gd",
		"res://scripts/systems/SpecialSystem.gd",
		"res://scripts/combat/CombatHelpers.gd",
	]:
		var s: String = FileAccess.get_file_as_string(path)
		if s.find("player_down") < 0:
			print("[DFREEZE] FAIL ", path, " missing player_down freeze")
			ok = false
	# items still tick while down
	var it: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	if it.find("player_down") < 0:
		print("[DFREEZE] FAIL ItemSystem should keep items, skip burns when down")
		ok = false
	else:
		print("[DFREEZE] ItemSystem partial tick ok")
	if ok:
		print("[DFREEZE] PASS")
		quit(0)
	else:
		print("[DFREEZE] FAIL")
		quit(1)
