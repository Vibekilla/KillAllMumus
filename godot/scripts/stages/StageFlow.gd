extends Node
## 1:1 HTML stage flow: clear portal/shop field → stageclear → shop → intro → play.

signal dialog_started(queue: Array, boss_data: Dictionary)
signal dialog_ended

var clear_portal = null  # {x,y} or null
var clear_shop = null
var clear_msg_t: float = 0.0
var clear_info: Dictionary = {}
var intro_timer: float = 0.0
var dialog = null  # {boss, queue, i, timer}
var shop_return: String = "stageclear"
var shop_tab: String = "w"
var shop_sel: int = 0
var shop_msg: String = ""
var shop_msg_t: float = 0.0
var shop_btns: Array = []
var stage_no_death: bool = true
var stage_no_bomb: bool = true
var kills_this_stage: int = 0
var stage_emblem_mark: int = 0

const FRAME := 60.0

func reset_run() -> void:
	clear_portal = null
	clear_shop = null
	clear_msg_t = 0.0
	clear_info = {}
	intro_timer = 0.0
	dialog = null
	shop_tab = "w"
	shop_sel = 0
	shop_msg = ""
	shop_msg_t = 0.0
	stage_no_death = true
	stage_no_bomb = true
	kills_this_stage = 0
	stage_emblem_mark = 0

func on_stage_start(intro_frames: float = -1.0) -> void:
	## HTML loadStage — reset field FX, burns, slowmo, items (not full newRun)
	## introTimer: newRun/loadStage=140; advanceScreen after stageclear=120
	## HTML: initPlayer(); run.bombs=Math.max(run.bombs,2); melee snap to loadout[0]
	stage_no_death = true
	stage_no_bomb = true
	kills_this_stage = 0
	stage_emblem_mark = P2Meta.new_emblems.size() if P2Meta else 0
	clear_portal = null
	clear_shop = null
	clear_msg_t = 0.0
	dialog = null
	if GameState.speedrun:
		intro_timer = 20.0
	elif intro_frames >= 0.0:
		intro_timer = intro_frames
	else:
		intro_timer = 140.0
	GameState.set_meta("stage_cleared", false)
	# HTML: run.bombs = Math.max(run.bombs, 2) every stage
	GameState.bombs = maxi(GameState.bombs, 2)
	if ItemSystem:
		ItemSystem.items.clear()
		ItemSystem.floaters.clear()
		ItemSystem.emotes.clear()
		ItemSystem.burns.clear()
		ItemSystem.fx.clear()
		ItemSystem.kills_this_stage = 0
	if CombatHelpers:
		if "particles" in CombatHelpers:
			CombatHelpers.particles.clear()
		if "score_texts" in CombatHelpers:
			CombatHelpers.score_texts.clear()
		if "melee_fx" in CombatHelpers:
			CombatHelpers.melee_fx.clear()
		if "fx" in CombatHelpers:
			CombatHelpers.fx.clear()
		if CombatHelpers.has_method("end_slowmo"):
			CombatHelpers.end_slowmo()
		elif GameState.has_meta("slowmo"):
			GameState.remove_meta("slowmo")
	# HTML initPlayer on each loadStage — bottom-center + iframe 120 (keeps shield/rapid)
	if P2Meta and P2Meta.has_method("init_player"):
		P2Meta.init_player()
	# Clear player special FX + fire CD
	var tree := get_tree()
	if tree:
		var pl = tree.get_first_node_in_group("player")
		if pl and pl.get("specials") and pl.specials.has_method("clear_field"):
			pl.specials.clear_field()
		if pl and pl.get("fire_sys"):
			# HTML loadStage: p.cd=0 only — do not zero global fire tick (braid/wave phase)
			if pl.fire_sys.has_method("reset_stage_cd"):
				pl.fire_sys.reset_stage_cd()
			elif pl.fire_sys.has_method("reset_run"):
				pl.fire_sys.fire_cd_frames = 0.0
		if pl and pl.get("consumables") != null:
			# HTML initPlayer zeros _eCd
			if "e_cd" in pl.consumables:
				pl.consumables.e_cd = 0.0
			if "e_held" in pl.consumables:
				pl.consumables.e_held = false
		# Clear non-boss enemies and bullets (HTML loadStage)
		for e in tree.get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.is_in_group("bosses"):
				e.queue_free()
		for b in tree.get_nodes_in_group("bosses"):
			if is_instance_valid(b):
				b.queue_free()
		var pool = tree.get_first_node_in_group("bullet_pool")
		if pool and pool.has_method("clear_all"):
			pool.clear_all()

func note_player_hit() -> void:
	stage_no_death = false

