extends Node
## 1:1 ports of remaining HTML P2 meta helpers (arsenal, score, tweet, run init).
## Autoload-style usage via class methods on a singleton instance attached from TitleScreen/Main.

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

## HTML lastSubmit — used by lbIsMine highlight
var last_submit: Dictionary = {}
var just_saved_score: bool = false
var end_won: bool = false
var new_emblems: Array = []  # emblem ids earned this run
var name_entry_open: bool = false
var shoutouts_open: bool = false

func apply_diff() -> void:
	## HTML applyDiff
	GameState.apply_difficulty()

func diff_name() -> String:
	## HTML diffName
	return ["NORMAL", "HARD", "HELL"][clampi(GameState.difficulty, 0, 2)]

func mode_tag() -> String:
	return GameState.mode_tag()

func em_page_count() -> int:
	return MenuHelpers.em_page_count()

func ars_arr(type: String) -> Array:
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var a = ar.get(type, [])
	return a.duplicate() if a is Array else []

func save_arsenal() -> void:
	## HTML saveArsenal — ProgressStore already owns arsenal dict
	ProgressStore.queue_save()
	_apply_arsenal_to_run()

func ars_item_by_key(type: String, k: String) -> Dictionary:
	if type == "w":
		if DataRegistry.weapons.has(k):
			var w: Dictionary = DataRegistry.weapons[k].duplicate()
			w["key"] = k
			return w
		return {}
	if type == "s":
		for s in DataRegistry.specials:
			if str(s.get("key")) == k:
				return s
		return {}
	if type == "m":
		for m in DataRegistry.melee:
			if str(m.get("key")) == k:
				return m
		return {}
	for c in DataRegistry.consumables:
		if str(c.get("key")) == k:
			return c
	return {}

func toggle_arsenal(type: String, key: String) -> void:
	## HTML toggleArsenal
	var arr = ars_arr(type)
	var cap: int = int(MenuHelpers.ARS_CAP.get(type, 5))
	var min_keep = 0 if type == "s" or type == "i" else 1
	var i = arr.find(key)
	if i >= 0:
		if arr.size() > min_keep:
			arr.remove_at(i)
			_set_ars(type, arr)
			_sfx("item")
		else:
			_sfx("hit")
	else:
		if arr.size() < cap:
			arr.append(key)
			_set_ars(type, arr)
			_sfx("power")
		else:
			_sfx("hit")

func move_arsenal(type: String, key: String, dir: int) -> void:
	## HTML moveArsenal — shift loadout order
	var arr = ars_arr(type)
	var i = arr.find(key)
	var j = i + dir
	if i < 0 or j < 0 or j >= arr.size():
		_sfx("hit")
		return
	var tmp = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
	_set_ars(type, arr)
	_sfx("item")

func unequip_arsenal(type: String, key: String) -> void:
	## HTML unequipArsenal
	var arr = ars_arr(type)
	var min_k = 0 if type == "s" or type == "i" else 1
	var i = arr.find(key)
	if i >= 0 and arr.size() > min_k:
		arr.remove_at(i)
		_set_ars(type, arr)
		_sfx("item")
	else:
		_sfx("hit")

func _set_ars(type: String, arr: Array) -> void:
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	if typeof(ar) != TYPE_DICTIONARY:
		ar = {}
	ar[type] = arr
	ProgressStore.progress["arsenal"] = ar
	save_arsenal()

func _apply_arsenal_to_run() -> void:
	## HTML applyArsenalToRun (subset)
	var w = ars_arr("w")
	var s = ars_arr("s")
	GameState.weapons.clear()
	for x in w:
		GameState.weapons.append(str(x))
	if GameState.weapons.is_empty():
		GameState.weapons.append("laser")
	if GameState.weapons.find(GameState.current_weapon) < 0:
		GameState.current_weapon = GameState.weapons[0]
	GameState.specials.clear()
	for x in s:
		GameState.specials.append(str(x))

func armed_spec() -> Dictionary:
	## HTML armedSpec
	if GameState.specials.is_empty():
		return {}
	var idx = 0
	var player = _player()
	if player and player.get("armed_special") != null:
		idx = int(player.armed_special)
	var key = str(GameState.specials[idx % GameState.specials.size()])
	for sp in DataRegistry.specials:
		if str(sp.get("key")) == key:
			return sp
	return {}

