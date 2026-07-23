extends Node
## 1:1 HTML keyPress — central action router for all game states.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := _map_key(event as InputEventKey)
		if k != "":
			key_press(k)
			get_viewport().set_input_as_handled()
	elif event is InputEventAction and event.pressed:
		# Fallback if action events arrive
		pass

func _map_key(e: InputEventKey) -> String:
	## Resolve HTML-style action name from key event via InputMap
	for action in [
		"shoot", "bomb", "special", "cycle_special", "swap", "melee", "meleeswap",
		"item_switch", "item_use", "interact", "focus", "pause", "ui_accept", "ui_cancel",
		"move_left", "move_right", "move_up", "move_down",
	]:
		if InputMap.has_action(action) and e.is_action_pressed(action):
			return _html_name(action)
	# bare keys
	match e.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER: return "start"
		KEY_ESCAPE: return "menu"
		KEY_T: return "tweet"
		KEY_F: return "fire"  # auto-fire toggle (HTML)
		_: return ""

func _html_name(action: String) -> String:
	match action:
		"cycle_special": return "cycle"
		"ui_accept": return "start"
		"ui_cancel": return "menu"
		"move_left": return "left"
		"move_right": return "right"
		"move_up": return "up"
		"move_down": return "down"
		_: return action

func key_press(k: String) -> void:
	## HTML keyPress(k)
	var state = GameState.state
	# Arsenal exit
	if state == GameState.State.ARSENAL:
		if k in ["start", "shoot", "melee", "menu", "bomb"]:
			GameState.return_to_title()
		return
	# Shop keyboard
	if state == GameState.State.SHOP:
		_shop_key(k)
		return
	# Portal / shop interact during cleared play
	if k == "interact" and state == GameState.State.PLAY and StageFlow:
		if StageFlow.clear_shop != null and _near(StageFlow.clear_shop, 40.0):
			StageFlow.enter_shop()
			return
		if StageFlow.clear_portal != null and _near(StageFlow.clear_portal, 44.0):
			StageFlow.enter_portal()
			return
	# Start / advance screens
	if k in ["start", "shoot", "melee"]:
		if state == GameState.State.TITLE:
			GameState.start_run()
			return
		if state in [
			GameState.State.INTRO, GameState.State.STAGE_CLEAR, GameState.State.WIN,
			GameState.State.GAMEOVER, GameState.State.LEADERBOARD, GameState.State.EMBLEMS,
			GameState.State.OUTFITS, GameState.State.NG_SELECT,
		]:
			if StageFlow and StageFlow.has_method("advance_screen"):
				StageFlow.advance_screen()
			elif state in [GameState.State.WIN, GameState.State.GAMEOVER]:
				GameState.start_run()
			else:
				GameState.set_state(GameState.State.PLAY)
			return
	# Pause toggle works from PLAY or PAUSED (HTML pause button)
	if k == "pause":
		if state == GameState.State.PLAY:
			GameState.set_state(GameState.State.PAUSED)
			get_tree().paused = true
			return
		if state == GameState.State.PAUSED:
			GameState.set_state(GameState.State.PLAY)
			get_tree().paused = false
			return
	# Play actions
	if state == GameState.State.PLAY:
		if k == "item_switch":
			var p = _player()
			if p and p.get("consumables"):
				p.consumables.cycle()
		if k == "meleeswap":
			_cycle_melee()
		if k == "focus":
			# double-tap dash is handled in Player; keep for HTML parity hook
			pass
		if k == "bomb":
			var p2 = _player()
			if p2 and p2.has_method("_try_bomb"):
				p2._try_bomb()
		if k == "swap":
			CombatHelpers.swap_weapon()
		if k == "special":
			var p3 = _player()
			if p3 and p3.get("specials") and GameState.specials.size():
				p3.specials.use(str(GameState.specials[0]), p3, p3.get("bullet_pool"))
		if k == "cycle":
			CombatHelpers.cycle_special()
		if k == "fire":
			# HTML autoFire toggle
			var st: Dictionary = ProgressStore.progress.get("settings", {})
			st["autofire"] = not bool(st.get("autofire", true))
			ProgressStore.progress["settings"] = st
			ProgressStore.queue_save()
			if AudioBus:
				AudioBus.sfx("item")
	# Tweet on end screens
	if k == "tweet" and state in [GameState.State.WIN, GameState.State.GAMEOVER]:
		if P2Meta and P2Meta.has_method("tweet_result"):
			P2Meta.tweet_result(state == GameState.State.WIN)
	# Menu return
	if k == "menu" and state != GameState.State.TITLE:
		if state == GameState.State.PLAY:
			return
		GameState.return_to_title()
		if AudioBus:
			AudioBus.sfx("item")
	# Paging
	if state == GameState.State.LEADERBOARD:
		pass  # TitleScreen model handles lb pages via click; keys optional
	if state == GameState.State.EMBLEMS:
		pass

func _shop_key(k: String) -> void:
	if k in ["interact", "menu"]:
		if StageFlow:
			StageFlow.leave_shop()
		return
	if k in ["swap", "cycle", "item_switch", "item_use"]:
		var tabs = ["w", "s", "m", "i"]
		if StageFlow:
			var i = tabs.find(StageFlow.shop_tab)
			StageFlow.shop_tab = tabs[(i + 1) % tabs.size()]
			StageFlow.shop_sel = 0
			if AudioBus:
				AudioBus.sfx("item")
		return
	if k == "left" and StageFlow:
		var n = maxi(1, StageFlow.shop_btns.size())
		StageFlow.shop_sel = (StageFlow.shop_sel + n - 1) % n
		if AudioBus:
			AudioBus.sfx("item")
	if k == "right" and StageFlow:
		var n2 = maxi(1, StageFlow.shop_btns.size())
		StageFlow.shop_sel = (StageFlow.shop_sel + 1) % n2
		if AudioBus:
			AudioBus.sfx("item")
	if k in ["shoot", "melee", "start"] and StageFlow:
		# buy selected — FlowUI handles full shop; trigger buy via StageFlow if available
		if StageFlow.has_method("shop_buy_selected"):
			StageFlow.shop_buy_selected()

func _near(pt, r: float) -> bool:
	var p = _player()
	if p == null or pt == null:
		return false
	var x = float(pt.get("x", 0)) if typeof(pt) == TYPE_DICTIONARY else float(pt.x)
	var y = float(pt.get("y", 0)) if typeof(pt) == TYPE_DICTIONARY else float(pt.y)
	return p.global_position.distance_to(Vector2(x, y)) < r

func _cycle_melee() -> void:
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var ms: Array = ar.get("m", ["katana"])
	if ms.size() < 2:
		return
	# rotate
	var first = ms[0]
	ms.remove_at(0)
	ms.append(first)
	ar["m"] = ms
	ProgressStore.progress["arsenal"] = ar
	var mdef = {}
	for m in DataRegistry.melee:
		if str(m.get("key")) == str(ms[0]):
			mdef = m
			break
	if AudioBus:
		AudioBus.sfx("item")
	CombatHelpers.flash("%s %s" % [mdef.get("icon", "🗡"), mdef.get("name", ms[0])], 75.0)

func _player() -> Node:
	return get_tree().get_first_node_in_group("player") if get_tree() else null
