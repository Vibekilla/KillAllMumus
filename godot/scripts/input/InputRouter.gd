extends Node
## 1:1 HTML keyPress — central action router for all game states.
## Keyboard + gamepad (Steam/desktop) via InputMap; Player holds use is_action_pressed.

const GamepadMap = preload("res://scripts/input/GamepadMap.gd")

const ROUTABLE := [
	"shoot", "bomb", "special", "cycle_special", "swap", "melee", "meleeswap",
	"item_switch", "item_use", "interact", "focus", "pause", "ui_accept", "ui_cancel",
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	# Steam / Xbox-style defaults layered on keyboard binds
	GamepadMap.ensure_defaults()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := _map_key(event as InputEventKey)
		if k != "":
			key_press(k)
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		var jk := _map_joy(event as InputEventJoypadButton)
		if jk != "":
			key_press(jk)
			get_viewport().set_input_as_handled()
	elif event is InputEventAction and event.pressed:
		pass

func _map_key(e: InputEventKey) -> String:
	## Resolve HTML-style action name from key event via InputMap
	for action in ROUTABLE:
		if InputMap.has_action(action) and e.is_action_pressed(action):
			return _html_name(action)
	# bare keys
	match e.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER: return "start"
		KEY_ESCAPE: return "menu"
		KEY_T: return "tweet"
		_: return ""

func _map_joy(e: InputEventJoypadButton) -> String:
	## Map joypad button press to HTML keyPress names (menus / one-shots)
	for action in ROUTABLE:
		if not InputMap.has_action(action):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton:
				if int((ev as InputEventJoypadButton).button_index) == int(e.button_index):
					return _html_name(action)
	# Start as accept on title if unmapped
	if e.button_index == JOY_BUTTON_START:
		return "start"
	return ""

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

func _soundgate_blocking() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for n in tree.get_nodes_in_group("sound_gate"):
		if n and n.has_method("is_blocking") and bool(n.is_blocking()):
			return true
	return false

func key_press(k: String) -> void:
	## HTML keyPress(k)
	# Soundgate modal: no start/play/menu keys until dismissed
	if _soundgate_blocking():
		return
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
	# PLAY combat one-shots (bomb/special/swap/cycle/melee/items) are owned by Player
	# via is_action_just_pressed / hold. InputRouter must NOT also fire them — double
	# key_press + Player burn 2 bombs and skip every other weapon. Touch injects
	# InputMap actions only; menu/portal/pause stay here.
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
	## HTML meleeswap — cycle player armed melee; do not reorder arsenal
	var p = _player()
	if p and p.has_method("cycle_melee"):
		p.cycle_melee()
		return
	# Fallback if player missing API
	var ar: Dictionary = ProgressStore.progress.get("arsenal", {})
	var ms: Array = ar.get("m", ["katana"])
	if ms.size() < 2:
		return
	if p and p.get("armed_melee") != null:
		p.armed_melee = (int(p.armed_melee) + 1) % ms.size()
		var mk = str(ms[int(p.armed_melee)])
		var mdef = {}
		for m in DataRegistry.melee:
			if str(m.get("key")) == mk:
				mdef = m
				break
		if AudioBus:
			AudioBus.sfx("item")
		if CombatHelpers:
			CombatHelpers.flash("%s %s" % [mdef.get("icon", "🗡"), mdef.get("name", mk)], 75.0)

func _player() -> Node:
	return get_tree().get_first_node_in_group("player") if get_tree() else null
