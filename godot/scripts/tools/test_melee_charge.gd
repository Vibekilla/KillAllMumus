extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var ms: String = FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")
	var bp: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	var ok := true
	if ms.find("1.05") < 0 or ms.find("0.15") < 0 or ms.find("78.0") < 0:
		print("[MELEE] FAIL flame burn params half+0.15 reach*1.05 life78")
		ok = false
	if ms.find("take_damage(dmg * 0.5)") >= 0 and ms.find("\"flame\"") < ms.find("take_damage(dmg * 0.5)"):
		# ensure flame path no longer has extra dmg*0.5 immediately after flame
		var fi := ms.find("\"flame\":")
		var chunk := ms.substr(fi, 250)
		if chunk.find("take_damage") >= 0:
			print("[MELEE] FAIL flame still applies extra take_damage")
			ok = false
	if ms.find("flurry = 30") < 0 and ms.find("flurry\", 30") < 0:
		print("[MELEE] FAIL flurry charge must set p.flurry=30")
		ok = false
	if bp.find("cnt < 28") < 0:
		print("[MELEE] FAIL melee_deflect point drop cap 28")
		ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("func _flurry_tick") < 0:
		print("[MELEE] FAIL missing _flurry_tick")
		ok = false
	if ok:
		print("[MELEE] PASS")
		quit(0)
	else:
		print("[MELEE] FAIL")
		quit(1)
