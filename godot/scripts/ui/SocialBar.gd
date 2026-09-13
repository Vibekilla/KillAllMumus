extends MarginContainer
## HTML #social — real Control chips (DOM overlay), not canvas roundRects.
## Desktop title only; touch hides the strip (HTML body.touch #social { display:none }).

const LINKS := [
	{"url": "https://bobina.moe", "label": "🌐 bobina.moe"},
	{"url": "https://x.com/itsvibekilla", "label": "𝕏 Vibekilla"},
	{"url": "https://x.com/bobina_council", "label": "𝕏 Bobina Council"},
	{"url": "https://x.com/bobocouncil", "label": "𝕏 Bobo Council"},
	{"url": "https://x.com/emblemvault", "label": "𝕏 Emblem Vault"},
	{"url": "https://x.com/JungleBayAC", "label": "𝕏 Jungle Bay"},
	{"url": "https://x.com/monke_meme_eth", "label": "𝕏 Monke"},
	{"url": "https://x.com/SKOL_ERC20", "label": "𝕏 SKOL"},
	{"url": "https://x.com/HBDCERC20", "label": "𝕏 Honey Badger"},
	{"url": "https://x.com/krakenfx", "label": "𝕏 Kraken"},
	{"url": "https://x.com/ourbit", "label": "𝕏 Ourbit"},
	{"url": "https://picklecharts.com", "label": "🥒 PickleCharts"},
]

const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var _flow: HFlowContainer

func _ready() -> void:
	name = "SocialBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# HTML #social { bottom:6px; padding:0 10px; gap:7px; flex-wrap }
	offset_left = 10.0
	offset_right = -10.0
	offset_bottom = -6.0
	offset_top = -78.0
	_flow = HFlowContainer.new()
	_flow.name = "Flow"
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("h_separation", 7)
	_flow.add_theme_constant_override("v_separation", 7)
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_flow)
	for s in LINKS:
		_flow.add_child(_make_chip(str(s["label"]), str(s["url"])))

func _make_chip(label: String, url: String) -> Button:
	var b := Button.new()
	b.text = label
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 11)
	if FontBank and FontBank.ui:
		b.add_theme_font_override("font", FontBank.ui)
	b.add_theme_color_override("font_color", Color(200.0 / 255.0, 176.0 / 255.0, 208.0 / 255.0))  # #c8b0d0
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_stylebox_override("normal", _chip_sb(false))
	b.add_theme_stylebox_override("hover", _chip_sb(true))
	b.add_theme_stylebox_override("pressed", _chip_sb(true))
	b.add_theme_stylebox_override("focus", _chip_sb(false))
	b.pressed.connect(func():
		MenuHelpers.open_url(url)
		if AudioBus:
			AudioBus.sfx("item")
	)
	return b

func _chip_sb(hover: bool) -> StyleBoxFlat:
	## HTML #social a  padding:5px 9px; radius:8px
	var sb := StyleBoxFlat.new()
	if hover:
		sb.bg_color = Color(60.0 / 255.0, 26.0 / 255.0, 60.0 / 255.0, 0.85)
		sb.border_color = Color(1.0, 122.0 / 255.0, 181.0 / 255.0)  # #ff7ab5
	else:
		sb.bg_color = Color(28.0 / 255.0, 16.0 / 255.0, 38.0 / 255.0, 0.72)
		sb.border_color = Color(1.0, 120.0 / 255.0, 190.0 / 255.0, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb
