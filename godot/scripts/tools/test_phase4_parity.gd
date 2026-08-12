extends SceneTree
## Phase 4: combat helpers — power/score/rank/bomb constants + nearest_target gates.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var CH = root.get_node_or_null("/root/CombatHelpers")
	var GS = root.get_node_or_null("/root/GameState")
	if CH == null or GS == null:
		print("[P4] FAIL no autoloads"); quit(1); return

	# powerCap / powerGainMul by difficulty
	GS.difficulty = 0
	if absf(CH.power_cap() - 6.0) > 0.001 or absf(CH.power_gain_mul() - 1.0) > 0.001:
		print("[P4] FAIL power normal ", CH.power_cap(), CH.power_gain_mul()); ok = false
	GS.difficulty = 1
	if absf(CH.power_cap() - 5.5) > 0.001 or absf(CH.power_gain_mul() - 0.7) > 0.001:
		print("[P4] FAIL power hard"); ok = false
	GS.difficulty = 2
	if absf(CH.power_cap() - 4.5) > 0.001 or absf(CH.power_gain_mul() - 0.5) > 0.001:
		print("[P4] FAIL power hell"); ok = false
	GS.difficulty = 0

	# shotLevel
	GS.power = 1.0
	if CH.shot_level() != 1:
		print("[P4] FAIL shot_level 1"); ok = false
	GS.power = 3.9
	if CH.shot_level() != 3:
		print("[P4] FAIL shot_level floor"); ok = false
	GS.power = 9.0
	if CH.shot_level() != 5:
		print("[P4] FAIL shot_level cap 5"); ok = false
	GS.power = 1.0

	# scoreMult / threatMul
	GS.ng_plus = 0
	GS.difficulty = 0
	GS.hell_mode = false
	GS.hard_mode = false
	GS.total_kills = 0
	if absf(CH.score_mult() - 1.0) > 0.001:
		print("[P4] FAIL score_mult base ", CH.score_mult()); ok = false
	GS.total_kills = 25  # rank C index 1 → 1+0.5=1.5
	var sm: float = CH.score_mult()
	if absf(sm - 1.5) > 0.05:
		print("[P4] FAIL score_mult rank C ", sm); ok = false
	GS.ng_plus = 1
	GS.total_kills = 0
	if absf(CH.score_mult() - 2.0) > 0.05:
		print("[P4] FAIL score_mult ng+1 ", CH.score_mult()); ok = false
	GS.hell_mode = true
	if absf(CH.threat_mul() - 1.28 * (1.0 + 0.16)) > 0.01:
		print("[P4] FAIL threat hell ng1 ", CH.threat_mul()); ok = false
	GS.hell_mode = false
	GS.ng_plus = 0

	# ranks
	GS.total_kills = 0
	if CH.rank_letter() != "D":
		print("[P4] FAIL rank D"); ok = false
	GS.total_kills = 320
	if CH.rank_letter() != "SS":
		print("[P4] FAIL rank SS got ", CH.rank_letter()); ok = false
	GS.total_kills = 0

	# burst/sparks/pop counts
	CH.particles.clear()
	CH.score_texts.clear()
	CH.burst(0, 0, "#fff")
	if CH.particles.size() != 16:
		print("[P4] FAIL burst 16 got ", CH.particles.size()); ok = false
	CH.particles.clear()
	CH.sparks(0, 0, "#fff")
	if CH.particles.size() != 5:
		print("[P4] FAIL sparks 5"); ok = false
	CH.pop(1, 2, "X", "#f00")
	if CH.score_texts.is_empty() or float(CH.score_texts[-1].get("life", 0)) != 44.0:
		print("[P4] FAIL pop life 44"); ok = false

	# lineTime
	if absf(CH.line_time("ab") - minf(280.0, 90.0 + 2.0 * 2.7)) > 0.01:
		print("[P4] FAIL line_time"); ok = false
	if absf(CH.line_time("x".repeat(200)) - 280.0) > 0.01:
		print("[P4] FAIL line_time cap 280"); ok = false

	# addPower level up
	GS.power = 1.9
	CH.flash_msg = {}
	CH.add_power(0.2)  # gain mul 1 on normal → 2.1 → lv 2
	if CH.shot_level() < 2:
		print("[P4] FAIL add_power level ", GS.power, CH.shot_level()); ok = false
	GS.power = 1.0

	# gainLife overflow score
	var lives_was: int = GS.lives
	GS.lives = 9
	var sc_was: int = GS.session_score
	CH.gain_life()
	if GS.lives != 9 or GS.session_score < sc_was + 50000:
		print("[P4] FAIL gainLife max overflow"); ok = false
	GS.lives = lives_was

	# MAX_LIVES / MAX_BOMBS
	if CH.MAX_LIVES != 9 or CH.MAX_BOMBS != 5:
		print("[P4] FAIL MAX constants"); ok = false

	# source guards
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("invuln = maxf(invuln, 140.0)") < 0 and pl.find("140.0") < 0:
		print("[P4] FAIL bomb iframe 140"); ok = false
	if pl.find("bomb_fx = 46") < 0:
		print("[P4] FAIL bombFx 46"); ok = false
	if pl.find("0.09") < 0:
		print("[P4] FAIL bomb boss 9%"); ok = false
	if pl.find("respawn = 70") < 0:
		print("[P4] FAIL hit respawn 70"); ok = false
	if pl.find("shield_t - 120") < 0 and pl.find("shield_t = maxf(0.0, shield_t - 120") < 0:
		print("[P4] FAIL shield -120"); ok = false
	var nt: String = FileAccess.get_file_as_string("res://scripts/combat/CombatHelpers.gd")
	if nt.find("intro") < 0 or nt.find("bosses") < 0:
		print("[P4] FAIL nearest_target boss gates"); ok = false

	# option offsets
	var FS = load("res://scripts/combat/FireSystem.gd").new()
	var o2: Array = FS.option_offsets(2)
	if o2.size() != 1 or float(o2[0].x) != -16.0:
		print("[P4] FAIL optionOffsets lv2 ", o2); ok = false
	var o5: Array = FS.option_offsets(5)
	if o5.size() != 4:
		print("[P4] FAIL optionOffsets lv5 ", o5); ok = false

	# ang_diff
	if absf(CH.ang_diff(0.0, PI * 0.5) - PI * 0.5) > 0.001:
		print("[P4] FAIL ang_diff"); ok = false

	if ok:
		print("[P4] Phase 4 combat helpers PASS")
		quit(0)
	else:
		print("[P4] FAIL")
		quit(1)
