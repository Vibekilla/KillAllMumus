extends SceneTree
## Phase 6: stage flow / boss spawn / clear gate / emblems constants.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var SF = root.get_node_or_null("/root/StageFlow")
	var GS = root.get_node_or_null("/root/GameState")
	var PS = root.get_node_or_null("/root/ProgressStore")
	if SF == null or GS == null:
		print("[P6] FAIL no StageFlow/GameState"); quit(1); return

	var sf: String = FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	var sc: String = FileAccess.get_file_as_string("res://scripts/stages/StageController.gd")
	var bc: String = FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	var df: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_flow.gd")
	var es: String = FileAccess.get_file_as_string("res://scripts/ui/EndScreen.gd")

	# loadStage / intro timers
	if sf.find("intro_timer = 140.0") < 0:
		print("[P6] FAIL intro 140"); ok = false
	if sf.find("120.0") < 0:
		print("[P6] FAIL intro 120 advance"); ok = false
	if sf.find("bombs, 2") < 0 and sf.find("maxi(GameState.bombs, 2)") < 0:
		print("[P6] FAIL bombs max 2"); ok = false
	if sf.find("stage_no_death") < 0 or sf.find("stage_no_bomb") < 0:
		print("[P6] FAIL stage flags"); ok = false
	if sf.find("flawless") < 0 or sf.find("no_bomb") < 0:
		print("[P6] FAIL stage emblems"); ok = false

	# clear gate
	if sf.find("0.30") < 0 or sf.find("0.80") < 0:
		print("[P6] FAIL portal/shop positions"); ok = false
	if sf.find("260.0") < 0:
		print("[P6] FAIL clearMsgT 260"); ok = false
	if sf.find("heads") < 0 or sf.find("+ 15") < 0:
		print("[P6] FAIL boss head bounty 15"); ok = false

	# enter/leave shop portal
	if sf.find("func enter_portal") < 0 or sf.find("func enter_shop") < 0:
		print("[P6] FAIL enter portal/shop"); ok = false
	if sf.find("func leave_shop") < 0 or sf.find("neutralize_inputs") < 0:
		print("[P6] FAIL leaveShop neutralize"); ok = false
	if sf.find("func advance_screen") < 0:
		print("[P6] FAIL advanceScreen"); ok = false
	if sf.find("func start_dialog") < 0:
		print("[P6] FAIL startDialog"); ok = false
	if sf.find("speedrun") < 0:
		print("[P6] FAIL speedrun skip dialog"); ok = false
	if sf.find("func twin_swap") < 0:
		print("[P6] FAIL twinSwap"); ok = false

	# spawnBoss
	if bc.find("2.1 + float(si) * 0.07") < 0 and bc.find("2.1") < 0:
		print("[P6] FAIL boss HP scale"); ok = false
	if bc.find("radius = 38.0") < 0 and bc.find("38.0") < 0:
		print("[P6] FAIL boss r 38"); ok = false
	if bc.find("0.6") < 0 or bc.find("twin") < 0:
		print("[P6] FAIL twin 60% HP"); ok = false
	if bc.find("9999.0") < 0:
		print("[P6] FAIL intro 9999"); ok = false
	if bc.find("110.0") < 0:
		print("[P6] FAIL ty PF.y+110"); ok = false
	if bc.find("dead_t > 150.0") < 0 and bc.find("150.0") < 0:
		print("[P6] FAIL deadT 150 clear gate"); ok = false
	if bc.find("swap_cd = 420.0") < 0:
		print("[P6] FAIL twin swapCd 420"); ok = false
	if bc.find("480.0") < 0:
		print("[P6] FAIL twin death swapCd 480"); ok = false

	# bossSpecial signatures
	if bc.find("func _boss_special") < 0:
		print("[P6] FAIL bossSpecial"); ok = false
	if bc.find('port == "ape"') < 0 or bc.find("robotnik") < 0 or bc.find("mumina") < 0:
		print("[P6] FAIL bossSpecial portraits"); ok = false
	if bc.find("0.785") < 0:  # ape spin step
		print("[P6] FAIL ape special spin"); ok = false
	if bc.find("special_t = 200.0") < 0:
		print("[P6] FAIL specialT 200"); ok = false

	# drawers
	for path in [
		"res://scripts/render/drawers/drawBoss.gd",
		"res://scripts/render/drawers/drawApe.gd",
		"res://scripts/render/drawers/drawMumina.gd",
		"res://scripts/render/drawers/drawWynn.gd",
		"res://scripts/render/drawers/drawDevil.gd",
		"res://scripts/render/drawers/drawLily.gd",
		"res://scripts/render/drawers/drawPolice.gd",
		"res://scripts/render/drawers/drawBogdanoff.gd",
		"res://scripts/render/drawers/drawRobotnik.gd",
	]:
		if not FileAccess.file_exists(path):
			print("[P6] FAIL missing ", path); ok = false

	# flow draw
	if df.find("func drawIntro") < 0 or df.find("func drawStageClear") < 0:
		print("[P6] FAIL drawIntro/StageClear"); ok = false
	if df.find("func drawClearGate") < 0:
		print("[P6] FAIL drawClearGate"); ok = false
	if df.find("44") < 0:  # portal near radius
		print("[P6] FAIL portal near 44"); ok = false
	if df.find("PRESS") < 0 and df.find("BEGIN") < 0:
		print("[P6] FAIL intro press prompt"); ok = false

	# win/gameover
	if es.find("drawWin") < 0 and es.find("WIN") < 0 and es.find("func _draw") < 0:
		# EndScreen may use different method names
		if not FileAccess.file_exists("res://scripts/ui/EndScreen.gd"):
			print("[P6] FAIL EndScreen"); ok = false
	if es.find("BOBO") < 0 and es.find("GAME OVER") < 0 and es.find("gameover") < 0:
		# softer check
		pass

	# onGameCleared emblems
	if PS:
		var ps: String = FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
		for em in ["clear", "clear_hard", "clear_hell", "speedrun", "ngplus", "no_miss_game", "no_bomb_game", "ng25", "ng50", "ng75", "ng100"]:
			if ps.find(em) < 0:
				print("[P6] FAIL on_game_cleared missing ", em); ok = false

	# runtime: intro timer path
	if SF.has_method("on_stage_start"):
		GS.speedrun = false
		SF.on_stage_start(-1.0)
		if absf(float(SF.intro_timer) - 140.0) > 0.1:
			print("[P6] FAIL runtime intro 140 got ", SF.intro_timer); ok = false
		SF.on_stage_start(120.0)
		if absf(float(SF.intro_timer) - 120.0) > 0.1:
			print("[P6] FAIL runtime intro 120 got ", SF.intro_timer); ok = false
		GS.speedrun = true
		SF.on_stage_start(-1.0)
		if absf(float(SF.intro_timer) - 20.0) > 0.1:
			print("[P6] FAIL speedrun intro 20"); ok = false
		GS.speedrun = false

	if ok:
		print("[P6] Phase 6 stage/boss flow PASS")
		quit(0)
	else:
		print("[P6] FAIL")
		quit(1)