func note_bomb() -> void:
	stage_no_bomb = false

func note_kill() -> void:
	kills_this_stage += 1

func spawn_clear_gate() -> void:
	## HTML spawnClearGate
	if GameState.stage_index >= DataRegistry.stages.size() - 1:
		on_boss_defeated()
		return
	var pf: Rect2 = Config.playfield()
	clear_portal = {"x": pf.position.x + pf.size.x * 0.5, "y": pf.position.y + pf.size.y * 0.30}
	clear_shop = {"x": pf.position.x + pf.size.x * 0.80, "y": pf.position.y + pf.size.y * 0.55}
	clear_msg_t = 260.0
	# HTML: mumuHeads+=15; saveHeads() — boss head bounty
	if ProgressStore:
		if ProgressStore.has_method("set_heads"):
			ProgressStore.set_heads(int(ProgressStore.heads()) + 15)
		else:
			ProgressStore.progress["heads"] = int(ProgressStore.progress.get("heads", 0)) + 15
			if ProgressStore.has_method("save_heads"):
				ProgressStore.save_heads()
			else:
				ProgressStore.queue_save()
	if AudioBus:
		AudioBus.sfx("win")
	# stay in PLAY with field interactables
	GameState.set_state(GameState.State.PLAY)
	# flag cleared via meta
	GameState.set_meta("stage_cleared", true)
	# clear combatants
	var tree := get_tree()
	if tree:
		for e in tree.get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.queue_free()
		var pool := tree.get_first_node_in_group("bullet_pool")
		if pool and pool.has_method("clear_all"):
			pool.clear_all()

func enter_portal() -> void:
	## HTML enterPortal → onBossDefeated stageclear
	if AudioBus:
		AudioBus.sfx("bomb")
	on_boss_defeated()

func enter_shop() -> void:
	## HTML enterShop — field shop returns to play (portal still available)
	shop_return = "play"
	shop_sel = 0
	shop_tab = "w"
	if AudioBus:
		AudioBus.sfx("item")
	GameState.set_state(GameState.State.SHOP)

func leave_shop() -> void:
	## HTML leaveShop — back to play (field with portal) unless from stageclear flow
	if AudioBus:
		AudioBus.sfx("item")
	neutralize_inputs()
	if shop_return == "stageclear":
		# after stage clear screen → go intro next stage via advance
		advance_from_shop()
	else:
		GameState.set_state(GameState.State.PLAY)

func neutralize_inputs() -> void:
	## HTML neutralizeInputs — prevent transition key/tap from leaking into fire/melee/item
	var tree := get_tree()
	if tree == null:
		return
	var pl = tree.get_first_node_in_group("player")
	if pl == null:
		return
	if pl.get("melee") != null and pl.melee:
		if pl.melee.get("holding") != null:
			pl.melee.holding = false
		if pl.melee.get("charge") != null:
			pl.melee.charge = 0.0
	if pl.get("consumables") != null and pl.consumables:
		if "e_held" in pl.consumables:
			pl.consumables.e_held = false
	# Clear edge-triggered actions that just opened shop/portal
	for action in ["shoot", "melee", "bomb", "special", "item_use", "interact", "swap"]:
		if InputMap.has_action(action):
			Input.action_release(action)

func advance_from_shop() -> void:
	GameState.stage_index += 1
	if GameState.stage_index >= DataRegistry.stages.size():
		GameState.end_run(true)
	else:
		GameState.set_meta("stage_cleared", false)
		clear_portal = null
		clear_shop = null
		GameState.set_state(GameState.State.INTRO)

func on_boss_defeated() -> void:
	## HTML onBossDefeated
	if stage_no_death:
		ProgressStore.unlock_emblem("flawless")
	if stage_no_bomb:
		ProgressStore.unlock_emblem("no_bomb")
	if GameState.stage_index >= DataRegistry.stages.size() - 1:
		GameState.end_run(true)
		return
	var earned: Array = []
	if P2Meta:
		for i in range(stage_emblem_mark, P2Meta.new_emblems.size()):
			earned.append(P2Meta.new_emblems[i])
	clear_info = {
		"stage": GameState.stage_index,
		"killsThisStage": kills_this_stage,
		"total": GameState.total_kills,
		"emblems": earned,
	}
	clear_portal = null
	clear_shop = null
	GameState.set_meta("stage_cleared", false)
	GameState.set_state(GameState.State.STAGE_CLEAR)

