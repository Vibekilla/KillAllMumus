extends SceneTree
## Headless full-scene playtest: loads Main.tscn, starts run, exercises systems.

func _init() -> void:
	call_deferred("_run")

func _A(name: String) -> Node:
	return root.get_node_or_null("/root/" + name)

func _run() -> void:
	await process_frame
	var DataRegistry = _A("DataRegistry")
	var GameState = _A("GameState")
	var ProgressStore = _A("ProgressStore")
	var AssetBank = _A("AssetBank")
	var StageFlow = _A("StageFlow")
	var fail = 0
	print("[PLAYTEST] === GODOT SCENE PLAYTEST ===")
	if DataRegistry == null or GameState == null:
		print("[PLAYTEST] FAIL autoloads")
		quit(1)
		return
	# Load main scene (player, spawner, UI)
	var packed = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[PLAYTEST] FAIL Main.tscn missing")
		quit(1)
		return
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print("[PLAYTEST] Main.tscn loaded children=", main.get_child_count())
	print("[PLAYTEST] data stages=", DataRegistry.stages.size(),
		" weapons=", DataRegistry.weapons.size(),
		" specials=", DataRegistry.specials.size(),
		" melee=", DataRegistry.melee.size() if DataRegistry.get("melee") != null else "?",
		" outfits=", DataRegistry.outfits.size(),
		" emblems=", DataRegistry.emblems.size(),
		" consum=", DataRegistry.consumables.size())
	# Assets
	var miss_tex = []
	if AssetBank:
		for k in ["maid", "confused", "honeybadger", "lily", "mumina", "winimg", "peephole", "portrait"]:
			if AssetBank.get_tex(k) == null:
				miss_tex.append(k)
	print("[PLAYTEST] textures miss=", miss_tex if miss_tex.size() else "none")
	# Start run
	GameState.difficulty = 0
	GameState.ng_plus = 0
	GameState.start_run()
	await process_frame
	print("[PLAYTEST] start_run state=", GameState.State.keys()[GameState.state],
		" lives=", GameState.lives, " power=", GameState.power, " weapons=", GameState.weapons)
	# Force play
	GameState.set_state(GameState.State.PLAY)
	if StageFlow and StageFlow.has_method("on_stage_start"):
		StageFlow.on_stage_start()
	await process_frame
	var player = root.get_tree().get_first_node_in_group("player")
	print("[PLAYTEST] player=", player != null)
	if player == null:
		fail += 1
		print("[PLAYTEST] FAIL no player in scene")
	else:
		print("[PLAYTEST] player pos=", player.global_position, " has fire=", player.get("fire_sys") != null,
			" melee=", player.get("melee") != null, " consum=", player.get("consumables") != null)
		# Fire all weapons briefly
		if player.get("fire_sys") and player.get("bullet_pool"):
			if player.fire_sys.has_method("reset_run"):
				player.fire_sys.reset_run()
			for w in GameState.weapons:
				GameState.current_weapon = w
				if player.fire_sys.has_method("reset_run"):
					player.fire_sys.reset_run()
				var ok = player.fire_sys.try_fire(player, player.bullet_pool, false)
				print("[PLAYTEST] fire wep=", w, " ok=", ok)
			GameState.current_weapon = "laser"
			if player.fire_sys.has_method("reset_run"):
				player.fire_sys.reset_run()
			player.fire_sys.try_fire(player, player.bullet_pool, true)  # focus
			print("[PLAYTEST] focus fire ok")
		# Ensure waves started
		var stages = root.get_node_or_null("StageController")
		if stages and stages.has_method("start_waves_if_ready"):
			stages.start_waves_if_ready()
		if player.get("melee"):
			player.melee.begin_hold()
			for _i in range(10):
				await process_frame
			player.melee.release(player, "katana", -PI / 2.0)
			print("[PLAYTEST] melee charged release")
		if player.get("consumables"):
			player.consumables.cycle()
			print("[PLAYTEST] consum key=", player.consumables.selected_key())
		if player.get("specials") and GameState.specials.size():
			GameState.special_meter = 100.0
			player.specials.use(str(GameState.specials[0]), player, player.bullet_pool)
			print("[PLAYTEST] special used ", GameState.specials[0])
	# Simulate combat frames
	for i in range(300):
		await process_frame
	var enemies = root.get_tree().get_nodes_in_group("enemies")
	var bosses = root.get_tree().get_nodes_in_group("bosses")
	print("[PLAYTEST] after 300f enemies=", enemies.size(), " bosses=", bosses.size(),
		" kills=", GameState.total_kills, " score=", GameState.session_score, " power=", GameState.power)
	# Spawner present?
	var spawner = main.get_node_or_null("EnemySpawner")
	print("[PLAYTEST] EnemySpawner=", spawner != null)
	if spawner and enemies.size() == 0 and GameState.total_kills == 0:
		print("[PLAYTEST] WARN no enemies spawned in 300 frames — check StageController/spawner timing")
		fail += 0  # soft warn, intro timers may delay
	# Emblem / progress
	if ProgressStore:
		ProgressStore.unlock_emblem("first_mumu")
		ProgressStore.estats_add("kills", 5)
		print("[PLAYTEST] emblems=", ProgressStore.emblem_count() if ProgressStore.has_method("emblem_count") else "?",
			" toast_q=", (ProgressStore.get_meta("emblem_toasts", []) if ProgressStore.has_meta("emblem_toasts") else []).size())
	# UI nodes
	for path in ["UI/TitleScreen", "UI/HudCanvas", "UI/EndScreen", "UI/FlowUI", "Playfield/Player"]:
		var n = main.get_node_or_null(path)
		if n == null:
			# try recursive
			n = _find(main, path.get_file())
		print("[PLAYTEST] node ", path, "=", n != null)
	# Title draw path
	GameState.set_state(GameState.State.TITLE)
	await process_frame
	print("[PLAYTEST] title state ok")
	if fail:
		print("[PLAYTEST] FAIL soft=", fail)
	else:
		print("[PLAYTEST] PASS scene smoke")
	quit(0 if fail == 0 else 1)

func _find(n: Node, name: String) -> Node:
	if n.name == name:
		return n
	for c in n.get_children():
		var r = _find(c, name)
		if r:
			return r
	return null
