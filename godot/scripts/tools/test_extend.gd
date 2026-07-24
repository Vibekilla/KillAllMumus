extends SceneTree
## Phase 4: score extend thresholds + kill-extend cadence (HTML EXTEND_SCORES / KILL_EXTEND).

func _init() -> void:
	call_deferred("go")

func go() -> void:
	await process_frame
	var IS: Node = root.get_node_or_null("/root/ItemSystem")
	var GS: Node = root.get_node_or_null("/root/GameState")
	var CH: Node = root.get_node_or_null("/root/CombatHelpers")
	if IS == null or GS == null or CH == null:
		print("[EXTEND] FAIL missing autoload")
		quit(1)
		return
	GS.set_state(GS.State.PLAY)
	GS.lives = 3
	GS.session_score = 0
	IS.extend_idx = 0
	var lives0: int = int(GS.lives)
	# Cross first score threshold
	GS.session_score = 300000
	IS.check_extend_score()
	print("[EXTEND] score 300k lives ", lives0, " -> ", GS.lives, " idx=", IS.extend_idx)
	var ok: bool = (int(GS.lives) == lives0 + 1 and int(IS.extend_idx) == 1)
	# Second threshold
	GS.session_score = 800000
	IS.check_extend_score()
	print("[EXTEND] score 800k lives=", GS.lives, " idx=", IS.extend_idx)
	ok = ok and int(IS.extend_idx) == 2 and int(GS.lives) == lives0 + 2
	# Kill extend every 50
	var k_ext: int = int(CH.KILL_EXTEND)
	GS.total_kills = k_ext
	var lives_before: int = int(GS.lives)
	IS.kill_extend()
	print("[EXTEND] kill_extend lives ", lives_before, " -> ", GS.lives)
	ok = ok and int(GS.lives) == lives_before + 1
	if ok:
		print("[EXTEND] PASS")
		quit(0)
	else:
		print("[EXTEND] FAIL")
		quit(1)
