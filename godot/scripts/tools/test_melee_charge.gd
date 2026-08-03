extends SceneTree
## Melee charge rate + charge FX parity vs HTML.
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
	# HTML: meleeChg += 1/48 per frame while held (~0.8s to full)
	if ms.find("/ 48.0") < 0 and ms.find("/48") < 0 and ms.find("1.0 / 48") < 0:
		print("[MELEE] FAIL charge rate must be +1/48 per frame (HTML)")
		ok = false
	else:
		print("[MELEE] charge rate 1/48 ok")
	# Must not use the old slow rate 0.85/s as primary hold charge
	if ms.find("charge + delta * 0.85") >= 0:
		print("[MELEE] FAIL still using delta*0.85 charge (too slow)")
		ok = false
	# Runtime: 48 frames at 1/60s should reach ~1.0
	var Melee = load("res://scripts/systems/MeleeSystem.gd")
	if Melee:
		var m = Melee.new()
		m.begin_hold()
		for i in range(48):
			m.tick(1.0 / 60.0)
		if m.charge < 0.99:
			print("[MELEE] FAIL charge after 48 frames=", m.charge, " want ~1.0")
			ok = false
		else:
			print("[MELEE] 48f full charge=", m.charge)
	if ok:
		print("[MELEE] PASS")
		quit(0)
	else:
		print("[MELEE] FAIL")
		quit(1)
