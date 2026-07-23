extends Node
## Global configuration — layout matches HTML applyLayout landscape / portrait.

const VERSION := "2.0.0-godot"
const GAME_TITLE := "Bobina: Kill All Mumus!!"

## When exported to web under killallmumus.com, same-origin API works with "".
var api_base_url: String = ""

# HTML: cv.width=960; cv.height=540; (mutated by apply_layout for portrait)
var W: float = 960.0
var H: float = 540.0
var VIEWPORT: Vector2 = Vector2(960, 540)

# HTML landscape: PF={x:48, y:14, w:512, h:516};
const PLAYFIELD := Rect2(48, 14, 512, 516)
# HTML: PANEL={x:PF.x+PF.w+16, y:14, w:960-(PF.x+PF.w+16)-14, h:516};
const PANEL := Rect2(576, 14, 370, 516)
# HTML: COLLECT_LINE=PF.y+96 (updated in apply_layout)
var COLLECT_LINE: float = 110.0

# Portrait layout (applyLayout(true))
const PORTRAIT_W := 540.0
const PORTRAIT_PF := Rect2(14, 84, 512, 516)

var display_scale: float = 1.0
var refresh_rate: int = 60
var debug_layer: bool = false
var portrait: bool = false
## Cached playfield/panel for current layout (always use these in draw/gameplay)
var PF: Rect2 = PLAYFIELD
var PANEL_R: Rect2 = PANEL

# HTML DEFAULT_BINDS / MOUSE prefs
var mouse_follow: float = 0.55
var mouse_speed: float = 1.12

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		api_base_url = ""
	elif OS.get_environment("KAM_API_BASE") != "":
		api_base_url = OS.get_environment("KAM_API_BASE")
	else:
		api_base_url = "https://killallmumus.com"
	apply_layout(false)
	get_tree().root.size_changed.connect(_on_root_size_changed)
	_on_root_size_changed()

func _on_root_size_changed() -> void:
	## HTML resize → applyLayout based on phone orientation
	var ws := DisplayServer.window_get_size()
	if ws.x <= 0 or ws.y <= 0:
		return
	# Tall window / phone portrait (or forced ui=touch on tall aspect)
	var want_p := float(ws.y) / float(ws.x) > 1.12
	if want_p != portrait:
		apply_layout(want_p)

func apply_layout(p: bool) -> void:
	## HTML applyLayout(p)
	portrait = p
	if p:
		# Portrait: 540-wide canvas, tall height from window aspect (clamped like HTML)
		var ws := DisplayServer.window_get_size()
		var aspect := 1.6
		if ws.x > 0:
			aspect = clampf(float(ws.y) / float(ws.x), 1.15, 2.35)
		W = PORTRAIT_W
		H = roundf(PORTRAIT_W * aspect)
		PF = PORTRAIT_PF
		PANEL_R = Rect2(8, PF.position.y + PF.size.y + 10, 524, maxf(120.0, H - (PF.position.y + PF.size.y + 10) - 8))
		COLLECT_LINE = PF.position.y + 96.0
		# Resize logical viewport so draw coords match HTML portrait canvas
		if get_tree() and get_tree().root:
			get_tree().root.content_scale_size = Vector2i(int(W), int(H))
	else:
		W = 960.0
		H = 540.0
		PF = PLAYFIELD
		PANEL_R = PANEL
		COLLECT_LINE = PF.position.y + 96.0
		if get_tree() and get_tree().root:
			get_tree().root.content_scale_size = Vector2i(960, 540)
	VIEWPORT = Vector2(W, H)

func playfield() -> Rect2:
	return PF

func panel() -> Rect2:
	return PANEL_R

func go_fullscreen_mobile() -> void:
	## HTML goFullscreenMobile
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
