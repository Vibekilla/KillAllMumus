extends SceneTree
## HTML meleeChargeFx: shockwall sfx boom, flurry sfx claw.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")
	var sh := src.find("\"shockwall\"")
	var fl := src.find("\"flurry\"")
	var sh_chunk := src.substr(sh, 2200) if sh >= 0 else ""
	var fl_chunk := src.substr(fl, 900) if fl >= 0 else ""
	if sh_chunk.find("sfx(\"boom\")") < 0:
		print("[MCSFX] FAIL shockwall must sfx boom")
		ok = false
	else:
		print("[MCSFX] shockwall boom ok")
	if fl_chunk.find("sfx(\"claw\")") < 0:
		print("[MCSFX] FAIL flurry charge must sfx claw")
		ok = false
	else:
		print("[MCSFX] flurry claw ok")
	var sp := FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	var bi := sp.find("HTML volley")
	var bchunk := sp.substr(bi, 500) if bi >= 0 else ""
	if bchunk.find("sfx(\"shoot\")") < 0:
		print("[MCSFX] FAIL bearzooka volley must sfx shoot")
		ok = false
	else:
		print("[MCSFX] bearzooka shoot ok")
	if bchunk.find("pshot") < 0:
		print("[MCSFX] FAIL bearzooka pellets should be pshot for bullet cancel")
		ok = false
	else:
		print("[MCSFX] bearzooka pshot ok")
	if ok:
		print("[MCSFX] PASS")
		quit(0)
	else:
		print("[MCSFX] FAIL")
		quit(1)
