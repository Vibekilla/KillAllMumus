extends SceneTree
## Vault hammer fling: e.flung flight + wall detonate (HTML enemyExplode).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var eb: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if eb.find("var flung") < 0:
		print("[FLUNG] FAIL missing flung field")
		ok = false
	if eb.find("flung_vel") < 0:
		print("[FLUNG] FAIL missing flung_vel")
		ok = false
	if eb.find("0.92") < 0:
		print("[FLUNG] FAIL velocity decay 0.92 missing")
		ok = false
	if eb.find("PF.x+12") < 0 and eb.find("position.x + 12") < 0 and eb.find("+ 12.0") < 0:
		print("[FLUNG] FAIL wall edge check missing")
		ok = false
	# wall hit must explode (charmed die path or enemy_explode)
	if eb.find("_die(true)") < 0 and eb.find("_enemy_explode") < 0:
		print("[FLUNG] FAIL wall must detonate")
		ok = false
	var ms: String = FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")
	if ms.find("flung = 44") < 0 and ms.find("flung\", 44") < 0:
		print("[FLUNG] FAIL shockwall must set flung=44")
		ok = false
	if ms.find("global_position +=") >= 0 and ms.find("flung_vel") < 0:
		# allow other += elsewhere; check shockwall block
		pass
	var si := ms.find("\"shockwall\":")
	var se := ms.find("\"flurry\":", si)
	if si >= 0 and se > si:
		var body := ms.substr(si, se - si)
		if body.find("flung") < 0:
			print("[FLUNG] FAIL shockwall body missing flung")
			ok = false
		if body.find("global_position +=") >= 0 and body.find("flung_vel") < 0:
			print("[FLUNG] FAIL shockwall still one-shot shove instead of flung vel")
			ok = false
	var df: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_flow.gd")
	if df.find("BEYOND:") < 0:
		print("[FLUNG] FAIL portal BEYOND label missing")
		ok = false
	if ok:
		print("[FLUNG] PASS")
		quit(0)
	else:
		print("[FLUNG] FAIL")
		quit(1)
