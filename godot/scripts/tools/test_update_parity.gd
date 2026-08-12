extends SceneTree
## Phase 1: guard HTML update() constants + particle gravity against regressions.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var pl: String = FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	var ch: String = FileAccess.get_file_as_string("res://scripts/combat/CombatHelpers.gd")
	var gs: String = FileAccess.get_file_as_string("res://autoload/GameState.gd")
	var bl: String = FileAccess.get_file_as_string("res://scripts/combat/Bullet.gd")
	var it: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	var fs: String = FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	var ms: String = FileAccess.get_file_as_string("res://scripts/systems/MeleeSystem.gd")

	# Movement / face
	if pl.find("6.6 * FRAME") < 0 or pl.find("3.5 * FRAME") < 0:
		print("[UPD] FAIL speed 6.6/3.5"); ok = false
	if pl.find("0.35") < 0 or pl.find("0.26") < 0:
		print("[UPD] FAIL face hold sp2/lerp"); ok = false
	if pl.find("absf(vpf.x) < 0.03") < 0:
		print("[UPD] FAIL velocity snap 0.03"); ok = false
	if pl.find("18.0 * FRAME") < 0:
		print("[UPD] FAIL dash speed 18"); ok = false
	if pl.find("offx *= 0.95") < 0:
		print("[UPD] FAIL offx decay"); ok = false

	# Power / special
	if gs.find("0.00085") < 0:
		print("[UPD] FAIL power bleed"); ok = false
	if gs.find("0.012") < 0:
		print("[UPD] FAIL special trickle"); ok = false

	# Graze
	if bl.find("rr + 8.0") < 0 and bl.find("rr+8") < 0:
		print("[UPD] FAIL graze ring +8"); ok = false
	if bl.find("special_meter + 0.2") < 0 and bl.find("+ 0.2") < 0:
		print("[UPD] FAIL graze special +0.2"); ok = false
	if bl.find("2.2 if focus") < 0 and bl.find("2.2 if focus_on") < 0:
		print("[UPD] FAIL hitR focus 2.2"); ok = false

	# Fire rate
	if fs.find("4.0 if focus else 6.0") < 0:
		print("[UPD] FAIL fire rate 4/6"); ok = false

	# Melee charge
	if ms.find("/ 48") < 0 and ms.find("/48") < 0:
		print("[UPD] FAIL melee charge /48"); ok = false

	# Particle gravity HTML q.vy+=0.12
	if ch.find("0.12 * df") < 0 and ch.find("+ 0.12") < 0:
		print("[UPD] FAIL particle gravity 0.12"); ok = false

	# Death freezes particles but items continue
	if ch.find("player_down") < 0:
		print("[UPD] FAIL death freeze particles"); ok = false
	if it.find("player_down") < 0 or it.find("_update_items") < 0:
		print("[UPD] FAIL death still updateItems"); ok = false

	# Dash spark each frame
	if pl.find("life\": 16.0") < 0 and pl.find('"life": 16.0') < 0:
		# looser
		if pl.find("outfit_colors") < 0 or pl.find("dash > 0.0") < 0:
			print("[UPD] FAIL dash frame particles"); ok = false

	if ok:
		print("[UPD] update() HTML 1:1 guards PASS")
		quit(0)
	else:
		print("[UPD] FAIL")
		quit(1)
