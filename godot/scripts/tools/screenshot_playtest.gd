extends SceneTree
## Headless Godot visual capture via SubViewport + Xvfb (GL).
##   xvfb-run -a godot --path godot --script res://scripts/tools/screenshot_playtest.gd

const OUT_SUB := "playtest_shots"
const VIEW_W := 960
const VIEW_H := 540

var _sv: SubViewport
var _main: Node

func _init() -> void:
	call_deferred("_run")

func _A(n: String) -> Node:
	return root.get_node_or_null("/root/" + n)

func _shot_dir() -> String:
	var d := "user://" + OUT_SUB
	DirAccess.make_dir_recursive_absolute(d)
	return d

func _force_ui_size(main: Node) -> void:
	var ui = main.get_node_or_null("UI")
	if ui == null:
		return
	for c in ui.get_children():
		if c is Control:
			var ctrl := c as Control
			ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
			ctrl.offset_left = 0
			ctrl.offset_top = 0
			ctrl.offset_right = 0
			ctrl.offset_bottom = 0
			ctrl.size = Vector2(VIEW_W, VIEW_H)
			ctrl.position = Vector2.ZERO
			ctrl.queue_redraw()

func _save(name: String) -> void:
	for _i in range(3):
		await process_frame
	RenderingServer.force_draw(true)
	await process_frame
	var tex: ViewportTexture = _sv.get_texture()
	if tex == null:
		print("[SHOT] FAIL no SubViewport texture ", name)
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		print("[SHOT] FAIL empty image ", name)
		return
	if img.get_width() != VIEW_W or img.get_height() != VIEW_H:
		img.resize(VIEW_W, VIEW_H, Image.INTERPOLATE_NEAREST)
	var path := _shot_dir().path_join(name + ".png")
	var err := img.save_png(path)
	print("[SHOT] ", name, " err=", err, " ", img.get_width(), "x", img.get_height(),
		" path=", ProjectSettings.globalize_path(path))

