extends SceneTree
## Phase 2 guards: arsenal caps, newRun constants, dropToSlot, defaults.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var MH = load("res://scripts/ui/menu/MenuHelpers.gd")
	var cap: Dictionary = MH.ARS_CAP
	if int(cap.get("w", 0)) != 5 or int(cap.get("s", 0)) != 5:
		print("[P2] FAIL ARS_CAP w/s"); ok = false
	if int(cap.get("m", 0)) != 2 or int(cap.get("i", 0)) != 3:
		print("[P2] FAIL ARS_CAP m/i"); ok = false

	var p2s: String = FileAccess.get_file_as_string("res://scripts/ui/menu/P2Meta.gd")
	var gs: String = FileAccess.get_file_as_string("res://autoload/GameState.gd")
	var mm: String = FileAccess.get_file_as_string("res://scripts/ui/menu/MenuModel.gd")
	var ps: String = FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
	var dm: String = FileAccess.get_file_as_string("res://scripts/ui/menu/draw_menus.gd")
	var dt: String = FileAccess.get_file_as_string("res://scripts/render/drawers/drawTitle.gd")

	# Starter arsenal laser (HTML arsenalW=['laser'])
	if ps.find('"w": ["laser"]') < 0 and ps.find("'w': ['laser']") < 0 and ps.find("laser") < 0:
		print("[P2] FAIL starter arsenal"); ok = false
	if gs.find('weapons.append("laser")') < 0:
		print("[P2] FAIL empty weapons → laser"); ok = false
	# newRun constants
	if p2s.find("lives = 6") < 0 and gs.find("lives = 6") < 0:
		print("[P2] FAIL lives 6"); ok = false
	if p2s.find("bombs = 3") < 0 and gs.find("bombs = 3") < 0:
		print("[P2] FAIL bombs 3"); ok = false
	if p2s.find("special_meter = 15") < 0 and gs.find("special_meter = 15") < 0:
		print("[P2] FAIL special 15"); ok = false
	if p2s.find("power = 1.0") < 0 and gs.find("power = 1.0") < 0:
		print("[P2] FAIL power 1.0"); ok = false
	# toggle / move / drop / unequip
	if p2s.find("func toggle_arsenal") < 0:
		print("[P2] FAIL toggle_arsenal"); ok = false
	if p2s.find("func move_arsenal") < 0:
		print("[P2] FAIL move_arsenal"); ok = false
	if p2s.find("func drop_to_slot") < 0:
		print("[P2] FAIL drop_to_slot"); ok = false
	if p2s.find("func unequip_arsenal") < 0:
		print("[P2] FAIL unequip_arsenal"); ok = false
	if mm.find("func drop_to_slot") < 0 or mm.find('sfx("power")') < 0:
		print("[P2] FAIL MenuModel drop_to_slot sfx"); ok = false
	# initPlayer iframe 120, y = PF.h-70
	if p2s.find("invuln = 120") < 0:
		print("[P2] FAIL initPlayer iframe 120"); ok = false
	if p2s.find("size.y - 70") < 0:
		print("[P2] FAIL initPlayer y-70"); ok = false
	# drawArsenal tabs
	if dm.find("tabW = 142") < 0 and dm.find("tabW=142") < 0:
		print("[P2] FAIL arsenal tabW 142"); ok = false
	if dm.find("func drawArsenal") < 0:
		print("[P2] FAIL drawArsenal"); ok = false
	# drawTitle
	if dt.find("func drawTitle") < 0 and dt.find("drawTitle") < 0:
		print("[P2] FAIL drawTitle"); ok = false
	if dt.find("KILL ALL MUMUS") < 0:
		print("[P2] FAIL title tagline"); ok = false
	# submit / tweet
	if p2s.find("func submit_score") < 0 or p2s.find("func tweet_result") < 0:
		print("[P2] FAIL submit/tweet"); ok = false
	# modeTag / applyDiff
	if gs.find("func mode_tag") < 0 or gs.find("func apply_difficulty") < 0:
		print("[P2] FAIL mode_tag/apply_difficulty"); ok = false
	# FREE content
	if ps.find("w:laser") < 0:
		print("[P2] FAIL free content laser"); ok = false

	# Runtime: ARS_CAP + mode_tag math (autoload via root)
	var gs_node = root.get_node_or_null("/root/GameState")
	if gs_node:
		gs_node.difficulty = 0
		gs_node.ng_plus = 0
		if gs_node.mode_tag() != "NORMAL":
			print("[P2] FAIL mode_tag NORMAL got ", gs_node.mode_tag()); ok = false
		gs_node.difficulty = 2
		gs_node.ng_plus = 3
		if gs_node.mode_tag() != "HELL+3":
			print("[P2] FAIL mode_tag HELL+3 got ", gs_node.mode_tag()); ok = false
		gs_node.difficulty = 0
		gs_node.ng_plus = 0
	else:
		print("[P2] FAIL no GameState autoload"); ok = false

	if ok:
		print("[P2] Phase 2 arsenal/run/title guards PASS")
		quit(0)
	else:
		print("[P2] FAIL")
		quit(1)
