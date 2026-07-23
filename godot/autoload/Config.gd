extends Node
## Global configuration — layout matches HTML applyLayout(false) landscape byte-for-byte.

const VERSION := "2.0.0-godot"
const GAME_TITLE := "Bobina: Kill All Mumus!!"

## When exported to web under killallmumus.com, same-origin API works with "".
var api_base_url: String = ""

# HTML: cv.width=960; cv.height=540;
const W := 960.0
const H := 540.0
const VIEWPORT := Vector2(960, 540)

# HTML landscape: PF={x:48, y:14, w:512, h:516};
const PLAYFIELD := Rect2(48, 14, 512, 516)
# HTML: PANEL={x:PF.x+PF.w+16, y:14, w:960-(PF.x+PF.w+16)-14, h:516};
# = {x:576, y:14, w:370, h:516}
const PANEL := Rect2(576, 14, 370, 516)
# HTML: COLLECT_LINE=PF.y+96
const COLLECT_LINE := 110.0

# Portrait layout (applyLayout(true)) — used when phone orientation detected
const PORTRAIT_W := 540.0
const PORTRAIT_PF := Rect2(14, 84, 512, 516)

var display_scale: float = 1.0
var refresh_rate: int = 60
var debug_layer: bool = false
var portrait: bool = false

# HTML DEFAULT_BINDS / MOUSE prefs
var mouse_follow: float = 0.55  # HTML MOUSE.follow default ~0.55–0.8 UI
var mouse_speed: float = 1.12   # HTML MOUSE.speed

func _ready() -> void:
	if OS.has_feature("web"):
		api_base_url = ""
	elif OS.get_environment("KAM_API_BASE") != "":
		api_base_url = OS.get_environment("KAM_API_BASE")
	else:
		api_base_url = "https://killallmumus.com"

func playfield() -> Rect2:
	return PORTRAIT_PF if portrait else PLAYFIELD

func panel() -> Rect2:
	if portrait:
		# HTML portrait: PANEL bottom strip
		var pf := PORTRAIT_PF
		return Rect2(8, pf.position.y + pf.size.y + 10, 524, 200)
	return PANEL

func go_fullscreen_mobile() -> void:
	## HTML goFullscreenMobile
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
