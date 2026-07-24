extends SceneTree
## Phase 4: HTML bossDmgMul / bossWepMul parity.

func _init() -> void:
	call_deferred("go")

func go() -> void:
	await process_frame
	var CH: Node = root.get_node_or_null("/root/CombatHelpers")
	var GS: Node = root.get_node_or_null("/root/GameState")
	if CH == null or GS == null:
		print("[BOSSMUL] FAIL missing autoload")
		quit(1)
		return
	var ok := true
	# bossDmgMul at power 1 → 1.0
	GS.power = 1.0
	var m1: float = CH.boss_dmg_mul()
	print("[BOSSMUL] power1 bm=", m1, " expect 1.0")
	if absf(m1 - 1.0) > 0.001:
		ok = false
	# power 6 → 1 - 0.55 = 0.45
	GS.power = 6.0
	var m6: float = CH.boss_dmg_mul()
	print("[BOSSMUL] power6 bm=", m6, " expect 0.45")
	if absf(m6 - 0.45) > 0.001:
		ok = false
	# power 3 → 1 - 0.22 = 0.78
	GS.power = 3.0
	var m3: float = CH.boss_dmg_mul()
	print("[BOSSMUL] power3 bm=", m3, " expect 0.78")
	if absf(m3 - 0.78) > 0.001:
		ok = false
	# bossWepMul laser NORMAL
	GS.difficulty = 0
	GS.current_weapon = "laser"
	var wl: float = CH.boss_wep_mul("laser")
	print("[BOSSMUL] laser N=", wl, " expect 0.8")
	if absf(wl - 0.8) > 0.001:
		ok = false
	GS.difficulty = 2
	var wl_h: float = CH.boss_wep_mul("laser")
	print("[BOSSMUL] laser HELL=", wl_h, " expect 0.48")
	if absf(wl_h - 0.48) > 0.001:
		ok = false
	# scale: voidbolt vs normal at power 6 laser hell
	GS.power = 6.0
	GS.difficulty = 2
	var d_norm: float = CH.scale_boss_shot_damage(10.0, false, "laser")
	var d_void: float = CH.scale_boss_shot_damage(10.0, true, "laser")
	# norm: 10 * 0.45 * 0.48 = 2.16 ; void: 10 * 0.3 * 0.45 = 1.35
	print("[BOSSMUL] scale norm=", d_norm, " expect 2.16 void=", d_void, " expect 1.35")
	if absf(d_norm - 2.16) > 0.02 or absf(d_void - 1.35) > 0.02:
		ok = false
	if ok:
		print("[BOSSMUL] PASS")
		quit(0)
	else:
		print("[BOSSMUL] FAIL")
		quit(1)
