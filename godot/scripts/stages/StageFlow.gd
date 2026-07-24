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

func on_stage_start() -> void:
	stage_no_death = true
	stage_no_bomb = true
	kills_this_stage = 0
	stage_emblem_mark = P2Meta.new_emblems.size() if P2Meta else 0
	clear_portal = null
	clear_shop = null
	intro_timer = 20.0 if GameState.speedrun else 140.0

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
	ProgressStore.progress["heads"] = int(ProgressStore.progress.get("heads", 0)) + 15
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
	if shop_return == "stageclear":
		# after stage clear screen → go intro next stage via advance
		advance_from_shop()
	else:
		GameState.set_state(GameState.State.PLAY)

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
			GameState.set_state(GameState.State.PLAY)
		GameState.State.STAGE_CLEAR:
			# HTML: loadStage(idx+1); state=intro
			GameState.stage_index += 1
			if GameState.stage_index >= DataRegistry.stages.size():
				GameState.end_run(true)
			else:
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
	}
	dialog_started.emit(lines, boss_data)

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
	## HTML twinSwap — extra FX on top of BossController swap
	if boss == null:
		return
	var other := "grichka" if str(boss.get("active_twin")) == "igor" else "igor"
	CombatHelpers.flash("⟳ %s takes the strings" % ("IGOR" if other == "igor" else "GRICHKA"), 90.0)
	if AudioBus:
		AudioBus.sfx("card")
	var col := "#b48ce0" if other == "igor" else "#e0b84a"
	for i in range(26):
		CombatHelpers.particles.append({
			"x": boss.global_position.x, "y": boss.global_position.y,
			"vx": (randf() - 0.5) * 8.0, "vy": (randf() - 0.5) * 8.0,
			"life": 28.0, "c": col,
		})
	var pool := get_tree().get_first_node_in_group("bullet_pool") if get_tree() else null
	if pool and pool.has_method("clear_enemy"):
		pool.clear_enemy()

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