func _run() -> void:
	await process_frame
	var GameState = _A("GameState")
	var StageFlow = _A("StageFlow")
	if GameState == null:
		print("[SHOT] FAIL no GameState")
		quit(1)
		return

	_sv = SubViewport.new()
	_sv.name = "ShotViewport"
	_sv.size = Vector2i(VIEW_W, VIEW_H)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	_sv.handle_input_locally = false
	_sv.gui_disable_input = true
	root.add_child(_sv)

	var packed = load("res://scenes/main/Main.tscn")
	if packed == null:
		print("[SHOT] FAIL Main.tscn")
		quit(1)
		return
	_main = packed.instantiate()
	_sv.add_child(_main)
	_force_ui_size(_main)
	var pf = _main.get_node_or_null("Playfield")
	if pf:
		pf.z_index = 5
	var fx = _main.get_node_or_null("FxLayer")
	if fx:
		fx.z_index = 10
	var border = _main.get_node_or_null("PlayfieldBorder")
	if border and border is CanvasItem:
		(border as CanvasItem).z_index = -1
	var bg = _main.get_node_or_null("Background")
	if bg and bg is CanvasItem:
		(bg as CanvasItem).z_index = -2
	for _i in range(8):
		await process_frame

	var fast := OS.get_environment("PLAYTEST_FAST") != "0"
	if OS.get_environment("PLAYTEST_FULL") == "1":
		fast = false
	var play_frames := 90 if fast else 200
	var fire_frames := 40 if fast else 100

	# Title — dismiss soundgate like HTML dual clicks #sg-mute
	GameState.set_state(GameState.State.TITLE)
	var sg = _main.get_node_or_null("UI/SoundGate")
	if sg and sg.has_method("force_dismiss"):
		sg.force_dismiss(false)
	elif sg:
		sg.visible = false
	_force_ui_size(_main)
	for _i in range(8 if fast else 12):
		await process_frame
	# Ensure title host redraws after gate
	var title = _main.get_node_or_null("UI/TitleScreen")
	if title and title.has_method("queue_redraw"):
		title.queue_redraw()
	for _i in range(4):
		await process_frame
	await _save("godot_title")

	# Dual fairness: HTML guest has only free skins; strip emblem unlocks for menu shots
	# (in-memory only — process exits; do not queue_save). emblems is Dictionary id→bool.
	var _ps = _A("ProgressStore")
	var _saved_emblems: Dictionary = {}
	if _ps:
		_saved_emblems = _ps.emblems.duplicate(true)
		_ps.emblems = {"start": true}
	GameState.selected_outfit = "og"
	if title and "model" in title and title.model:
		title.model.outfit_preview = "og"
		title.model.victory_face = 0
		title.model.outfit_pose = 0

	# Meta menus (always — dual compares these to HTML)
	for st_name in [
		[GameState.State.OUTFITS, "godot_menu_outfits"],
		[GameState.State.ARSENAL, "godot_menu_arsenal"],
		[GameState.State.EMBLEMS, "godot_menu_emblems"],
		[GameState.State.LEADERBOARD, "godot_menu_leaderboard"],
	]:
		GameState.set_state(st_name[0])
		_force_ui_size(_main)
		if title and title.has_method("queue_redraw"):
			title.queue_redraw()
		var wait_n := 6 if fast else 10
		# Leaderboard needs HTTP settle (or fail → error copy)
		if st_name[0] == GameState.State.LEADERBOARD:
			wait_n = 45 if fast else 90
		for _i in range(wait_n):
			await process_frame
		# If still loading under playtest, force error empty state for stable dual
		if st_name[0] == GameState.State.LEADERBOARD and title and "model" in title:
			var m = title.model
			if m and str(m.lb_state) == "loading":
				m.lb_state = "error"
				m.lb_cache = []
				title.queue_redraw()
				for _i in range(3):
					await process_frame
		await _save(str(st_name[1]))

	# Phase 2: Bobina expression + pose + blink dual previews (HTML VICTORY_FACES / OUTFIT_POSES)
	if not fast and title and "model" in title and title.model:
		GameState.set_state(GameState.State.OUTFITS)
		_force_ui_size(_main)
		# MenuHelpers.VICTORY_FACES: 0 Auto, 1 :3 uwu, 2 Smile, 3 >v< squee, 4 Giggle, 5 Annoyed
		for face_i in [0, 1, 2, 3, 4, 5]:
			title.model.victory_face = face_i
			title.model.outfit_preview = "og"
			title.model.outfit_pose = 0
			title.queue_redraw()
			for _i in range(8):
				await process_frame
			await _save("godot_bobina_face_%d" % face_i)
		# Poses (idle / dance / cheer) with smile face for stable compare
		title.model.victory_face = 2
		for pose_i in [0, 1, 4]:
			title.model.outfit_pose = pose_i
			title.model.outfit_preview = "og"
			title.queue_redraw()
			for _i in range(10):
				await process_frame
			await _save("godot_bobina_pose_%d" % pose_i)
		# Blink open vs closed: pause SimClock so tick stays in blink window (tick % 230 < 7)
		title.model.victory_face = 2  # smile — blink applies
		title.model.outfit_pose = 0
		var sc = _A("SimClock")
		if sc:
			var was_paused: bool = bool(sc.paused) if "paused" in sc else false
			sc.paused = true
			sc.sim_frame = 10  # open eyes (tick alias ok)
			if title.has_method("set_process"):
				pass
			if "menus" in title and title.menus and title.menus.has_method("set_tick"):
				title.menus.set_tick(10)
			title.queue_redraw()
			for _i in range(6):
				await process_frame
				title.queue_redraw()
			await _save("godot_bobina_blink_open")
			sc.sim_frame = 3  # closed lids
			if "menus" in title and title.menus and title.menus.has_method("set_tick"):
				title.menus.set_tick(3)
			title.queue_redraw()
			for _i in range(6):
				await process_frame
				title.queue_redraw()
			await _save("godot_bobina_blink_closed")
			sc.paused = was_paused

		# --- Phase 2.1 / 2.4 / 2.5: breath, all poses, continuous outfits, coffee hold, GIFs ---
		var sc2 = _A("SimClock")
		if sc2:
			sc2.paused = true
		# Breath dual (idle pose): two breath-phase ticks — sin(t*0.045) peaks differ
		title.model.victory_face = 2
		title.model.outfit_pose = 0
		title.model.outfit_preview = "og"
		for breath_tick in [0, 35]:
			if sc2:
				sc2.sim_frame = breath_tick
			if "menus" in title and title.menus and title.menus.has_method("set_tick"):
				title.menus.set_tick(breath_tick)
			title.queue_redraw()
			for _i in range(6):
				await process_frame
				title.queue_redraw()
			await _save("godot_bobina_breath_%d" % breath_tick)
		# Remaining poses: twirl / bounce / This Is Fine (coffee + fire)
		for pose_i in [2, 3, 5]:
			title.model.outfit_pose = pose_i
			title.model.outfit_preview = "og"
			if sc2:
				sc2.sim_frame = 40
			if "menus" in title and title.menus and title.menus.has_method("set_tick"):
				title.menus.set_tick(40)
			title.queue_redraw()
			for _i in range(10):
				await process_frame
				title.queue_redraw()
			await _save("godot_bobina_pose_%d" % pose_i)
		# Full wardrobe via OUTFITS menu (HTML drawOutfits) — one stable tick per skin @ ×4.7 stage
		title.model.outfit_pose = 0
		title.model.victory_face = 2  # smile
		if sc2:
			sc2.sim_frame = 24
		if "menus" in title and title.menus and title.menus.has_method("set_tick"):
			title.menus.set_tick(24)
		var wardrobe: Array = []
		var dr = _A("DataRegistry")
		if dr and "outfits" in dr:
			for o in dr.outfits:
				wardrobe.append(str(o.get("key", "")))
		if wardrobe.is_empty():
			wardrobe = ["og", "maid", "nanosuit", "badger", "viking", "ourbit", "bullbina", "monke",
				"pickle", "emblem", "labrat", "neko", "kigurumi", "cheese", "business", "jester",
				"samurai", "bride", "angel", "golden", "succubus", "voidling", "honeybee", "banana",
				"squirrely", "honeypot", "empress", "cabal"]
		for outfit_key in wardrobe:
			if outfit_key == "":
				continue
			title.model.outfit_preview = outfit_key
			title.queue_redraw()
			for _i in range(5):
				await process_frame
				title.queue_redraw()
			await _save("godot_menu_outfit_%s" % outfit_key)
		# Continuous-anim skins: second tick for wing/tail/veil motion dual inside same menu
		for outfit_key in ["angel", "succubus", "voidling", "honeypot", "bride", "empress", "cabal"]:
			title.model.outfit_preview = outfit_key
			title.model.outfit_pose = 0
			title.model.victory_face = 2
			for anim_tick in [8, 48]:
				if sc2:
					sc2.sim_frame = anim_tick
				if "menus" in title and title.menus and title.menus.has_method("set_tick"):
					title.menus.set_tick(anim_tick)
				title.queue_redraw()
				for _i in range(6):
					await process_frame
					title.queue_redraw()
				await _save("godot_menu_outfit_anim_%s_%d" % [outfit_key, anim_tick])
		if sc2:
			sc2.paused = false

		# GIF overlays: talk (dialog), leek (stage clear already), confused floater
		# StageFlow already resolved at _run start
		if StageFlow and StageFlow.has_method("start_dialog"):
			GameState.set_state(GameState.State.PLAY)
			StageFlow.start_dialog([
				{"w": 1, "t": "Phase 2 talk GIF dual — hewo!"},
			], {})
			_force_ui_size(_main)
			for _i in range(12):
				await process_frame
			await _save("godot_gif_talk")
			StageFlow.dialog = null
		var items = _A("ItemSystem")
		if items:
			GameState.set_state(GameState.State.PLAY)
			items.floaters.clear()
			items.floaters.append({
				"x": 304.0, "y": 280.0, "life": 30.0, "vy": 0.0, "scale": 1.0,
			})
			_force_ui_size(_main)
			var wd = _main.get_node_or_null("WorldCanvas")
			if wd and wd.has_method("queue_redraw"):
				wd.queue_redraw()
			for _i in range(10):
				await process_frame
				if wd:
					wd.queue_redraw()
			await _save("godot_gif_confused")
			items.floaters.clear()
		# Return to outfits for later dual restore
		GameState.set_state(GameState.State.OUTFITS)
		_force_ui_size(_main)

	# Restore emblems for rest of dual (play may earn more)
	if _ps:
		_ps.emblems = _saved_emblems

	# Settings + NG select (title meta screens HTML dual also captures)
	GameState.set_state(GameState.State.SETTINGS)
	_force_ui_size(_main)
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_menu_settings")

	GameState.set_state(GameState.State.NG_SELECT)
	_force_ui_size(_main)
	if title and title.has_method("queue_redraw"):
		title.queue_redraw()
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_menu_ngselect")

	# Clean run: intro first (HTML order), then play with invuln so dual never hits gameover
	GameState.difficulty = 0
	GameState.ng_plus = 0
	GameState.start_run()  # → INTRO
	_force_ui_size(_main)
	var flow = _main.get_node_or_null("UI/FlowUI")
	if flow and flow.has_method("queue_redraw"):
		flow.queue_redraw()
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_flow_intro")

	GameState.set_state(GameState.State.PLAY)
	if StageFlow and StageFlow.has_method("on_stage_start"):
		StageFlow.on_stage_start()
	var player = _sv.get_tree().get_first_node_in_group("player")
	if player == null:
		player = root.get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(304, 400)
		player.z_index = 20
		# Dual playtest: stay alive so godot_play is real combat, not gameover
		if "invuln" in player:
			player.invuln = 99999.0
		GameState.lives = 99
		var spr = player.get_node_or_null("Sprite")
		if spr:
			spr.z_index = 20
	for i in range(play_frames):
		await process_frame
		if player and "invuln" in player:
			player.invuln = 99999.0
		if player and player.get("fire_sys") and player.get("bullet_pool"):
			player.fire_sys.try_fire(player, player.bullet_pool, false)
	print("[SHOT] enemies=", root.get_tree().get_nodes_in_group("enemies").size(),
		" player=", player != null, " pos=", player.global_position if player else Vector2.ZERO,
		" state=", GameState.State.keys()[GameState.state])
	# Ensure still PLAY (player_hit must not have ended the run)
	if GameState.state != GameState.State.PLAY:
		GameState.set_state(GameState.State.PLAY)
		if player:
			player.global_position = Vector2(304, 400)
			if "invuln" in player:
				player.invuln = 99999.0
		for _i in range(4):
			await process_frame
	await _save("godot_play")

	# Pause overlay (HTML #pausescreen during play) — re-center after force_ui_size
	GameState.set_state(GameState.State.PAUSED)
	_force_ui_size(_main)
	var pause_ui = _main.get_node_or_null("UI/PauseMenu")
	if pause_ui and pause_ui.has_method("_center_panel") and pause_ui.get("panel"):
		pause_ui._center_panel(pause_ui.panel as PanelContainer, 380.0)
	# Clear emblem toast so dual matches HTML (toast under pause dim, not over card)
	var ch = _A("CombatHelpers")
	if ch and "flash_msg" in ch:
		ch.flash_msg = {}
	var ps = _A("ProgressStore")
	if ps and ps.has_meta("emblem_toasts"):
		ps.set_meta("emblem_toasts", [])
	for _i in range(6 if fast else 10):
		await process_frame
		if pause_ui and pause_ui.has_method("_center_panel") and pause_ui.get("panel"):
			pause_ui._center_panel(pause_ui.panel as PanelContainer, 380.0)
	await _save("godot_flow_pause")
	GameState.set_state(GameState.State.PLAY)

	if StageFlow and StageFlow.has_method("spawn_clear_gate"):
		StageFlow.spawn_clear_gate()
	GameState.set_state(GameState.State.PLAY)
	_force_ui_size(_main)
	if flow and flow.has_method("queue_redraw"):
		flow.queue_redraw()
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_flow_cleargate")

	if StageFlow and StageFlow.has_method("enter_shop"):
		StageFlow.enter_shop()
	else:
		GameState.set_state(GameState.State.SHOP)
	_force_ui_size(_main)
	if flow and flow.has_method("queue_redraw"):
		flow.queue_redraw()
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_flow_shop")

	# clear_info keys match StageFlow.on_boss_defeated / HTML clearInfo
	GameState.session_score = 13300
	GameState.total_kills = 39
	if StageFlow:
		StageFlow.clear_info = {
			"stage": 0,
			"killsThisStage": 39,
			"total": 39,
			"emblems": [],
		}
		StageFlow.kills_this_stage = 39
	GameState.set_state(GameState.State.STAGE_CLEAR)
	_force_ui_size(_main)
	if flow and flow.has_method("queue_redraw"):
		flow.queue_redraw()
	for _i in range(6 if fast else 10):
		await process_frame
	await _save("godot_flow_stageclear")

	# End screens — mirror HTML dual: no name-entry chrome (canvas-only compare)
	var end_ui = _main.get_node_or_null("UI/EndScreen")
	var p2 = _A("P2Meta")
	if p2:
		p2.name_entry_open = false
		p2.just_saved_score = false
		p2.end_won = false
	if end_ui and end_ui.get("handle_edit"):
		end_ui.handle_edit.visible = false
	GameState.session_score = 125000
	GameState.total_kills = 420
	GameState.lives = 0
	GameState.set_state(GameState.State.GAMEOVER)
	if p2:
		p2.name_entry_open = false
		p2.end_won = false
	if end_ui and end_ui.get("handle_edit"):
		end_ui.handle_edit.visible = false
	_force_ui_size(_main)
	if end_ui and end_ui.has_method("queue_redraw"):
		end_ui.queue_redraw()
	for _i in range(8 if fast else 12):
		await process_frame
	await _save("godot_end_gameover")

	GameState.session_score = 2500000
	GameState.total_kills = 9001
	if p2:
		p2.name_entry_open = false
		p2.end_won = true
	if end_ui and end_ui.get("handle_edit"):
		end_ui.handle_edit.visible = false
	GameState.set_state(GameState.State.WIN)
	if p2:
		p2.name_entry_open = false
	if end_ui and end_ui.get("handle_edit"):
		end_ui.handle_edit.visible = false
	_force_ui_size(_main)
	if end_ui and end_ui.has_method("queue_redraw"):
		end_ui.queue_redraw()
	for _i in range(8 if fast else 12):
		await process_frame
	await _save("godot_end_win")
	if not fast:
		# Outfit previews on title (mini Bobina) + force outfits menu for model parity
		for outfit in ["og", "maid", "honeypot", "cabal"]:
			GameState.selected_outfit = outfit
			GameState.set_state(GameState.State.TITLE)
			_force_ui_size(_main)
			var bob = _sv.find_child("BobinaSprite", true, false)
			if bob and bob.has_method("set_outfit"):
				bob.set_outfit(outfit)
			for _i in range(8):
				await process_frame
			await _save("godot_outfit_" + outfit)

		# Fresh play at power 6 for combat dual
		GameState.start_run()
		GameState.set_state(GameState.State.PLAY)
		GameState.power = 6.0
		GameState.lives = 99
		player = root.get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = Vector2(304, 400)
			if "invuln" in player:
				player.invuln = 99999.0
		for i in range(fire_frames):
			await process_frame
			if player and "invuln" in player:
				player.invuln = 99999.0
			if player and player.get("fire_sys") and player.get("bullet_pool"):
				player.fire_sys.try_fire(player, player.bullet_pool, false)
		await _save("godot_play_power6")

	print("[SHOT] done dir=", ProjectSettings.globalize_path(_shot_dir()))
	print("[SHOT] PASS")
	quit(0)
