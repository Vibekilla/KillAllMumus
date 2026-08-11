extends SceneTree
## HTML flashMsg.t-- runs before p.dead early-return — toasts still drain while down.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/combat/CombatHelpers.gd")
	if src.find("_tick_flash") < 0:
		print("[FLASH] FAIL missing _tick_flash helper")
		ok = false
	else:
		print("[FLASH] _tick_flash ok")
	var i := src.find("func tick_fx")
	var chunk := src.substr(i, 900) if i >= 0 else ""
	# Must tick flash before player_down return
	var fi := chunk.find("_tick_flash")
	var pi := chunk.find("player_down")
	if fi < 0 or pi < 0 or fi > pi:
		print("[FLASH] FAIL tick_fx must call _tick_flash before player_down early-return")
		ok = false
	else:
		print("[FLASH] flash before death-freeze ok")
	if src.find("PROCESS_MODE_ALWAYS") < 0:
		print("[FLASH] FAIL CombatHelpers must ALWAYS process for pause flash")
		ok = false
	else:
		print("[FLASH] always process ok")
	if src.find("State.PAUSED") < 0:
		print("[FLASH] FAIL must tick flash while PAUSED")
		ok = false
	else:
		print("[FLASH] pause flash path ok")
	# Runtime via project autoloads
	var CH: Node = root.get_node_or_null("/root/CombatHelpers")
	var GS: Node = root.get_node_or_null("/root/GameState")
	if CH and GS and CH.has_method("flash") and CH.has_method("tick_fx"):
		CH.flash("TEST", 30.0)
		GS.player_down = true
		GS.set_state(GS.State.PLAY)
		CH.tick_fx(1.0 / 60.0)
		var t_left := float(CH.flash_msg.get("t", -1))
		if t_left >= 29.5:
			print("[FLASH] FAIL flash frozen during player_down t=", t_left)
			ok = false
		else:
			print("[FLASH] runtime drain during death ok t=", t_left)
		GS.player_down = false
	else:
		print("[FLASH] runtime skip (autoloads not ready) — structure checks only")
	if ok:
		print("[FLASH] PASS")
		quit(0)
	else:
		print("[FLASH] FAIL")
		quit(1)
