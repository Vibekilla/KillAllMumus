extends SceneTree
## HTML: emblemTick after update (runs while dead); dialog freezes while p.dead.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var gs := FileAccess.get_file_as_string("res://autoload/GameState.gd")
	var i := gs.find("func _on_sim_tick")
	var chunk := gs.substr(i, 900) if i >= 0 else ""
	if chunk.find("_tick_emblems_play") < 0:
		print("[EDD] FAIL GameState must call emblem tick on sim")
		ok = false
	else:
		print("[EDD] emblem tick from GameState ok")
	# emblem before player_down return
	var ei := chunk.find("_tick_emblems_play")
	var pi := chunk.find("player_down")
	if ei < 0 or pi < 0 or ei > pi:
		print("[EDD] FAIL emblem tick must run before player_down early-return")
		ok = false
	else:
		print("[EDD] emblem before death freeze ok")
	var pl := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	# Only fail on an actual call, not comments mentioning emblems.tick_play
	var has_call := false
	for line in pl.split("\n"):
		var s := line.strip_edges()
		if s.begins_with("#"):
			continue
		if s.find("emblems.tick_play(") >= 0 or s.find("emblems.tick_play ()") >= 0:
			has_call = true
			break
	if has_call:
		print("[EDD] FAIL Player should not double-drive emblems.tick_play")
		ok = false
	else:
		print("[EDD] Player no double-tick ok")
	var sf := FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	var di := sf.find("func tick_dialog")
	var dchunk := sf.substr(di, 400) if di >= 0 else ""
	if dchunk.find("player_down") < 0:
		print("[EDD] FAIL dialog must freeze while player_down")
		ok = false
	else:
		print("[EDD] dialog death freeze ok")
	var ts := FileAccess.get_file_as_string("res://scripts/ui/TitleScreen.gd")
	if ts.find("title_idle_t += 1.0") < 0 and ts.find("title_idle_t += 1") < 0:
		print("[EDD] FAIL title idle must advance 1/frame on SimClock")
		ok = false
	else:
		print("[EDD] title idle sim ok")
	if ts.find("delta * 60") >= 0 or ts.find("delta*60") >= 0:
		print("[EDD] FAIL title idle still uses wall-clock delta")
		ok = false
	else:
		print("[EDD] no wall-clock idle ok")
	if ok:
		print("[EDD] PASS")
		quit(0)
	else:
		print("[EDD] FAIL")
		quit(1)
