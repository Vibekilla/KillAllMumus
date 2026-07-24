extends SceneTree
## Cloud merge must not wipe local progress; charm explode is enemyExplode.
## Run: godot --path godot --headless --script res://scripts/tools/test_merge_charm.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var src := FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
	if "progress = remote.duplicate" in src:
		print("[FAIL] merge_from_cloud must not replace progress with remote.duplicate")
		ok = false
	else:
		print("[CLOUD] no wholesale replace ok")
	if "heads_local" not in src or "heads_remote" not in src:
		print("[FAIL] heads max missing")
		ok = false
	else:
		print("[CLOUD] heads max ok")
	if "merged_ar" not in src:
		print("[FAIL] arsenal merge missing")
		ok = false
	else:
		print("[CLOUD] arsenal merge ok")
	# Runtime merge via root autoload
	var ps = root.get_node_or_null("/root/ProgressStore")
	if ps == null:
		print("[WARN] ProgressStore autoload not ready — skip runtime")
	else:
		var before_heads := int(ps.progress.get("heads", 0))
		ps.progress["heads"] = 10
		ps.emblems["first_mumu"] = true
		ps.merge_from_cloud({
			"heads": 5,
			"emblems": {"boss_first": true},
			"estats": {"kills": 99},
			"arsenal": {"w": ["laser", "void"], "s": [], "m": [], "i": []},
			"consum": {"honeycomb": 3},
			"ngUnlocked": 2,
			"settings": {"music": 50},
		})
		if int(ps.progress.get("heads", 0)) < 10:
			print("[FAIL] heads should stay max local=", ps.progress.get("heads"))
			ok = false
		else:
			print("[CLOUD] heads keep max ok")
		if not ps.emblems.get("first_mumu", false) or not ps.emblems.get("boss_first", false):
			print("[FAIL] emblem union failed")
			ok = false
		else:
			print("[CLOUD] emblem union ok")
		if int(ps.estats.get("kills", 0)) < 99:
			print("[FAIL] estats max failed")
			ok = false
		else:
			print("[CLOUD] estats max ok")
		ps.progress["heads"] = before_heads
	var eb := FileAccess.get_file_as_string("res://scripts/enemies/EnemyBase.gd")
	if "_enemy_explode" not in eb:
		print("[FAIL] missing _enemy_explode")
		ok = false
	else:
		print("[CHARM] enemy_explode ok")
	if "take_damage(6.0)" not in eb:
		print("[FAIL] explode AoE 6 missing")
		ok = false
	else:
		print("[CHARM] AoE 6 ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
