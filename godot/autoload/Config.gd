extends Node
## Global configuration — API base, display defaults, version.

const VERSION := "2.0.0-godot"
const GAME_TITLE := "Bobina: Kill All Mumus!!"

## When exported to web under killallmumus.com, same-origin API works with "".
## For local desktop testing against the live server, set API_BASE_URL.
var api_base_url: String = ""

const PLAYFIELD := Rect2(48, 14, 512, 516)
const VIEWPORT := Vector2(960, 540)

var display_scale: float = 1.0
var refresh_rate: int = 60
var debug_layer: bool = false

func _ready() -> void:
	# Desktop export may need absolute API host
	if OS.has_feature("web"):
		api_base_url = ""
	elif OS.get_environment("KAM_API_BASE") != "":
		api_base_url = OS.get_environment("KAM_API_BASE")
	else:
		api_base_url = "https://killallmumus.com"
