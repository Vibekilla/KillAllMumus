extends SceneTree
## HTML loadStage parity: bombs floor 2, initPlayer, mouse follow default.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var sf: String = FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if sf.find("maxi(GameState.bombs, 2)") < 0 and sf.find("maxi(GameState.bombs,2)") < 0:
		print("[LOADST] FAIL bombs floor max(bombs,2) missing in on_stage_start")
		ok = false
	if sf.find("init_player") < 0:
		print("[LOADST] FAIL on_stage_start must call init_player (HTML loadStage)")
		ok = false
	var pm: String = FileAccess.get_file_as_string("res://scripts/ui/menu/P2Meta.gd")
	if pm.find("keep_shield") < 0 or pm.find("keep_rapid") < 0:
		print("[LOADST] FAIL init_player must preserve shieldT/rapidT (HTML)")
		ok = false
	if pm.find("p.dead = false") < 0:
		print("[LOADST] FAIL init_player must clear dead")
		ok = false
	var cfg: String = FileAccess.get_file_as_string("res://autoload/Config.gd")
	# default follow must be 0.6 (HTML MOUSE.follow)
	if cfg.find("mouse_follow: float = 0.6") < 0 and cfg.find("mouse_follow := 0.6") < 0:
		print("[LOADST] FAIL Config.mouse_follow default should be 0.6")
		ok = false
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("preserves shieldT") < 0 and pl.find("keep residual") < 0:
		# soft check — respawn comment
		if pl.find("shieldT") < 0 and pl.find("rapidT") < 0:
			print("[LOADST] FAIL respawn should document shield/rapid preserve")
			ok = false
	if ok:
		print("[LOADST] PASS")
		quit(0)
	else:
		print("[LOADST] FAIL")
		quit(1)
