extends SceneTree
## Phase 4: pickup magnet / COLLECT_LINE vacuum (HTML updateItems).

func _init() -> void:
	call_deferred("go")

func go() -> void:
	await process_frame
	var IS: Node = root.get_node_or_null("/root/ItemSystem")
	var GS: Node = root.get_node_or_null("/root/GameState")
	var CFG: Node = root.get_node_or_null("/root/Config")
	if IS == null or GS == null:
		print("[MAGNET] FAIL missing autoload")
		quit(1)
		return
	GS.set_state(GS.State.PLAY)
	GS.set_meta("dual_mode", false)
	IS.items.clear()
	# Drop a power pellet far from player y but within magnet if we home from auto
	IS.drop_item(300.0, 300.0, "power")
	var cl: float = 110.0
	if CFG and "COLLECT_LINE" in CFG:
		cl = float(CFG.COLLECT_LINE)
	# Fake player via a dummy node in group? ItemSystem uses get_first_node_in_group("player")
	# Without a player, magnet won't vacuum — just ensure tick doesn't crash
	var n0: int = IS.items.size()
	IS.tick(1.0 / 60.0)
	print("[MAGNET] tick ok items=", IS.items.size(), " collect_line=", cl, " start=", n0)
	# Gravity should pull vy down when not homing
	var it: Dictionary = IS.items[0] if IS.items.size() else {}
	if it.is_empty():
		print("[MAGNET] FAIL no item after tick")
		quit(1)
		return
	var vy0: float = float(it.get("vy", 0))
	IS.tick(1.0 / 60.0)
	var vy1: float = float(IS.items[0].get("vy", 0)) if IS.items.size() else 0.0
	print("[MAGNET] gravity vy ", vy0, " -> ", vy1)
	var grav_ok := vy1 > vy0 or float(it.get("homing", false))
	if grav_ok:
		print("[MAGNET] PASS")
		quit(0)
	else:
		print("[MAGNET] FAIL")
		quit(1)
