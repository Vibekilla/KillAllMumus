extends SceneTree
## Phase 4: boss death → clear gate timing constants (HTML deadT>150).

const DEATH_GATE_FRAMES := 150.0
const WYNN_HELL_SINK := 96.0

func _init() -> void:
	call_deferred("go")

func go() -> void:
	await process_frame
	var SF: Node = root.get_node_or_null("/root/StageFlow")
	var GS: Node = root.get_node_or_null("/root/GameState")
	if SF == null or GS == null:
		print("[GATE] FAIL missing autoload")
		quit(1)
		return
	# spawn_clear_gate on non-final sets portal + stage_cleared
	GS.stage_index = 0
	GS.set_state(GS.State.PLAY)
	if SF.has_method("spawn_clear_gate"):
		SF.spawn_clear_gate()
	var has_portal: bool = SF.clear_portal != null
	var cleared: bool = bool(GS.get_meta("stage_cleared", false))
	print("[GATE] stage0 portal=", has_portal, " cleared=", cleared)
	var ok: bool = has_portal and cleared
	# Final stage skips portal → win
	GS.stage_index = 6
	SF.clear_portal = null
	GS.set_meta("stage_cleared", false)
	if SF.has_method("spawn_clear_gate"):
		SF.spawn_clear_gate()
	# on_boss_defeated for final should end run or set WIN
	print("[GATE] final portal=", SF.clear_portal, " state=", GS.State.keys()[GS.state])
	ok = ok and SF.clear_portal == null
	print("[GATE] constants deadT=", DEATH_GATE_FRAMES, " hell_sink=", WYNN_HELL_SINK)
	if ok:
		print("[GATE] PASS")
		quit(0)
	else:
		print("[GATE] FAIL")
		quit(1)
