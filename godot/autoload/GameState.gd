extends Node
## High-level game flow: title → play → stage clear → win/gameover.

signal state_changed(new_state: StringName)
signal score_changed(score: int, kills: int, rank: String)
signal run_started
signal run_ended(won: bool)

enum State { TITLE, INTRO, PLAY, PAUSED, STAGE_CLEAR, SHOP, WIN, GAMEOVER, LEADERBOARD, OUTFITS, EMBLEMS, ARSENAL, NG_SELECT, SETTINGS }

var state: State = State.TITLE
var difficulty: int = 0  # 0 NORMAL 1 HARD 2 HELL
var ng_plus: int = 0
var hard_mode: bool = false
var hell_mode: bool = false

var stage_index: int = 0
var session_score: int = 0
var total_kills: int = 0
var lives: int = 3
var bombs: int = 3
var power: float = 0.0
var special_meter: float = 0.0
var selected_outfit: String = "og"
var current_weapon: String = "laser"
var weapons: Array[String] = ["laser"]
var specials: Array[String] = ["mech", "bearzooka"]
var run_no_death: bool = true
var run_no_bomb: bool = true
var speedrun: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(delta: float) -> void:
	## HTML update(): power bleed 0.00085/frame when power>1, not in dialog, not stage-cleared
	if state != State.PLAY:
		return
	if power <= 1.0:
		return
	var cleared := bool(get_meta("stage_cleared", false))
	var dialog_open := false
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/StageFlow"):
		dialog_open = StageFlow.dialog != null
	if cleared or dialog_open:
		return
	# HTML runs at 60 sim frames; scale by delta*60 so wall-time matches
	var df := delta * 60.0
	power = maxf(1.0, power - 0.00085 * df)

func set_state(s: State) -> void:
	state = s
	state_changed.emit(State.keys()[s])

func apply_difficulty() -> void:
	hard_mode = difficulty >= 1
	hell_mode = difficulty >= 2

func mode_tag() -> String:
	var names := ["NORMAL", "HARD", "HELL"]
	var base: String = names[clampi(difficulty, 0, 2)]
	if ng_plus > 0:
		return "%s+%d" % [base, ng_plus]
	return base

func score_mul() -> float:
	## HTML scoreMult via CombatHelpers when available
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/CombatHelpers"):
		return CombatHelpers.score_mult()
	var rank_i: int = _rank_index()
	return (1.0 + rank_i * 0.5) * (1.0 + ng_plus) * (1.5 if hard_mode and not hell_mode else (2.2 if hell_mode else 1.0))

func threat_mul() -> float:
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/CombatHelpers"):
		return CombatHelpers.threat_mul()
	return (1.28 if hell_mode else 1.0) * (1.0 + ng_plus * 0.16)

func _rank_index() -> int:
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/CombatHelpers"):
		return CombatHelpers.rank_index()
	var order := ["D", "C", "B", "A", "S", "SS"]
	return maxi(0, order.find(DataRegistry.rank_for_kills(total_kills)))

func rank_letter() -> String:
	return DataRegistry.rank_for_kills(total_kills)

func start_run() -> void:
	## HTML newRun / startRun parity
	apply_difficulty()
	stage_index = 0
	session_score = 0
	total_kills = 0
	# HTML newRun: lives:6, bombs:3, power:1.0, special:15
	lives = 6
	bombs = 3
	power = 1.0
	special_meter = 15.0
	run_no_death = true
	run_no_bomb = true
	# sync arsenal weapons if present
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {}) if ProgressStore else {}
	if ar.get("w") is Array and (ar["w"] as Array).size():
		weapons.clear()
		for w in ar["w"]:
			weapons.append(str(w))
	if ar.get("s") is Array:
		specials.clear()
		for s in ar["s"]:
			specials.append(str(s))
	current_weapon = weapons[0] if weapons.size() else "laser"
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/P2Meta"):
		P2Meta.just_saved_score = false
		P2Meta.end_won = false
		P2Meta.new_emblems.clear()
		P2Meta.init_player()
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/ItemSystem"):
		ItemSystem.reset_run()
	if Engine.get_main_loop() and Engine.get_main_loop().root.get_node_or_null("/root/StageFlow"):
		StageFlow.reset_run()
	set_state(State.INTRO)
	run_started.emit()
	score_changed.emit(session_score, total_kills, rank_letter())

func add_score(amount: int) -> void:
	session_score += maxi(0, amount)
	score_changed.emit(session_score, total_kills, rank_letter())

func add_kill(n: int = 1) -> void:
	total_kills += n
	ProgressStore.estats_add("kills", n)
	score_changed.emit(session_score, total_kills, rank_letter())

func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	run_no_bomb = false
	ProgressStore.estats_add("bombs", 1)
	return true

func player_hit() -> void:
	run_no_death = false
	lives -= 1
	if lives < 0:
		end_run(false)

func clear_stage() -> void:
	set_state(State.STAGE_CLEAR)

func advance_stage() -> void:
	stage_index += 1
	if stage_index >= DataRegistry.stages.size():
		end_run(true)
	else:
		set_state(State.INTRO)

func end_run(won: bool) -> void:
	if won:
		ProgressStore.on_game_cleared(difficulty, ng_plus, speedrun, run_no_death, run_no_bomb)
		set_state(State.WIN)
	else:
		set_state(State.GAMEOVER)
	# HTML: computeEmblems() + saveEstats() on win/gameover
	ProgressStore.compute_emblems()
	if session_score > int(ProgressStore.estats.get("best", 0)):
		ProgressStore.estats["best"] = session_score
	ProgressStore.save_estats()
	run_ended.emit(won)

func return_to_title() -> void:
	set_state(State.TITLE)
