extends SceneTree
## Headless Godot visual capture via SubViewport + Xvfb (GL).
##   xvfb-run -a godot --path godot --script res://scripts/tools/screenshot_playtest.gd
##
## Env (set by tools/port/dual_playtest.mjs):
##   PLAYTEST_FAST=1|0   PLAYTEST_FULL=1|0
##   PLAYTEST_SHOTS=aura,items,elites,bosses   (empty = default matrix)
## Groups: core, wardrobe, faces, anims, weapons, melee, specials, aura,
##         items, elites, bosses, power6  (+ aliases shield→aura, outfit→wardrobe, …)

const OUT_SUB := "playtest_shots"
const VIEW_W := 960
const VIEW_H := 540

var _sv: SubViewport
var _main: Node
## Empty = no filter (respect fast/full defaults). Non-empty = only listed groups.
var _shot_set: Dictionary = {}
var _shot_filter: bool = false
var _fast: bool = true

func _init() -> void:
	call_deferred("_run")

func _A(n: String) -> Node:
	return root.get_node_or_null("/root/" + n)

func _parse_shot_filter() -> void:
	var raw := OS.get_environment("PLAYTEST_SHOTS").strip_edges()
	_shot_set.clear()
	_shot_filter = false
	if raw.is_empty():
		return
	_shot_filter = true
	for part in raw.split(","):
		var s := str(part).strip_edges().to_lower()
		if s.is_empty():
			continue
		var c := _canon_shot(s)
		_shot_set[c] = true
		if c == "combat" or s == "combat":
			_shot_set["weapons"] = true
			_shot_set["melee"] = true
			_shot_set["specials"] = true
			_shot_set["power6"] = true

func _canon_shot(s: String) -> String:
	match s:
		"outfit", "outfits", "wardrobe":
			return "wardrobe"
		"weapon", "weapons", "wep":
			return "weapons"
		"special", "specials":
			return "specials"
		"item", "items":
			return "items"
		"elite", "elites":
			return "elites"
		"boss", "bosses":
			return "bosses"
		"face", "faces":
			return "faces"
		"anim", "anims", "breath", "pose", "blink":
			return "anims"
		"menus", "menu", "flow", "ends", "title", "core", "play":
			return "core"
		"shield", "focus", "rapid", "vial", "phase", "dash", "bomb", "power", "aura":
			return "aura"
		"melee":
			return "melee"
		"power6", "combat":
			return s
		_:
			return s

func _want(group: String) -> bool:
	## No filter: core always; full-only groups when PLAYTEST_FULL / not fast.
	var g := _canon_shot(group)
	if not _shot_filter:
		match g:
			"wardrobe", "faces", "anims", "weapons", "melee", "specials", \
			"aura", "items", "elites", "bosses", "power6", "combat":
				return not _fast
			_:
				return true
	return _shot_set.has(g)

func _need_play() -> bool:
	return (
		_want("weapons") or _want("melee") or _want("specials") or _want("aura")
		or _want("items") or _want("elites") or _want("bosses") or _want("power6")
		or _want("faces") or _want("core")
	)

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

