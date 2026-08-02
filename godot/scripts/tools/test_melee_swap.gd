extends SceneTree
## Melee swap cycles armed_melee without reordering arsenal.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	if pl.find("var armed_melee") < 0:
		print("[MSWAP] FAIL armed_melee field missing")
		ok = false
	if pl.find("func cycle_melee") < 0:
		print("[MSWAP] FAIL cycle_melee missing")
		ok = false
	if pl.find("func current_melee_key") < 0:
		print("[MSWAP] FAIL current_melee_key missing")
		ok = false
	if pl.find("current_melee_key()") < 0:
		print("[MSWAP] FAIL melee paths must use current_melee_key")
		ok = false
	# must not hardcode ms[0] for combat melee
	if pl.find("ms[0]") >= 0:
		print("[MSWAP] FAIL still hardcodes ms[0] for melee")
		ok = false
	var ir: String = FileAccess.get_file_as_string("res://scripts/input/InputRouter.gd")
	if ir.find("cycle_melee") < 0:
		print("[MSWAP] FAIL InputRouter must call cycle_melee")
		ok = false
	# must not permanently rotate arsenal array as primary path
	var ci := ir.find("func _cycle_melee")
	if ci >= 0:
		var body := ir.substr(ci, 400)
		if body.find("remove_at(0)") >= 0 and body.find("cycle_melee") < 0:
			print("[MSWAP] FAIL still rotates arsenal permanently")
			ok = false
	var pm: String = FileAccess.get_file_as_string("res://scripts/ui/menu/P2Meta.gd")
	if pm.find("armed_melee") < 0:
		print("[MSWAP] FAIL apply arsenal must clamp armed_melee")
		ok = false
	var gs: String = FileAccess.get_file_as_string("res://autoload/GameState.gd")
	if gs.find("armed_melee = 0") < 0:
		print("[MSWAP] FAIL newRun must reset armed_melee")
		ok = false
	if ok:
		print("[MSWAP] PASS")
		quit(0)
	else:
		print("[MSWAP] FAIL")
		quit(1)
