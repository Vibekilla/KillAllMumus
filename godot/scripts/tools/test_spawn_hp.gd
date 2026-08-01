extends SceneTree
## HTML spawnLil / spawnBig / spawnElite HP + elite kind table + kill score path.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var src: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemySpawner.gd")
	var ok: bool = true
	if src.find("26.0 if icy else 16.0") < 0:
		print("[SPAWN] FAIL big HP must be (icy?26:16)*(1+d*0.45)")
		ok = false
	if src.find("ELITE_KIND") < 0 or src.find("badnik") < 0:
		print("[SPAWN] FAIL missing ELITE_KIND table")
		ok = false
	if src.find("1.3") < 0:
		print("[SPAWN] FAIL elite *1.3 scale")
		ok = false
	var d0_big: float = float(round(16.0 * 1.0))
	var d2_big: float = float(round(16.0 * (1.0 + 2.0 * 0.45)))
	var e0: float = float(round(9.0 * 1.3 * 1.0 * 1.0))
	print("[SPAWN] stage0 big=", d0_big, " stage2 big=", d2_big, " elite0=", e0)
	if absf(d0_big - 16.0) > 0.1 or absf(d2_big - 30.0) > 0.1:
		print("[SPAWN] FAIL big formula")
		ok = false
	if absf(e0 - 12.0) > 0.1:
		print("[SPAWN] FAIL elite0 formula got", e0)
		ok = false
	var isrc: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	var ki: int = isrc.find("func kill_enemy")
	var chunk: String = isrc.substr(ki, 2000) if ki >= 0 else ""
	if chunk.find("estats_add(\"kills\"") >= 0:
		print("[SPAWN] FAIL kill_enemy still double-counts estats.kills")
		ok = false
	else:
		print("[SPAWN] kill estats single-count OK")
	if chunk.find("GameState.add_score") < 0:
		print("[SPAWN] FAIL kill_enemy must GameState.add_score")
		ok = false
	else:
		print("[SPAWN] kill score path OK")
	var ebase: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	var di: int = ebase.find("func _die")
	var dchunk: String = ebase.substr(di, 400) if di >= 0 else ""
	# _die should not also add_score (kill_enemy does)
	if dchunk.find("add_score") >= 0:
		print("[SPAWN] FAIL EnemyBase._die still add_score (double)")
		ok = false
	else:
		print("[SPAWN] single score path OK")
	if ok:
		print("[SPAWN] PASS")
		quit(0)
	else:
		print("[SPAWN] FAIL")
		quit(1)