## Wipe combat clutter so dual stills match HTML forced states (no leftover portal/mobs/FX).
func _dual_sanitize(player, pool) -> void:
	var GS = _A("GameState")
	var StageFlow = _A("StageFlow")
	if StageFlow:
		if StageFlow.has_method("reset_run"):
			StageFlow.reset_run()
		else:
			StageFlow.clear_portal = null
			StageFlow.clear_shop = null
			StageFlow.clear_msg_t = 0.0
			StageFlow.dialog = null
		if GS:
			GS.set_meta("stage_cleared", false)
	for e in root.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	for b in root.get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(b):
			b.queue_free()
	for sp in root.get_tree().get_nodes_in_group("enemy_spawner"):
		if not is_instance_valid(sp):
			continue
		if sp.has_method("lock_for_dual"):
			sp.lock_for_dual()
		elif sp.has_method("clear"):
			sp.clear()
		# Pin spawner off for dual stills (clear alone is not enough if stage restarts)
		if "spawning" in sp:
			sp.spawning = false
		if "dual_lock" in sp:
			sp.dual_lock = true
		if "boss_spawned" in sp:
			sp.boss_spawned = true
		if "stage_time" in sp:
			sp.stage_time = 99999.0
	if pool and pool.has_method("clear_all"):
		pool.clear_all()
	elif pool and pool.has_method("clear"):
		pool.clear()
	var items = _A("ItemSystem")
	if items:
		if "items" in items:
			items.items.clear()
		if "floaters" in items:
			items.floaters.clear()
		if "burns" in items:
			items.burns.clear()
		if "emotes" in items:
			items.emotes.clear()
	var ch = _A("CombatHelpers")
	if ch:
		if "particles" in ch:
			ch.particles.clear()
		if "score_texts" in ch:
			ch.score_texts.clear()
		if "melee_fx" in ch:
			ch.melee_fx.clear()
		if "flash_msg" in ch:
			ch.flash_msg = {}
	if player:
		if "invuln" in player:
			player.invuln = 99999.0
		player.global_position = Vector2(304, 400)
		if "focus" in player:
			player.focus = false
		if "shield_t" in player:
			player.shield_t = 0.0
		if "rapid_t" in player:
			player.rapid_t = 0.0
		if "vial_t" in player:
			player.vial_t = 0.0
		if "vial_hits" in player:
			player.vial_hits = 0
		if "phase_t" in player:
			player.phase_t = 0.0
		if "dash" in player:
			player.dash = 0.0
		if "trail" in player:
			player.trail = []
		if "bomb_fx" in player:
			player.bomb_fx = 0.0
		var ms = player.get("melee")
		if ms and "swipe_fx" in ms:
			ms.swipe_fx.clear()
		var sp = player.get("specials")
		if sp and "fx" in sp:
			sp.fx.clear()
	if GS:
		GS.set_state(GS.State.PLAY)
		GS.lives = 99
	# Dual stills: no autofire + clear emblem toast chrome
	var PStore = _A("ProgressStore")
	if PStore:
		if "progress" in PStore:
			var st: Dictionary = PStore.progress.get("settings", {})
			if typeof(st) != TYPE_DICTIONARY:
				st = {}
			st["autofire"] = false
			PStore.progress["settings"] = st
		if PStore.has_meta("emblem_toasts"):
			PStore.set_meta("emblem_toasts", [])
	if player:
		player.set_meta("dual_lock_pose", true)
		player.set_meta("dual_aim", -PI / 2.0)
		player.set_meta("dual_hold_fx", true)
		player.set_meta("dual_expr", "")  # Auto/smile like HTML play stills
		if "aim" in player:
			player.aim = -PI / 2.0
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if "dash" in player:
			player.dash = 0.0
		if "trail" in player:
			player.trail = []
	# Hard-stop StageController from re-arming waves mid-still
	for sc in root.get_tree().get_nodes_in_group("stage_controller"):
		if is_instance_valid(sc) and "spawner" in sc and sc.spawner:
			var spn = sc.spawner
			if spn and "dual_lock" in spn:
				spn.dual_lock = true
			if spn and "spawning" in spn:
				spn.spawning = false

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

	_fast = OS.get_environment("PLAYTEST_FAST") != "0"
	if OS.get_environment("PLAYTEST_FULL") == "1":
		_fast = false
	_parse_shot_filter()
	var fast := _fast
	var play_frames := 90 if fast else 200
	var fire_frames := 40 if fast else 100
	if _shot_filter:
		print("[SHOT] filter=", ",".join(_shot_set.keys()))
	else:
		print("[SHOT] filter=all fast=", fast)

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
	if _want("core"):
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

	# Meta menus (core dual; skipped on sliced combat duals)
	if _want("core"):
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

	# Phase 2: Bobina anims + wardrobe (independently filterable via --shots)
	if (_want("anims") or _want("wardrobe")) and title and "model" in title and title.model:
		GameState.set_state(GameState.State.OUTFITS)
		_force_ui_size(_main)
		var sc2 = _A("SimClock")
		if _want("anims"):
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
		if _want("wardrobe"):
			# Full wardrobe via OUTFITS menu (HTML drawOutfits) — one stable tick per skin @ ×4.7 stage
			if sc2:
				sc2.paused = true
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
		if _want("anims"):
			# GIF overlays: talk (dialog), confused floater
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
	if _want("core"):
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
	var player = null
	var flow = _main.get_node_or_null("UI/FlowUI")
	if _need_play():
		GameState.difficulty = 0
		GameState.ng_plus = 0
		GameState.start_run()  # → INTRO
		_force_ui_size(_main)
		if flow and flow.has_method("queue_redraw"):
			flow.queue_redraw()
		for _i in range(6 if fast else 10):
			await process_frame
		if _want("core"):
			await _save("godot_flow_intro")

		GameState.set_state(GameState.State.PLAY)
		if StageFlow and StageFlow.has_method("on_stage_start"):
			StageFlow.on_stage_start()
		player = _sv.get_tree().get_first_node_in_group("player")
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
		# Short settle when sliced (no full play firing); long when core
		var settle := play_frames if _want("core") else (12 if fast else 24)
		for i in range(settle):
			await process_frame
			if player and "invuln" in player:
				player.invuln = 99999.0
			if player and player.get("fire_sys") and player.get("bullet_pool") and _want("core"):
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
		if _want("core"):
			await _save("godot_play")
	# Phase 2 minor: play-scale (×1) expression dual — force dual_expr on player
	if _want("faces") and player:
		var exprs = [null, "uwu", "smile", "squee", "giggle", "annoyed"]
		# Map VICTORY_FACES indices 0..5
		for face_i in range(exprs.size()):
			var ex = exprs[face_i]
			if ex == null:
				player.set_meta("dual_expr", "")  # Auto → null smile path
			else:
				player.set_meta("dual_expr", ex)
			player.global_position = Vector2(304, 400)
			if "invuln" in player:
				player.invuln = 99999.0
			var wd = _main.get_node_or_null("WorldCanvas")
			if wd and wd.get("bobina_cache") and wd.bobina_cache.has_method("clear_cache"):
				wd.bobina_cache.clear_cache()
			for _i in range(12):
				await process_frame
				if wd:
					wd.queue_redraw()
			await _save("godot_play_face_%d" % face_i)
		if player.has_meta("dual_expr"):
			player.remove_meta("dual_expr")

	# Phase 2 leftover: HUD-mini (~0.46) expression dual on leaderboard rows
	if _want("faces") and title and "model" in title and title.model:
		# Arm dual mode BEFORE LEADERBOARD so fetch does not wipe synthetic rows
		title.model.dual_hud_face = 0
		var rows: Array = []
		for face_i in range(6):
			rows.append({
				"name": "DualFace%d" % face_i,
				"score": 1000 * (6 - face_i),
				"kills": 10 + face_i,
				"outfit": "og",
				"linked": false,
			})
		GameState.set_state(GameState.State.LEADERBOARD)
		_force_ui_size(_main)
		title.model.lb_state = "ok"
		title.model.lb_page = 0
		title.model.lb_cache = rows
		for face_i in range(6):
			title.model.dual_hud_face = face_i
			title.model.victory_face = face_i
			title.model.lb_cache = rows
			title.model.lb_state = "ok"
			title.queue_redraw()
			for _i in range(8):
				await process_frame
				title.model.lb_cache = rows
				title.queue_redraw()
			await _save("godot_hud_face_%d" % face_i)
		title.model.dual_hud_face = -1

	# Pause / shop / ends — core flow dual only
	if _want("core") and player:
		GameState.set_state(GameState.State.PAUSED)
		_force_ui_size(_main)
		var pause_ui = _main.get_node_or_null("UI/PauseMenu")
		if pause_ui and pause_ui.has_method("_center_panel") and pause_ui.get("panel"):
			pause_ui._center_panel(pause_ui.panel as PanelContainer, 380.0)
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

	if _want("anims") or _want("wardrobe"):
		# Outfit previews on title (mini Bobina) — light subset
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

	if _want("power6") and player:
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

	# ── Phase 3: weapons / melee / specials / auras / items / elites / bosses ──
	if player and (_want("weapons") or _want("melee") or _want("specials") or _want("aura") or _want("items") or _want("elites") or _want("bosses")):
		GameState.set_state(GameState.State.PLAY)
		GameState.power = 6.0
		GameState.lives = 99
		if "invuln" in player:
			player.invuln = 99999.0
		player.global_position = Vector2(304, 400)
		var pool = player.get("bullet_pool")
		var fire = player.get("fire_sys")
		var playfield = _main.get_node_or_null("Playfield")
		var weps: Array = ["laser", "homing", "wave", "scatter", "gatling", "grenade", "voidripper", "lotus", "shock", "spread"]
		GameState.weapons.clear()
		for w in weps:
			GameState.weapons.append(w)
		_dual_sanitize(player, pool)
		for _i in range(8):
			await process_frame
			_dual_sanitize(player, pool)
		if _want("weapons"):
			for wep in weps:
				_dual_sanitize(player, pool)
				GameState.power = 6.0
				GameState.current_weapon = wep
				for i in range(18):
					await process_frame
					if "invuln" in player:
						player.invuln = 99999.0
					if fire and pool:
						fire.try_fire(player, pool, false)
				await _save("godot_wep_%s" % wep)
		if _want("melee"):
			var mkeys: Array = ["katana", "lash", "scythe", "hammer", "claws"]
			for mk in mkeys:
				_dual_sanitize(player, pool)
				GameState.power = 6.0
				var ms = player.get("melee")
				if ms:
					ms.cooldown = 0.0
					ms.charge = 1.0
					ms.holding = false
					ms.release(player, mk, -PI / 2.0)
				for _i in range(10):
					await process_frame
					if "invuln" in player:
						player.invuln = 99999.0
				await _save("godot_melee_%s" % mk)
		if _want("specials"):
			var skeys: Array = ["laser", "mech", "bearzooka", "vault", "stampede", "badger", "sixth", "revenge", "kiss", "kraken", "void"]
			var sp = player.get("specials")
			for sk in skeys:
				_dual_sanitize(player, pool)
				GameState.power = 6.0
				GameState.special_meter = 100.0
				if sp and sp.has_method("use"):
					sp.use(sk, player, pool)
				for _i in range(16):
					await process_frame
					if "invuln" in player:
						player.invuln = 99999.0
				await _save("godot_special_%s" % sk)

		if _want("aura"):
			_dual_sanitize(player, pool)
			for _i in range(8):
				await process_frame
				_dual_sanitize(player, pool)
			player.set_meta("dual_lock_pose", true)
			player.set_meta("dual_aim", -PI / 2.0)
			player.set_meta("dual_hold_fx", true)
			player.set_meta("dual_expr", "")
			player.global_position = Vector2(304, 400)
			player.aim = -PI / 2.0
			player.velocity = Vector2.ZERO
			for pwr in [1.0, 3.0, 6.0]:
				GameState.power = pwr
				player.set_meta("dual_focus", false)
				player.focus = false
				player.shield_t = 0.0
				player.rapid_t = 0.0
				player.vial_t = 0.0
				player.vial_hits = 0
				player.phase_t = 0.0
				player.dash = 0.0
				player.bomb_fx = 0.0
				player.trail = []
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
				player.velocity = Vector2.ZERO
				player.invuln = 99999.0
				for _i in range(8):
					await process_frame
					_dual_sanitize(player, pool)
					player.set_meta("dual_lock_pose", true)
					player.set_meta("dual_hold_fx", true)
					player.aim = -PI / 2.0
					player.global_position = Vector2(304, 400)
					player.velocity = Vector2.ZERO
					player.focus = false
					player.dash = 0.0
					player.trail = []
					for e in root.get_tree().get_nodes_in_group("enemies"):
						if is_instance_valid(e) and not e.is_in_group("bosses"):
							e.queue_free()
					if playfield:
						for c in playfield.get_children():
							if not is_instance_valid(c):
								continue
							if c.is_in_group("player") or c.is_in_group("bosses"):
								continue
							if c.is_in_group("enemies") or c.get("kind") != null:
								c.queue_free()
					var chp = _A("CombatHelpers")
					if chp and "particles" in chp:
						chp.particles.clear()
				await _save("godot_aura_power_%d" % int(pwr))
			# Variant stills — pin each FX flag like HTML __kamDual.setAura
			GameState.power = 4.0
			player.set_meta("dual_focus", true)
			player.focus = true
			player.invuln = 40.0
			player.shield_t = 0.0
			player.rapid_t = 0.0
			player.vial_t = 0.0
			player.phase_t = 0.0
			player.dash = 0.0
			player.bomb_fx = 0.0
			player.trail = []
			for _i in range(6):
				await process_frame
				_dual_sanitize(player, pool)
				player.set_meta("dual_focus", true)
				player.set_meta("dual_hold_fx", true)
				player.focus = true
				player.invuln = 40.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
				player.velocity = Vector2.ZERO
			await _save("godot_aura_focus")
			player.set_meta("dual_focus", false)
			player.focus = false
			player.invuln = 99999.0
			player.shield_t = 120.0
			for _i in range(6):
				await process_frame
				player.shield_t = 120.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
				player.velocity = Vector2.ZERO
				for e in root.get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and not e.is_in_group("bosses"):
						e.queue_free()
			await _save("godot_aura_shield")
			player.shield_t = 0.0
			player.rapid_t = 120.0
			for _i in range(6):
				await process_frame
				player.rapid_t = 120.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
			await _save("godot_aura_rapid")
			player.rapid_t = 0.0
			player.vial_t = 120.0
			player.vial_hits = 3
			for _i in range(6):
				await process_frame
				player.vial_t = 120.0
				player.vial_hits = 3
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
			await _save("godot_aura_vial")
			player.vial_t = 0.0
			player.vial_hits = 0
			player.phase_t = 120.0
			for _i in range(6):
				await process_frame
				player.phase_t = 120.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
			await _save("godot_aura_phase")
			player.phase_t = 0.0
			player.dash = 12.0
			player.dash_ang = -PI / 2.0
			player.trail = []
			for i in range(8):
				player.trail.push_front({"wx": player.global_position.x, "wy": player.global_position.y + float(i) * 6.0})
			for _i in range(4):
				await process_frame
				player.dash = 12.0
				player.dash_ang = -PI / 2.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
				player.velocity = Vector2.ZERO
				if player.trail.is_empty():
					for i in range(8):
						player.trail.push_front({"wx": player.global_position.x, "wy": player.global_position.y + float(i) * 6.0})
			await _save("godot_aura_dash")
			player.dash = 0.0
			player.trail = []
			player.bomb_fx = 30.0
			for _i in range(4):
				await process_frame
				player.bomb_fx = 30.0
				player.aim = -PI / 2.0
				player.global_position = Vector2(304, 400)
			await _save("godot_aura_bomb")
			player.bomb_fx = 0.0

		if _want("items"):
			_dual_sanitize(player, pool)
			GameState.power = 1.0
			for _i in range(8):
				await process_frame
				_dual_sanitize(player, pool)
			GameState.power = 1.0
			var items_sys = _A("ItemSystem")
			if items_sys:
				items_sys.items.clear()
				var item_types: Array = [
					"power", "fullpower", "point", "life", "bomb", "shield", "rapid", "skull", "weapon",
				]
				var cfg_node = _A("Config")
				var pf_rect: Rect2 = cfg_node.playfield() if cfg_node and cfg_node.has_method("playfield") else Rect2(48, 14, 512, 516)
				var col_n := 3
				for ii in range(item_types.size()):
					var tx := pf_rect.position.x + 80.0 + float(ii % col_n) * 140.0
					var ty := pf_rect.position.y + 100.0 + float(ii / col_n) * 100.0
					var extra := {}
					if str(item_types[ii]) == "skull":
						extra["val"] = 10
					if str(item_types[ii]) == "weapon":
						extra["wep"] = "laser"
					items_sys.drop_item(tx, ty, str(item_types[ii]), extra)
					if items_sys.items.size():
						var last: Dictionary = items_sys.items[items_sys.items.size() - 1]
						last["vx"] = 0.0
						last["vy"] = 0.0
						last["homing"] = false
				for _i in range(8):
					await process_frame
					for it in items_sys.items:
						if it is Dictionary:
							it["vx"] = 0.0
							it["vy"] = 0.0
					for e in root.get_tree().get_nodes_in_group("enemies"):
						if is_instance_valid(e) and not e.is_in_group("bosses"):
							e.queue_free()
					if pool and pool.has_method("clear_all"):
						pool.clear_all()
					var chp2 = _A("CombatHelpers")
					if chp2 and "particles" in chp2:
						chp2.particles.clear()
				await _save("godot_items_grid")
				items_sys.items.clear()

		var cfg2 = _A("Config")
		var pf2: Rect2 = cfg2.playfield() if cfg2 and cfg2.has_method("playfield") else Rect2(48, 14, 512, 516)
		if playfield == null:
			playfield = _main.get_node_or_null("Playfield")
		var DataRegistry = _A("DataRegistry")

		if _want("elites"):
			_dual_sanitize(player, pool)
			GameState.power = 1.0
			for _i in range(8):
				await process_frame
				_dual_sanitize(player, pool)
			GameState.power = 1.0
			var elites: Array = ["cheer", "ape", "badnik", "pup", "scammer", "voideye", "goon"]
			var EnemyScene = load("res://scenes/enemies/Enemy.tscn")
			if EnemyScene and playfield:
				for ei in range(elites.size()):
					var ek: String = str(elites[ei])
					var en = EnemyScene.instantiate()
					playfield.add_child(en)
					var ex := pf2.position.x + 80.0 + float(ei % 4) * 100.0
					var ey := pf2.position.y + 120.0 + float(ei / 4) * 140.0
					if en.has_method("setup"):
						en.setup(pool, Vector2(ex, ey), {
							"kind": "elite",
							"hp": 9999.0,
							"vel": Vector2.ZERO,
							"icy": false,
							"r": 26.0,
							"score": 900,
							"hover": ey,
							"elite": ek,
						})
					if "vel" in en:
						en.vel = Vector2.ZERO
				for _i in range(10):
					await process_frame
					for e in root.get_tree().get_nodes_in_group("enemies"):
						if not is_instance_valid(e) or e.is_in_group("bosses"):
							continue
						if str(e.get("kind")) != "elite":
							e.queue_free()
							continue
						if "vel" in e:
							e.vel = Vector2.ZERO
					if pool and pool.has_method("clear_all"):
						pool.clear_all()
					var chp3 = _A("CombatHelpers")
					if chp3 and "particles" in chp3:
						chp3.particles.clear()
				await _save("godot_elites_grid")
				for e in root.get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and not e.is_in_group("bosses"):
						e.queue_free()
				for _i in range(3):
					await process_frame

		if _want("bosses"):
			var BossScene = load("res://scenes/enemies/Boss.tscn")
			if BossScene and playfield and DataRegistry:
				for si in range(mini(7, DataRegistry.stages.size())):
					_dual_sanitize(player, pool)
					GameState.power = 1.0
					for _i in range(3):
						await process_frame
					GameState.stage_index = si
					var stage: Dictionary = DataRegistry.get_stage(si)
					var boss = BossScene.instantiate()
					playfield.add_child(boss)
					var boss_pos := Vector2(pf2.get_center().x, pf2.position.y + 140)
					boss.setup(pool, boss_pos, stage)
					# Visible body, pinned pose (no roam / no attack / no spin-facing)
					if "intro" in boss:
						boss.intro = 0.0
					if "dead" in boss:
						boss.dead = false
					if "stun" in boss:
						boss.stun = 99999.0
					if "special_t" in boss:
						boss.special_t = 0.0
					if "dash" in boss:
						boss.dash = false
					if "mtx" in boss:
						boss.mtx = boss_pos.x
					if "mty" in boss:
						boss.mty = boss_pos.y
					if "face" in boss:
						boss.face = PI / 2.0  # face down (HTML rest face)
					for _i in range(14):
						await process_frame
						if is_instance_valid(boss):
							boss.global_position = boss_pos
							if "intro" in boss:
								boss.intro = 0.0
							if "stun" in boss:
								boss.stun = 99999.0
							if "special_t" in boss:
								boss.special_t = 0.0
							if "dash" in boss:
								boss.dash = false
							if "mtx" in boss:
								boss.mtx = boss_pos.x
							if "mty" in boss:
								boss.mty = boss_pos.y
							if "face" in boss:
								boss.face = PI / 2.0
							if "t" in boss:
								# freeze pattern timers from advancing attack cadence
								boss.t = int(boss.t)
						# Drop wave trash + boss bullets so portrait is readable
						for e in root.get_tree().get_nodes_in_group("enemies"):
							if is_instance_valid(e) and not e.is_in_group("bosses"):
								e.queue_free()
						# Also sweep Playfield strays (some spawns skip groups briefly)
						if playfield:
							for c in playfield.get_children():
								if not is_instance_valid(c):
									continue
								if c.is_in_group("player") or c.is_in_group("bosses"):
									continue
								if c.is_in_group("enemies") or str(c.get_class()).find("Area") >= 0:
									if c != boss and c.get("kind") != null:
										c.queue_free()
						for spn in root.get_tree().get_nodes_in_group("enemy_spawner"):
							if is_instance_valid(spn) and "spawning" in spn:
								spn.spawning = false
						if pool and pool.has_method("clear_all"):
							pool.clear_all()
						var chb = _A("CombatHelpers")
						if chb and "particles" in chb:
							chb.particles.clear()
					var bname := str(stage.get("boss", {}).get("portrait", "boss%d" % si))
					await _save("godot_boss_%s" % bname)
					if is_instance_valid(boss):
						boss.queue_free()
				for _i in range(2):
					await process_frame

	print("[SHOT] done dir=", ProjectSettings.globalize_path(_shot_dir()))
	print("[SHOT] PASS")
	quit(0)
