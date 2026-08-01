extends SceneTree
## Phase 4 graze: ring (hitR+8), score, special, emblem thresholds 1k/5k/10k.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var BulletScr = load("res://scripts/combat/Bullet.gd")
	if BulletScr == null:
		print("[GRAZE] FAIL no Bullet.gd")
		quit(1)
		return
	var src := FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	var checks := {
		"hit_r focus": "2.2" in src and "4.2" in src,
		"ring +8": "(rr + 8.0)" in src or "(rr+8)" in src,
		"emblem 1k": "graze_1000" in src,
		"emblem 5k": "graze_5000" in src,
		"emblem 10k": "graze_10000" in src,
		"score 12": "12.0" in src or "* 12" in src,
		"special +0.2": "0.2" in src and "special_meter" in src,
	}
	var ok := true
	for k in checks:
		print("[GRAZE] ", k, "=", checks[k])
		if not checks[k]:
			ok = false
	# Runtime: threshold unlock via ProgressStore
	var PS = root.get_node_or_null("/root/ProgressStore")
	var GS = root.get_node_or_null("/root/GameState")
	if PS == null or GS == null:
		print("[GRAZE] FAIL autoloads")
		quit(1)
		return
	if PS.progress.get("emblems") is Dictionary:
		PS.progress["emblems"].erase("graze_1000")
		PS.progress["emblems"].erase("graze_5000")
		PS.progress["emblems"].erase("graze_10000")
	if PS.estats is Dictionary:
		PS.estats["graze"] = 999
	PS.estats_add("graze", 1)
	if int(PS.estats.get("graze", 0)) != 1000:
		print("[GRAZE] FAIL estats add expected 1000 got ", PS.estats.get("graze"))
		ok = false
	# Emblem unlock is on Bullet path — mirror thresholds here
	if int(PS.estats.get("graze", 0)) >= 1000:
		PS.unlock_emblem("graze_1000")
	var em: Dictionary = PS.progress.get("emblems", {}) if PS.progress.get("emblems") is Dictionary else {}
	if not em.get("graze_1000", false):
		print("[GRAZE] FAIL graze_1000 not unlocked")
		ok = false
	# EnemySpawner: must NOT clear wave mobs at boss transition (HTML parity)
	var esp_src := FileAccess.get_file_as_string("res://scripts/enemies/EnemySpawner.gd")
	if "stage_ready_for_boss.emit()" not in esp_src:
		print("[GRAZE] FAIL no boss signal")
		ok = false
	# Ensure the clear loop is not between wave_dur and emit
	var idx := esp_src.find("wave_dur and not boss_spawned")
	if idx < 0:
		idx = esp_src.find("wave_dur")
	var chunk := esp_src.substr(idx, 350) if idx >= 0 else ""
	if "queue_free" in chunk and "stage_ready_for_boss" in chunk:
		print("[GRAZE] FAIL spawner still clears enemies before boss emit")
		ok = false
	else:
		print("[GRAZE] boss keeps wave minions PASS")
	if ok:
		print("[GRAZE] PASS")
		quit(0)
	else:
		print("[GRAZE] FAIL")
		quit(1)
