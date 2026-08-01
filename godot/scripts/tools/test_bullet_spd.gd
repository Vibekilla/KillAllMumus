extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var BP = load("res://scripts/combat/BulletPatterns.gd")
	var GS = root.get_node_or_null("/root/GameState")
	var ok := true
	GS.difficulty = 0
	GS.apply_difficulty()
	GS.ng_plus = 0
	var n: float = BP._spd_mul()
	print("[SPD] NORMAL ng0=", n, " expect 0.8")
	if absf(n - 0.8) > 0.001:
		ok = false
	GS.difficulty = 1
	GS.apply_difficulty()
	var h: float = BP._spd_mul()
	print("[SPD] HARD ng0=", h, " expect 1.0")
	if absf(h - 1.0) > 0.001:
		ok = false
	GS.difficulty = 2
	GS.apply_difficulty()
	var hell: float = BP._spd_mul()
	print("[SPD] HELL ng0=", hell, " expect 1.28")
	if absf(hell - 1.28) > 0.001:
		ok = false
	GS.ng_plus = 2
	var hell2: float = BP._spd_mul()
	# 1.0 * 1.28 * (1+0.32) = 1.28*1.32
	var exp2: float = 1.28 * (1.0 + 2.0 * 0.16)
	print("[SPD] HELL ng2=", hell2, " expect ", exp2)
	if absf(hell2 - exp2) > 0.001:
		ok = false
	if ok:
		print("[SPD] PASS")
		quit(0)
	else:
		print("[SPD] FAIL")
		quit(1)
