extends SceneTree
## HTML neutralizeInputs clears pointer + lastShiftTap so transition doesn't fire/dash.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var sf := FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if sf.find("neutralize_lmb") < 0:
		print("[NEUT] FAIL neutralize must set neutralize_lmb")
		ok = false
	else:
		print("[NEUT] neutralize_lmb ok")
	if sf.find("_shift_tap_t") < 0:
		print("[NEUT] FAIL must reset _shift_tap_t")
		ok = false
	else:
		print("[NEUT] shift tap reset ok")
	var pl := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("neutralize_lmb") < 0:
		print("[NEUT] FAIL Player must gate LMB on neutralize_lmb")
		ok = false
	else:
		print("[NEUT] Player LMB gate ok")
	var ps := FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
	if ps.find("emblems[\"start\"]") < 0 and ps.find("emblems['start']") < 0:
		print("[NEUT] FAIL ProgressStore must force start emblem")
		ok = false
	else:
		print("[NEUT] start emblem bootstrap ok")
	if ps.find("clear_hell") < 0 or ps.find("hell_cleared") < 0:
		print("[NEUT] FAIL hellCleared → clear_hell migrate missing")
		ok = false
	else:
		print("[NEUT] clear_hell migrate ok")
	if ok:
		print("[NEUT] PASS")
		quit(0)
	else:
		print("[NEUT] FAIL")
		quit(1)
