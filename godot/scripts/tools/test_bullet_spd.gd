extends SceneTree
## HTML SPD = (hard?1:0.8) * (1+stage*0.13) * threatMul()

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
	GS.stage_index = 0
	var n: float = BP._spd_mul()
	print("[SPD] NORMAL s0=", n, " expect 0.8")
	if absf(n - 0.8) > 0.001:
		ok = false
	GS.stage_index = 2
	var n2: float = BP._spd_mul()
	var exp_n2: float = 0.8 * (1.0 + 2.0 * 0.13)
	print("[SPD] NORMAL s2=", n2, " expect ", exp_n2)
	if absf(n2 - exp_n2) > 0.001:
		ok = false
	GS.difficulty = 1
	GS.apply_difficulty()
	GS.stage_index = 0
	var h: float = BP._spd_mul()
	print("[SPD] HARD s0=", h, " expect 1.0")
	if absf(h - 1.0) > 0.001:
		ok = false
	GS.difficulty = 2
	GS.apply_difficulty()
	var hell: float = BP._spd_mul()
	print("[SPD] HELL s0=", hell, " expect 1.28")
	if absf(hell - 1.28) > 0.001:
		ok = false
	GS.stage_index = 3
	var hell3: float = BP._spd_mul()
	var exp_h3: float = 1.28 * (1.0 + 3.0 * 0.13)
	print("[SPD] HELL s3=", hell3, " expect ", exp_h3)
	if absf(hell3 - exp_h3) > 0.001:
		ok = false
	GS.ng_plus = 2
	GS.stage_index = 0
	var hell_ng: float = BP._spd_mul()
	var exp_ng: float = 1.28 * (1.0 + 2.0 * 0.16)
	print("[SPD] HELL ng2 s0=", hell_ng, " expect ", exp_ng)
	if absf(hell_ng - exp_ng) > 0.001:
		ok = false
	if ok:
		print("[SPD] PASS")
		quit(0)
	else:
		print("[SPD] FAIL")
		quit(1)
