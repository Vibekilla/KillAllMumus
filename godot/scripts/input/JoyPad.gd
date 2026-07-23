extends Node
## HTML virtual joystick + touch chrome (joy*, manageTouchUI, pdown/pmove/pup).
## DOM overlay is gone in Godot; we keep the same state machine for analog stick.

signal joy_changed(active: bool, vx: float, vy: float)

const JOY_R := 48.0

var active: bool = false
var joy_id = null
var cx: float = 0.0
var cy: float = 0.0
var vx: float = 0.0
var vy: float = 0.0
var home := Vector2(90, 430)
var touch_ui_on: bool = false
var pointer_down: bool = false
var pointer := Vector2.ZERO
var mouse := Vector2.ZERO
var mouse_move_t: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	joy_show_home()

func _process(delta: float) -> void:
	if mouse_move_t > 0.0:
		mouse_move_t = maxf(0.0, mouse_move_t - delta * 60.0)
	manage_touch_ui()

func joy_reset() -> void:
	## HTML joyReset
	active = false
	joy_id = null
	vx = 0.0
	vy = 0.0
	joy_changed.emit(false, 0.0, 0.0)
	if P2Meta:
		P2Meta.joy_reset()

func joy_home_pos() -> Vector2:
	## HTML joyHomePos — bottom-left fixed seat
	var vh := Config.H
	return Vector2(maxi(58, 72), vh - 106.0)

func joy_show_home() -> void:
	## HTML joyShowHome
	home = joy_home_pos()
	cx = home.x
	cy = home.y

func joy_start(screen_pos: Vector2, id = 0) -> void:
	## HTML joyStart
	active = true
	joy_id = id
	cx = home.x
	cy = home.y
	joy_apply(screen_pos)

func joy_move(screen_pos: Vector2, id = null) -> void:
	## HTML joyMove
	if not active:
		return
	if id != null and joy_id != null and id != joy_id:
		return
	joy_apply(screen_pos)

func joy_end(id = null) -> void:
	## HTML joyEnd
	if not active:
		return
	if id != null and joy_id != null and id != joy_id:
		return
	joy_reset()

func joy_apply(screen_pos: Vector2) -> void:
	## HTML joyApply
	var dx := screen_pos.x - cx
	var dy := screen_pos.y - cy
	var d := sqrt(dx * dx + dy * dy)
	if d > JOY_R:
		dx *= JOY_R / d
		dy *= JOY_R / d
	vx = dx / JOY_R
	vy = dy / JOY_R
	joy_changed.emit(true, vx, vy)
	if P2Meta:
		P2Meta.joy = {"active": true, "vx": vx, "vy": vy}

func manage_touch_ui() -> void:
	## HTML manageTouchUI — show virtual stick only in play on touch (or ui=touch override)
	var want := false
	var ov = read_ui_override()
	if ov == true:
		want = true
	elif ov == false:
		want = false
	else:
		want = DisplayServer.is_touchscreen_available()
	var show := want and GameState.state == GameState.State.PLAY
	if touch_ui_on != show:
		touch_ui_on = show
		if show:
			joy_show_home()
		else:
			joy_reset()
	# HTML: reset stick while paused
	if GameState.state == GameState.State.PAUSED and active:
		joy_reset()

func update_touch_buttons() -> void:
	## HTML updateTouchButtons — special ready badge (canvas HUD already shows %)
	pass

func read_ui_override() -> Variant:
	## HTML readUiOverride — null | true(touch) | false(desktop)
	var st: Dictionary = ProgressStore.progress.get("settings", {})
	var ui = st.get("ui", null)
	if ui == "touch":
		return true
	if ui == "desktop":
		return false
	return null

func close_gate(go_fs: bool = false) -> void:
	## HTML closeGate — sound gate dismissed; optional fullscreen
	if go_fs and Config.has_method("go_fullscreen_mobile"):
		Config.go_fullscreen_mobile()
	elif go_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func pdown(pos: Vector2) -> void:
	## HTML pdown (pointer down on game canvas)
	pointer_down = true
	pointer = pos
	mouse = pos
	mouse_move_t = 45.0

func pmove(pos: Vector2) -> void:
	## HTML pmove
	mouse = pos
	mouse_move_t = 45.0
	if pointer_down:
		pointer = pos

func pup() -> void:
	## HTML pup
	pointer_down = false

func in_btn(p: Vector2, b) -> bool:
	## HTML inBtn
	return MenuHelpers.in_btn(p, b) if MenuHelpers else false

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")
