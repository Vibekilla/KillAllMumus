extends SceneTree
## Blackhole: launch settle, boss chip no-pull, bullet spiral devour.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var sp: String = FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if sp.find("func _blackhole_tick") < 0:
		print("[BH] FAIL missing _blackhole_tick")
		ok = false
	if sp.find("dt_bh < 16") < 0 and sp.find("dt_bh < 16.0") < 0:
		print("[BH] FAIL launch window dt<16 missing")
		ok = false
	if sp.find("pull * 0.7") < 0 and sp.find("pull*0.7") < 0:
		print("[BH] FAIL boss range pull*0.7 missing")
		ok = false
	if sp.find("take_damage(3.0)") < 0 and sp.find("take_damage(3)") < 0:
		print("[BH] FAIL boss chip dmg 3 missing")
		ok = false
	# boss must not be in mob pull loop (is_in_group bosses continue)
	if sp.find("e.is_in_group(\"bosses\")") < 0:
		print("[BH] FAIL must skip bosses in mumu pull")
		ok = false
	var bp: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPool.gd")
	if bp.find("func blackhole_pull_bullets") < 0:
		print("[BH] FAIL blackhole_pull_bullets missing")
		ok = false
	if bp.find("0.9") < 0 or bp.find("2.4") < 0:
		print("[BH] FAIL spiral gravity constants missing")
		ok = false
	# must not use simple clear_enemy_near as primary path for BH
	var bi := sp.find("\"blackhole\":")
	var be := sp.find("\"wave\":", bi)
	if bi >= 0 and be > bi:
		var body := sp.substr(bi, be - bi)
		if body.find("clear_enemy_near") >= 0 and body.find("blackhole_pull") < 0:
			print("[BH] FAIL still using clear_enemy_near only for BH")
			ok = false
	if ok:
		print("[BH] PASS")
		quit(0)
	else:
		print("[BH] FAIL")
		quit(1)
