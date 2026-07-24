extends SceneTree
## Special trickle 0.012/frame + hitPlayer constants (HTML).
## Run: godot --path godot --headless --script res://scripts/tools/test_hit_special.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	# Special trickle rate
	var trickle := 0.012
	var per_sec := trickle * 60.0
	print("[SPECIAL] trickle/frame=", trickle, " ≈", per_sec, "/s")
	if absf(trickle - 0.012) > 0.0001:
		ok = false
	# Fire must NOT add special (source contract)
	var psrc := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if "special_meter + delta" in psrc or "special_meter += delta" in psrc:
		print("[FAIL] Player still charges special on fire")
		ok = false
	else:
		print("[SPECIAL] no per-fire charge ok")
	var gsrc := FileAccess.get_file_as_string("res://autoload/GameState.gd")
	if "special_meter + 0.012" not in gsrc:
		print("[FAIL] GameState missing 0.012 special trickle")
		ok = false
	else:
		print("[SPECIAL] GameState trickle ok")
	# hitPlayer constants
	if "invuln, 26.0" not in psrc and "maxf(invuln, 26.0)" not in psrc:
		print("[FAIL] vial iframe should be 26")
		ok = false
	else:
		print("[HIT] vial iframe 26 ok")
	if "shield_t - 120.0" not in psrc and "shield_t - 120" not in psrc:
		print("[FAIL] shield should chip 120 frames")
		ok = false
	else:
		print("[HIT] shield chip 120 ok")
	if "respawn = 70.0" not in psrc:
		print("[FAIL] death respawn should be 70")
		ok = false
	else:
		print("[HIT] respawn 70 ok")
	if "_respawn_player" not in psrc:
		print("[FAIL] missing _respawn_player")
		ok = false
	else:
		print("[HIT] respawn path ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
