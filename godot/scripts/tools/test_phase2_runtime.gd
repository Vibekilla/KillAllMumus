extends SceneTree
## Phase 2 runtime: arsenal mutate, mode_tag, fmtScore, caps, new_run constants.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var MH = load("res://scripts/ui/menu/MenuHelpers.gd")
	var cap: Dictionary = MH.ARS_CAP
	if int(cap.w) != 5 or int(cap.s) != 5 or int(cap.m) != 2 or int(cap.i) != 3:
		print("[P2R] FAIL ARS_CAP ", cap); ok = false

	# fmtScore parity samples
	var samples := {
		0: "0", 999: "999", 1000: "1K", 1500: "1.5K", 10000: "10K",
		1000000: "1M", 1500000: "1.5M", 123456789: "123M"
	}
	for n in samples.keys():
		var got: String = MH.fmt_score(n)
		var exp: String = str(samples[n])
		# 123456789 → 123.456789M rounds: HTML toFixed for >=100 is 0 decimals → 123M
		if got != exp:
			# allow 1.50K style stripped
			print("[P2R] FAIL fmt_score(", n, ") got=", got, " expect=", exp)
			ok = false

	var GS = root.get_node_or_null("/root/GameState")
	var PS = root.get_node_or_null("/root/ProgressStore")
	var P2 = root.get_node_or_null("/root/P2Meta")
	if GS == null or PS == null or P2 == null:
		print("[P2R] FAIL missing autoloads"); quit(1); return

	# modeTag
	GS.difficulty = 0; GS.ng_plus = 0
	if GS.mode_tag() != "NORMAL":
		print("[P2R] FAIL mode NORMAL"); ok = false
	GS.difficulty = 1; GS.ng_plus = 0
	if GS.mode_tag() != "HARD":
		print("[P2R] FAIL mode HARD"); ok = false
	GS.difficulty = 2; GS.ng_plus = 7
	if GS.mode_tag() != "HELL+7":
		print("[P2R] FAIL mode HELL+7 got ", GS.mode_tag()); ok = false
	GS.difficulty = 0; GS.ng_plus = 0
	GS.apply_difficulty()
	if GS.hard_mode or GS.hell_mode:
		print("[P2R] FAIL applyDiff clear"); ok = false
	GS.difficulty = 2
	GS.apply_difficulty()
	if not GS.hell_mode or not GS.hard_mode:
		print("[P2R] FAIL applyDiff hell"); ok = false
	GS.difficulty = 0
	GS.apply_difficulty()

	# arsenal toggle + drop + caps
	PS.progress["arsenal"] = {"w": ["laser"], "s": ["mech"], "m": ["katana"], "i": []}
	P2.toggle_arsenal("w", "spread")
	var w: Array = P2.ars_arr("w")
	if w.find("spread") < 0 or w.find("laser") < 0:
		print("[P2R] FAIL toggle equip spread got ", w); ok = false
	P2.toggle_arsenal("w", "spread")
	w = P2.ars_arr("w")
	if w.find("spread") >= 0:
		print("[P2R] FAIL toggle unequip spread"); ok = false
	# cannot unequip last weapon
	P2.toggle_arsenal("w", "laser")
	w = P2.ars_arr("w")
	if w.is_empty() or w[0] != "laser":
		print("[P2R] FAIL minKeep weapon ", w); ok = false
	# specials can go empty
	P2.toggle_arsenal("s", "mech")
	var s: Array = P2.ars_arr("s")
	if s.find("mech") >= 0:
		print("[P2R] FAIL special unequip"); ok = false
	# dropToSlot
	PS.progress["arsenal"] = {"w": ["laser"], "s": [], "m": ["katana"], "i": []}
	P2.drop_to_slot("w", "homing", 0)
	w = P2.ars_arr("w")
	if w.size() < 1 or str(w[0]) != "homing":
		# if laser still first and homing second when not replace — HTML insert at slot
		# laser present, insert at 0 → [homing, laser]
		if w.size() < 2 or str(w[0]) != "homing":
			print("[P2R] FAIL drop_to_slot got ", w); ok = false
	# fill to cap 5 then replace
	PS.progress["arsenal"] = {"w": ["laser", "spread", "homing", "wave", "scatter"], "s": [], "m": ["katana"], "i": []}
	P2.drop_to_slot("w", "gatling", 2)
	w = P2.ars_arr("w")
	if w.size() != 5 or str(w[2]) != "gatling":
		print("[P2R] FAIL drop replace slot2 got ", w); ok = false

	# start_run constants
	GS.start_run()
	if GS.lives != 6 or GS.bombs != 3:
		print("[P2R] FAIL lives/bombs ", GS.lives, GS.bombs); ok = false
	if absf(GS.power - 1.0) > 0.001 or absf(GS.special_meter - 15.0) > 0.001:
		print("[P2R] FAIL power/special ", GS.power, GS.special_meter); ok = false
	if GS.stage_index != 0 or GS.state != GS.State.INTRO:
		print("[P2R] FAIL stage/state ", GS.stage_index, GS.state); ok = false
	if GS.weapons.is_empty():
		print("[P2R] FAIL weapons empty after start"); ok = false

	# arsenalCount = w+s
	PS.progress["arsenal"] = {"w": ["laser", "spread"], "s": ["mech", "bearzooka"], "m": ["katana"], "i": []}
	var ac: int = P2.arsenal_count()
	if ac != 4:
		print("[P2R] FAIL arsenal_count ", ac); ok = false

	if ok:
		print("[P2R] Phase 2 runtime PASS")
		quit(0)
	else:
		print("[P2R] FAIL")
		quit(1)