func add_weapon(key: String, def: Dictionary) -> String:
	## HTML addWeapon — runtime registry extend
	DataRegistry.weapons[key] = def
	if DataRegistry.weapon_order.find(key) < 0:
		DataRegistry.weapon_order.append(key)
	return key

func add_special(def: Dictionary) -> int:
	DataRegistry.specials.append(def)
	return DataRegistry.specials.size() - 1

func add_melee(def: Dictionary) -> int:
	DataRegistry.melee.append(def)
	return DataRegistry.melee.size() - 1

func add_bomb(def: Dictionary) -> int:
	DataRegistry.bombs.append(def)
	return DataRegistry.bombs.size() - 1

func new_run() -> void:
	## HTML newRun — full session reset then start
	just_saved_score = false
	end_won = false
	new_emblems.clear()
	last_submit = {}
	GameState.session_score = 0
	GameState.total_kills = 0
	_apply_arsenal_to_run()
	# HTML: lives 6, bombs 3, power 1.0, special meter starts 15
	GameState.lives = 6
	GameState.bombs = 3
	GameState.power = 1.0
	GameState.special_meter = 15.0
	GameState.stage_index = 0
	GameState.run_no_death = true
	GameState.run_no_bomb = true
	GameState.apply_difficulty()
	if GameState.weapons.size():
		GameState.current_weapon = GameState.weapons[0]
	init_player()
	GameState.set_state(GameState.State.INTRO)
	GameState.run_started.emit()
	GameState.score_changed.emit(GameState.session_score, GameState.total_kills, GameState.rank_letter())

func init_player() -> void:
	## HTML initPlayer — reset player node fields
	var p = _player()
	if p == null:
		return
	var pf: Rect2 = Config.playfield()
	p.global_position = Vector2(pf.position.x + pf.size.x * 0.5, pf.position.y + pf.size.y - 70.0)
	if p.get("invuln") != null:
		p.invuln = 120.0
	if p.get("focus") != null:
		p.focus = false
	if p.get("dash") != null:
		p.dash = 0.0
	if p.get("dash_cd") != null:
		p.dash_cd = 0.0
	if p.get("knock") != null:
		p.knock = 0.0
	if p.get("bomb_fx") != null:
		p.bomb_fx = 0.0
	if p.get("phase_t") != null:
		p.phase_t = 0.0
	if p.get("shield_t") != null:
		p.shield_t = 0.0
	if p.get("rapid_t") != null:
		p.rapid_t = 0.0
	if p.get("aim") != null:
		p.aim = -PI / 2.0
	if p.has_node("Sprite/BobinaSprite"):
		p.get_node("Sprite/BobinaSprite").set_outfit(GameState.selected_outfit)

func fetch_lb() -> void:
	## HTML fetchLB
	ApiClient.fetch_scores()

func submit_score(handle: String = "") -> void:
	## HTML submitScore
	var h = handle.strip_edges().replace("@", "").replace("<", "").replace(">", "").replace(" ", "")
	if h.length() > 15:
		h = h.substr(0, 15)
	if h != "":
		ProgressStore.progress["handle"] = h
		ProgressStore.queue_save()
	var linked = ApiClient.authenticated
	var me: Dictionary = ApiClient.me
	last_submit = {
		"handle": str(me.get("xUsername", h)) if linked else h,
		"score": GameState.session_score,
		"kills": GameState.total_kills,
		"bcId": me.get("bcId") if linked else null,
		"bobinaUsername": me.get("username") if linked else null,
	}
	var payload = {
		"handle": h if not linked else str(me.get("xUsername", h)),
		"score": GameState.session_score,
		"kills": GameState.total_kills,
		"rank": GameState.rank_letter(),
		"mode": GameState.mode_tag(),
		"won": 1 if end_won else 0,
		"outfit": GameState.selected_outfit,
	}
	ApiClient.submit_score(payload)
	just_saved_score = true

