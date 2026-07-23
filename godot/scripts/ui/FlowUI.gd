extends Control
## Canvas host for INTRO / STAGE_CLEAR / SHOP + field clear-gate overlay during PLAY.

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx: RefCounted
var flow_draw: RefCounted
var tick: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	z_index = 20
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	flow_draw = load("res://scripts/ui/menu/draw_flow.gd").new()
	flow_draw.setup(ctx)
	GameState.state_changed.connect(func(_s): queue_redraw())
	visible = true
	if SimClock and not SimClock.sim_tick.is_connected(_on_sim_tick):
		SimClock.sim_tick.connect(_on_sim_tick)

var _last_tick: int = -1

func _on_sim_tick(dt: float) -> void:
	## Stage flow timers advance on fixed sim steps only.
	if StageFlow:
		StageFlow.tick(dt)

func _process(_delta: float) -> void:
	var nt := SimClock.sim_frame if SimClock else tick + 1
	# show for flow states or when field portal is active
	var show := GameState.state in [
		GameState.State.INTRO, GameState.State.STAGE_CLEAR, GameState.State.SHOP
	] or (GameState.state == GameState.State.PLAY and StageFlow and StageFlow.is_field_cleared())
	# still need clicks when portal active — stay mouse_filter stop only then
	if GameState.state == GameState.State.PLAY and not (StageFlow and StageFlow.is_field_cleared()):
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
	if not show:
		return
	if nt == _last_tick:
		return
	_last_tick = nt
	tick = nt
	queue_redraw()

func _draw() -> void:
	if ctx == null or flow_draw == null:
		return
	ctx.begin_frame()
	flow_draw.set_tick(tick)
	match GameState.state:
		GameState.State.INTRO:
			flow_draw.drawIntro()
		GameState.State.STAGE_CLEAR:
			flow_draw.drawStageClear(StageFlow.clear_info if StageFlow else {})
		GameState.State.SHOP:
			flow_draw.drawShop(
				StageFlow.shop_tab if StageFlow else "w",
				StageFlow.shop_sel if StageFlow else 0,
				StageFlow.shop_msg if StageFlow else "",
				StageFlow.shop_msg_t if StageFlow else 0.0
			)
		GameState.State.PLAY:
			if StageFlow and StageFlow.is_field_cleared():
				flow_draw.drawClearGate(StageFlow.clear_portal, StageFlow.clear_shop, StageFlow.clear_msg_t)
	# dialog overlay on play
	if StageFlow and StageFlow.dialog != null and GameState.state == GameState.State.PLAY:
		flow_draw.drawDialog(StageFlow.dialog)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("shoot") or event.keycode == KEY_ENTER:
			_on_advance()
			accept_event()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(event.position)
		accept_event()

func _on_advance() -> void:
	if not StageFlow:
		return
	match GameState.state:
		GameState.State.INTRO, GameState.State.STAGE_CLEAR:
			StageFlow.advance_screen()
		GameState.State.SHOP:
			StageFlow.leave_shop()
		GameState.State.PLAY:
			if StageFlow.is_field_cleared():
				# shoot near portal advances
				StageFlow.enter_portal()

func _on_click(p: Vector2) -> void:
	if not StageFlow:
		return
	match GameState.state:
		GameState.State.INTRO, GameState.State.STAGE_CLEAR:
			StageFlow.advance_screen()
		GameState.State.SHOP:
			_shop_click(p)
		GameState.State.PLAY:
			if not StageFlow.is_field_cleared():
				return
			if StageFlow.clear_portal and MenuHelpers.in_btn(p, {
				"x": float(StageFlow.clear_portal.x) - 44,
				"y": float(StageFlow.clear_portal.y) - 44,
				"w": 88, "h": 88,
			}):
				StageFlow.enter_portal()
			elif StageFlow.clear_shop and MenuHelpers.in_btn(p, {
				"x": float(StageFlow.clear_shop.x) - 38,
				"y": float(StageFlow.clear_shop.y) - 38,
				"w": 76, "h": 76,
			}):
				StageFlow.enter_shop()

func _shop_click(p: Vector2) -> void:
	var hit := false
	for b in flow_draw.shop_btns:
		if not MenuHelpers.in_btn(p, b):
			continue
		hit = true
		if b.get("tab") != null:
			StageFlow.shop_tab = str(b.tab)
			StageFlow.shop_sel = 0
			if AudioBus:
				AudioBus.sfx("item")
			return
		if b.get("i") != null:
			var i := int(b.i)
			if StageFlow.shop_sel == i:
				_shop_buy()
			else:
				StageFlow.shop_sel = i
				if AudioBus:
					AudioBus.sfx("item")
			return
	if not hit:
		StageFlow.leave_shop()

func _shop_buy() -> void:
	var list: Array = flow_draw._shop_list(StageFlow.shop_tab)
	if StageFlow.shop_sel < 0 or StageFlow.shop_sel >= list.size():
		return
	var it: Dictionary = list[StageFlow.shop_sel]
	var heads := int(ProgressStore.progress.get("heads", 0))
	var cost := int(it.get("cost", 0))
	if str(it.get("kind")) == "consumable":
		if heads < cost:
			StageFlow.shop_msg = "Not enough heads."
			StageFlow.shop_msg_t = 110
			if AudioBus:
				AudioBus.sfx("hit")
			return
		ProgressStore.progress["heads"] = heads - cost
		var consum: Dictionary = ProgressStore.progress.get("consum", {})
		var k := str(it.get("key"))
		consum[k] = int(consum.get(k, 0)) + 1
		ProgressStore.progress["consum"] = consum
		ProgressStore.queue_save()
		StageFlow.shop_msg = "Bought %s  (now ×%d)" % [it.get("name"), consum[k]]
		StageFlow.shop_msg_t = 120
		if AudioBus:
			AudioBus.sfx("extend")
		return
	if bool(it.get("owned", false)):
		StageFlow.shop_msg = "Already in your arsenal."
		StageFlow.shop_msg_t = 90
		if AudioBus:
			AudioBus.sfx("hit")
		return
	if cost <= 0:
		StageFlow.shop_msg = "Earn its Emblem to unlock this one."
		StageFlow.shop_msg_t = 110
		if AudioBus:
			AudioBus.sfx("hit")
		return
	if heads < cost:
		StageFlow.shop_msg = "Not enough heads — go bag more Mumus."
		StageFlow.shop_msg_t = 120
		if AudioBus:
			AudioBus.sfx("hit")
		return
	ProgressStore.progress["heads"] = heads - cost
	var su: Dictionary = ProgressStore.progress.get("shopUnlocks", {})
	var typ := str(it.get("type", StageFlow.shop_tab))
	var key := str(it.get("key"))
	su["%s:%s" % [typ, key]] = true
	ProgressStore.progress["shopUnlocks"] = su
	ProgressStore.queue_save()
	StageFlow.shop_msg = "Unlocked %s — equip it in your Arsenal!" % it.get("name")
	StageFlow.shop_msg_t = 160
	if AudioBus:
		AudioBus.sfx("win")
