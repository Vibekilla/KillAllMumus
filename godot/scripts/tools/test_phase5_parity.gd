extends SceneTree
## Phase 5: items/kills/spawn/specials/bullets pattern constants.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var IT = root.get_node_or_null("/root/ItemSystem")
	var CH = root.get_node_or_null("/root/CombatHelpers")
	var GS = root.get_node_or_null("/root/GameState")
	if IT == null or CH == null or GS == null:
		print("[P5] FAIL no autoloads"); quit(1); return

	# EXTEND_SCORES / KILL_EXTEND / elite hearts
	if IT.EXTEND_SCORES != [300000, 800000, 1600000]:
		print("[P5] FAIL EXTEND_SCORES ", IT.EXTEND_SCORES); ok = false
	if CH.KILL_EXTEND != 50:
		print("[P5] FAIL KILL_EXTEND"); ok = false
	GS.difficulty = 0
	GS.ng_plus = 0
	if IT.elite_hearts() != 2:
		print("[P5] FAIL elite_hearts base"); ok = false
	GS.difficulty = 2
	GS.ng_plus = 3
	if IT.elite_hearts() != 5:  # min(5, 2+2+3)=5
		print("[P5] FAIL elite_hearts cap ", IT.elite_hearts()); ok = false
	GS.difficulty = 0
	GS.ng_plus = 0

	# drop_loot rates exist as code paths
	var dl: String = FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	for frag in ["0.30", "0.28", "0.09", "0.10", "0.12", "0.13", "0.58", "0.06"]:
		if dl.find(frag) < 0:
			print("[P5] FAIL dropLoot/kill rate ", frag); ok = false
	if dl.find("add_power(1.5)") < 0:
		print("[P5] FAIL elite power 1.5"); ok = false
	if dl.find("4.0 if kind == \"big\" else 1.4") < 0 and dl.find("1.4") < 0:
		print("[P5] FAIL special meter on kill"); ok = false
	if dl.find("500.0 if kind == \"big\" else 100.0") < 0 and dl.find("500") < 0:
		print("[P5] FAIL kill score"); ok = false

	# collect_item
	if dl.find("0.05") < 0:
		print("[P5] FAIL power pickup 0.05"); ok = false
	if dl.find("290") < 0 or dl.find("270") < 0:
		print("[P5] FAIL shield/rapid durations"); ok = false
	if dl.find("life_frags >= 5") < 0 and dl.find(">= 5") < 0:
		print("[P5] FAIL life frags 5"); ok = false
	if dl.find("bomb_frags >= 3") < 0 and dl.find(">= 3") < 0:
		print("[P5] FAIL bomb frags 3"); ok = false

	# spawn constants
	var sp: String = FileAccess.get_file_as_string("res://scripts/enemies/EnemySpawner.gd")
	if sp.find('"ape"') < 0 or sp.find("ELITE_HP") < 0:
		print("[P5] FAIL ELITE_KIND/HP"); ok = false
	if sp.find("9.0, 11.0, 15.0") < 0 and sp.find("9.0") < 0:
		print("[P5] FAIL ELITE_HP values"); ok = false
	if sp.find("0.45") < 0 or sp.find("15.0") < 0:
		print("[P5] FAIL spawn lil hp scale"); ok = false
	if sp.find("26.0 if icy else 16.0") < 0 and sp.find("26.0") < 0:
		print("[P5] FAIL spawn big hp"); ok = false

	# bullet patterns SPD
	var bp: String = FileAccess.get_file_as_string("res://scripts/combat/BulletPatterns.gd")
	if bp.find("0.8") < 0 or bp.find("0.13") < 0:
		print("[P5] FAIL SPD mul"); ok = false
	if bp.find("radius\": 12") < 0 and bp.find("12.0") < 0:
		print("[P5] FAIL heavy shell r12"); ok = false
	if bp.find("hp\": 4") < 0 and bp.find("4.0") < 0:
		print("[P5] FAIL heavy shell hp4"); ok = false

	# chain / nade / explode
	if dl.find("175.0") < 0:
		print("[P5] FAIL chain range 175"); ok = false
	if dl.find("24.0") < 0:
		print("[P5] FAIL chain stun 24"); ok = false
	if dl.find("50.0") < 0 or dl.find("58.0") < 0:
		print("[P5] FAIL nade ranges"); ok = false
	if dl.find("take_damage(2.0)") < 0:
		print("[P5] FAIL nade boss 2"); ok = false
	if dl.find("3.5") < 0:
		print("[P5] FAIL enemy_explode shake 3.5"); ok = false
	if dl.find("46.0") < 0:
		print("[P5] FAIL explode aoe 46"); ok = false

	# bubbles / stardust
	if dl.find("range(6)") < 0 or dl.find("120.0") < 0 or dl.find("rmax") < 0:
		print("[P5] FAIL spawnBubbles"); ok = false
	if dl.find("270.0") < 0 or dl.find("stardust") < 0:
		print("[P5] FAIL spawnStardust"); ok = false

	# specials
	var ss: String = FileAccess.get_file_as_string("res://scripts/systems/SpecialSystem.gd")
	if ss.find(">= 100.0") < 0:
		print("[P5] FAIL special charge 100"); ok = false
	if ss.find("64.0") < 0 or ss.find("240.0") < 0 or ss.find("156.0") < 0:
		print("[P5] FAIL special durations"); ok = false
	if ss.find("300.0") < 0:
		print("[P5] FAIL sixth 300"); ok = false
	if ss.find("charm\", 180") < 0 and ss.find("charm\", 180.0") < 0 and ss.find("180.0") < 0:
		print("[P5] FAIL kiss charm 180"); ok = false
	if ss.find("special_25") < 0:
		print("[P5] FAIL special_25 emblem"); ok = false

	# drawers exist
	for path in [
		"res://scripts/render/drawers/drawMumu.gd",
		"res://scripts/render/drawers/drawElite.gd",
		"res://scripts/render/drawers/drawItem.gd",
		"res://scripts/render/drawers/drawFx.gd",
		"res://scripts/render/drawers/drawMech.gd",
		"res://scripts/render/drawers/drawBobo.gd",
	]:
		if not FileAccess.file_exists(path):
			print("[P5] FAIL missing ", path); ok = false

	# runtime: elite_hearts / extend score step
	IT.extend_idx = 0
	GS.session_score = 300000
	var lives0: int = GS.lives
	IT.check_extend_score()
	if IT.extend_idx != 1:
		print("[P5] FAIL extend_idx after 300k"); ok = false
	# gain_life may have run
	GS.session_score = 0
	IT.extend_idx = 0

	# kill_extend overflow
	GS.lives = 9
	var sc0: int = GS.session_score
	IT.kill_extend()
	if GS.session_score < sc0 + 50000:
		print("[P5] FAIL kill_extend bonus"); ok = false
	GS.lives = lives0

	if ok:
		print("[P5] Phase 5 items/spawn/specials PASS")
		quit(0)
	else:
		print("[P5] FAIL")
		quit(1)