func lb_is_mine(e: Dictionary) -> bool:
	## HTML lbIsMine — lastSubmit match (not only auth)
	if last_submit.is_empty():
		return false
	if last_submit.get("bcId") != null and e.get("bcId") != null:
		if str(last_submit["bcId"]) == str(e["bcId"]):
			return true
	return str(e.get("handle", "")) == str(last_submit.get("handle", "")) \
		and int(e.get("score", -1)) == int(last_submit.get("score", -2)) \
		and int(e.get("kills", -1)) == int(last_submit.get("kills", -2))

func tweet_result(won: bool) -> void:
	## HTML tweetResult
	var rank: String = GameState.rank_letter()
	var handle = str(ProgressStore.progress.get("handle", "")).replace(" ", "")
	handle = handle.replace("@", "")
	var head = "🐻 BOBO IS SAVED! 🎀" if won else "🐂 The Mumu horde got me..."
	var body = "I exterminated the WHOLE Mumu army and beat James Wynn!" if won \
		else "I went down swinging against the Mumu army."
	var stats = "📊 %d Mumus · Rank %s · %s pts" % [
		GameState.total_kills, rank, MenuHelpers.fmt_score(GameState.session_score)
	]
	if GameState.difficulty > 0 or GameState.ng_plus > 0:
		stats += " · " + GameState.mode_tag()
	var text = "\n".join([
		"%s 🎮 Bobina: KILL ALL MUMUS!!" % head, "",
		body, stats, "",
		"Think you can top me? 👇" if won else "Bet you can’t do better. 👇",
		"@Bobina_Council @EmblemVault @bobocouncil",
		"#KillAllMumus #EmblemAI $EMBLEM",
	])
	var base = Config.api_base_url if Config.api_base_url != "" else "https://killallmumus.com"
	var sp = "%s/share/%s?s=%d&k=%d&r=%s" % [
		base.rstrip("/"),
		"win" if won else "over",
		GameState.session_score,
		GameState.total_kills,
		rank.uri_encode(),
	]
	if handle != "":
		sp += "&h=" + handle.uri_encode()
	var u = "https://twitter.com/intent/tweet?text=%s&url=%s" % [text.uri_encode(), sp.uri_encode()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open('%s','_blank','noopener')" % u.replace("'", "\\'"))
	else:
		OS.shell_open(u)

func show_name_entry_or_submit() -> void:
	## HTML showNameEntry — linked users auto-submit
	if ApiClient.authenticated:
		var me: Dictionary = ApiClient.me
		submit_score(str(me.get("xUsername", ProgressStore.progress.get("handle", ""))))
		just_saved_score = true
		GameState.set_state(GameState.State.WIN if end_won else GameState.State.GAMEOVER)
		name_entry_open = false
		return
	name_entry_open = true
	GameState.set_state(GameState.State.WIN if end_won else GameState.State.GAMEOVER)

func do_save_score(handle: String) -> void:
	## HTML doSaveScore
	submit_score(handle)
	name_entry_open = false
	just_saved_score = true

func open_shoutouts() -> void:
	shoutouts_open = true

func hide_name_entry() -> void:
	## HTML hideNameEntry
	name_entry_open = false

func arsenal_count(_type: String = "") -> int:
	## HTML arsenalCount — weapons + specials equipped
	return ars_arr("w").size() + ars_arr("s").size()

func apply_arsenal_to_run() -> void:
	## HTML applyArsenalToRun
	_apply_arsenal_to_run()

func melee_idx_list() -> Array:
	## HTML meleeIdxList
	var out: Array = []
	for k in ars_arr("m"):
		for i in range(DataRegistry.melee.size()):
			if str(DataRegistry.melee[i].get("key")) == str(k):
				out.append(i)
				break
	return out

func lb_page_count() -> int:
	## HTML lbPageCount — TitleScreen model owns pages; provide default
	return maxi(1, int(ceili(float(10) / float(MenuHelpers.LB_PER_PAGE))))

func lb_set_page(_n: int) -> void:
	## HTML lbSetPage — no-op at meta level; TitleScreen model handles paging
	pass

## HTML virtual joystick state
var joy := {"active": false, "vx": 0.0, "vy": 0.0}

func joy_reset() -> void:
	## HTML joyReset
	joy["active"] = false
	joy["vx"] = 0.0
	joy["vy"] = 0.0

func close_shoutouts() -> void:
	shoutouts_open = false

func _player() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")

func _sfx(t: String) -> void:
	if AudioBus:
		AudioBus.sfx(t)
