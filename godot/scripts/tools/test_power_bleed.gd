extends SceneTree
## Phase 4: power bleed fixed-step on SimClock (HTML 0.00085/frame).

func _init() -> void:
	call_deferred("go")

func go() -> void:
	await process_frame
	var GS: Node = root.get_node_or_null("/root/GameState")
	var SC: Node = root.get_node_or_null("/root/SimClock")
	if GS == null:
		print("[BLEED] FAIL no GameState")
		quit(1)
		return
	# Ensure bleed listens to sim clock
	if GS.has_method("_bind_sim_clock"):
		GS._bind_sim_clock()
	GS.set_state(GS.State.PLAY)
	GS.power = 3.0
	GS.set_meta("stage_cleared", false)
	var p0: float = float(GS.power)
	# Drive 60 fixed sim ticks via GameState._on_sim_tick (SimClock.sim_tick payload)
	for i in range(60):
		if GS.has_method("_on_sim_tick"):
			GS._on_sim_tick(1.0 / 60.0)
		else:
			print("[BLEED] FAIL no _on_sim_tick")
			quit(1)
			return
	var p_after: float = float(GS.power)
	var expected: float = 3.0 - 0.00085 * 60.0
	print("[BLEED] power ", p0, " -> ", p_after, " expected ~", expected)
	var bleed_ok := absf(p_after - expected) < 0.002 and p_after < p0
	# Cleared field freezes bleed
	GS.set_meta("stage_cleared", true)
	var p1: float = float(GS.power)
	for i in range(60):
		GS._on_sim_tick(1.0 / 60.0)
	var freeze_ok := absf(float(GS.power) - p1) < 0.00001
	print("[BLEED] cleared freeze ", p1, " -> ", GS.power, " freeze_ok=", freeze_ok)
	if bleed_ok and freeze_ok:
		print("[BLEED] PASS")
		quit(0)
	else:
		print("[BLEED] FAIL bleed_ok=", bleed_ok, " freeze_ok=", freeze_ok)
		quit(1)