func advance_screen() -> void:
	## HTML advanceScreen
	match GameState.state:
		GameState.State.INTRO:
			# HTML: state='play'; neutralizeInputs()
			neutralize_inputs()
			GameState.set_state(GameState.State.PLAY)
		GameState.State.STAGE_CLEAR:
			# HTML: loadStage(idx+1); state=intro; introTimer=120
			GameState.stage_index += 1
			if GameState.stage_index >= DataRegistry.stages.size():
				GameState.end_run(true)
			else:
				neutralize_inputs()
				# begin_current_stage → on_stage_start; request 120-frame intro
				set_meta("next_intro_frames", 120.0)
				GameState.set_state(GameState.State.INTRO)
		GameState.State.GAMEOVER, GameState.State.WIN:
			GameState.start_run()
		GameState.State.LEADERBOARD, GameState.State.EMBLEMS, GameState.State.OUTFITS, GameState.State.NG_SELECT:
			GameState.return_to_title()
		_:
			pass

func start_dialog(lines: Array, boss_data: Dictionary) -> void:
	## HTML startDialog
	if GameState.speedrun or lines.is_empty():
		dialog = null
		return
	var first: Dictionary = lines[0] if lines[0] is Dictionary else {"t": str(lines[0]), "w": 0}
	dialog = {
		"boss": boss_data,
		"queue": lines.duplicate(),
		"i": 0,
		"timer": CombatHelpers.line_time(str(first.get("t", ""))),
		"hurt": false,
	}
	dialog_started.emit(lines, boss_data)

func bobina_say(text: String, frames: float = 60.0, hurt: bool = false) -> void:
	## HTML bobinaSay — quick hurt/banter line in dialog bar (won't clobber non-hurt dialog)
	if dialog != null and not bool(dialog.get("hurt", false)):
		return
	if GameState.speedrun and not hurt:
		return
	dialog = {
		"boss": null,
		"queue": [{"w": 1, "t": text}],
		"i": 0,
		"timer": frames,
		"hurt": hurt,
	}
	dialog_started.emit(dialog["queue"], {})

func tick_dialog(delta: float) -> void:
	if dialog == null:
		return
	dialog["timer"] = float(dialog.get("timer", 0)) - delta * FRAME
	if float(dialog["timer"]) <= 0.0:
		dialog["i"] = int(dialog.get("i", 0)) + 1
		var q: Array = dialog.get("queue", [])
		if int(dialog["i"]) >= q.size():
			dialog = null
			dialog_ended.emit()
		else:
			var line = q[int(dialog["i"])]
			var txt := str(line.get("t", line) if line is Dictionary else line)
			dialog["timer"] = CombatHelpers.line_time(txt)

func twin_swap(boss: Node) -> void:
	## HTML twinSwap voluntary FX — flash, particles, card sfx, taunt dialog
	if boss == null:
		return
	# BossController already switched active_twin to the incoming twin
	var other := "igor"
	if "active_twin" in boss:
		other = str(boss.active_twin)
	CombatHelpers.flash("⟳ %s takes the strings" % ("IGOR" if other == "igor" else "GRICHKA"), 90.0)
	if AudioBus:
		AudioBus.sfx("card")
	var col := "#b48ce0" if other == "igor" else "#e0b84a"
	var bx := float(boss.global_position.x) if boss is Node2D else 0.0
	var by := float(boss.global_position.y) if boss is Node2D else 0.0
	for i in range(26):
		CombatHelpers.particles.append({
			"x": bx, "y": by,
			"vx": (randf() - 0.5) * 8.0, "vy": (randf() - 0.5) * 8.0,
			"life": 28.0, "c": col,
		})
	var pool := get_tree().get_first_node_in_group("bullet_pool") if get_tree() else null
	if pool and pool.has_method("clear_enemy"):
		pool.clear_enemy()
	# HTML: taunt only (no retort) if dialog free
	if dialog == null and "data" in boss and boss.data is Dictionary:
		var bd: Dictionary = boss.data
		var taunts = bd.get("taunts", [])
		if taunts is Array and (taunts as Array).size() > 0:
			var tlist: Array = taunts
			start_dialog([{"w": 0, "t": str(tlist[randi() % tlist.size()])}], bd)

func tick(delta: float) -> void:
	if clear_msg_t > 0.0:
		clear_msg_t = maxf(0.0, clear_msg_t - delta * FRAME)
	if shop_msg_t > 0.0:
		shop_msg_t = maxf(0.0, shop_msg_t - delta * FRAME)
	if GameState.state == GameState.State.INTRO and intro_timer > 0.0:
		intro_timer = maxf(0.0, intro_timer - delta * FRAME)
	tick_dialog(delta)

func is_field_cleared() -> bool:
	return bool(GameState.get_meta("stage_cleared", false)) and clear_portal != null
