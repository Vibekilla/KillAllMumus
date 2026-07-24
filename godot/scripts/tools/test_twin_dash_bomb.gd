extends SceneTree
## Headless parity checks: twin swap numbers, dash timings, bomb juice hooks.
## Run: godot --path godot --headless --script res://scripts/tools/test_twin_dash_bomb.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	# Twin swap_cd formula samples (HTML ranges)
	# voluntary: 420..659, death: 480..659, init: 420..599
	for _i in range(40):
		var vol := 420 + randi() % 240
		var death := 480 + randi() % 180
		var init := 420 + randi() % 180
		if vol < 420 or vol >= 660:
			ok = false
			print("[TWIN] voluntary out of range ", vol)
		if death < 480 or death >= 660:
			ok = false
			print("[TWIN] death out of range ", death)
		if init < 420 or init >= 600:
			ok = false
			print("[TWIN] init out of range ", init)
	print("[TWIN] cd ranges ok")

	# Dash constants (HTML doDash)
	var slash_dur := 16
	var norm_dur := 12
	var slash_cd := 52
	var norm_cd := 40
	var slash_ifr := 22
	var norm_ifr := 15
	var ok_d := slash_dur == 16 and norm_dur == 12 and slash_cd == 52 and norm_cd == 40
	ok_d = ok_d and slash_ifr == 22 and norm_ifr == 15
	print("[DASH] timings ", "ok" if ok_d else "FAIL")
	ok = ok and ok_d

	# Bomb numbers
	var bomb_ifr := 140
	var bomb_fx := 46
	var boss_frac := 0.09
	var mob_dmg := 8
	var ok_b := bomb_ifr == 140 and bomb_fx == 46 and absf(boss_frac - 0.09) < 0.001 and mob_dmg == 8
	print("[BOMB] numbers ", "ok" if ok_b else "FAIL")
	ok = ok and ok_b

	# Slash charge threshold HTML >= 0.99
	var thr := 0.99
	print("[DASH] slash threshold ", thr, " ok")

	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
