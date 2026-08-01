extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var IS = root.get_node_or_null("/root/ItemSystem")
	var GS = root.get_node_or_null("/root/GameState")
	var ok := true
	GS.difficulty = 0
	GS.ng_plus = 0
	var h0: int = IS.elite_hearts()
	print("[ELITE] N ng0=", h0, " expect 2")
	if h0 != 2:
		ok = false
	GS.difficulty = 2
	GS.ng_plus = 1
	var h1: int = IS.elite_hearts()
	print("[ELITE] HELL ng1=", h1, " expect 5")
	if h1 != 5:  # min(5, 2+2+1)=5
		ok = false
	var src: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if src.find("elite_hearts") < 0:
		print("[ELITE] FAIL body check must use elite_hearts")
		ok = false
	var ms: String = FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")
	if ms.find("mkills") < 0 or ms.find("melee_slayer") < 0 or ms.find("melee_all") < 0:
		print("[ELITE] FAIL melee emblem tracking")
		ok = false
	if ok:
		print("[ELITE] PASS")
		quit(0)
	else:
		print("[ELITE] FAIL")
		quit(1)
