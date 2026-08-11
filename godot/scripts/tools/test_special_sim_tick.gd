extends SceneTree
## SpecialSystem advances on SimClock (HTML updateFx frame cadence).

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if src.find("sim_tick") < 0 or src.find("_on_sim_tick") < 0:
		print("[SPEC] FAIL must connect SimClock.sim_tick")
		ok = false
	else:
		print("[SPEC] sim_tick ok")
	if src.find("player_down") < 0:
		print("[SPEC] FAIL must freeze while player_down")
		ok = false
	else:
		print("[SPEC] death freeze ok")
	var pl := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	# Player should not drive specials.tick every physics frame anymore
	var count := 0
	var i := 0
	while true:
		var j := pl.find("specials.tick", i)
		if j < 0:
			break
		count += 1
		i = j + 1
	if count > 0:
		print("[SPEC] FAIL Player still calls specials.tick (", count, "×) — SimClock owns FX")
		ok = false
	else:
		print("[SPEC] Player no longer drives specials.tick ok")
	var fs := FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	if fs.find("reset_stage_cd") < 0:
		print("[SPEC] FAIL FireSystem.reset_stage_cd missing")
		ok = false
	else:
		print("[SPEC] fire stage CD-only reset ok")
	var sf := FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if sf.find("reset_stage_cd") < 0:
		print("[SPEC] FAIL StageFlow should use reset_stage_cd on loadStage")
		ok = false
	else:
		print("[SPEC] loadStage fire CD path ok")
	if sf.find("set_heads") < 0 and sf.find("save_heads") < 0:
		print("[SPEC] FAIL clear gate heads should save")
		ok = false
	else:
		print("[SPEC] clear-gate heads save ok")
	if ok:
		print("[SPEC] PASS")
		quit(0)
	else:
		print("[SPEC] FAIL")
		quit(1)
