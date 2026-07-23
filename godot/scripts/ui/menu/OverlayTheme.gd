extends RefCounted
## Shared StyleBox / colors for HTML #pausescreen / #settings / .set-card chrome.

const PINK := Color(1.0, 0.357, 0.553)  # #ff5b8d
const PINK_DEEP := Color(0.878, 0.141, 0.416)  # #e0246a
const VIOLET := Color(0.690, 0.627, 0.847)  # #b0a0d8
const TITLE_SET := Color(0.902, 0.847, 1.0)  # #e6d8ff
const SUB := Color(0.784, 0.737, 0.878)  # #c8bce0
const SEC := Color(0.604, 0.545, 0.659)  # #9a8ba8
const LABEL := Color(0.910, 0.878, 0.965)  # #e8e0f6
const HINT := Color(0.604, 0.545, 0.659)
const CARD_TOP := Color(0.133, 0.102, 0.204)  # #221a34
const CARD_BOT := Color(0.165, 0.063, 0.188)  # #2a1030
const PAUSE_TOP := Color(0.141, 0.102, 0.204)  # #241a34
const TEXT_W := Color(1, 1, 1)
const MUTED_BTN := Color(0.910, 0.812, 0.878)  # #e8cfe0

static func card_style(border: Color, radius: float = 18.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BOT
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_corner_radius_all(int(radius))
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(border.r, border.g, border.b, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2.ZERO
	return sb

static func btn_primary() -> StyleBoxFlat:
	## HTML #ps-resume pink gradient (flat mid)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PINK
	sb.set_corner_radius_all(14)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.shadow_color = Color(1.0, 0.24, 0.47, 0.45)
	sb.shadow_size = 10
	return sb

static func btn_ghost(border_a: float = 0.2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, border_a)
	sb.set_corner_radius_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static func btn_help() -> StyleBoxFlat:
	## HTML #set-help amber-tinted
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.824, 0.471, 0.12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.824, 0.471, 0.4)
	sb.set_corner_radius_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static func slider_grabber() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PINK
	sb.set_corner_radius_all(8)
	sb.set_expand_margin_all(4)
	return sb

static func slider_area() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func slider_fill() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PINK
	sb.set_corner_radius_all(4)
	return sb

static func style_slider(s: HSlider) -> void:
	if s == null:
		return
	s.add_theme_stylebox_override("slider", slider_area())
	s.add_theme_stylebox_override("grabber_area", slider_fill())
	s.add_theme_stylebox_override("grabber_area_highlight", slider_fill())
	var g := slider_grabber()
	s.add_theme_stylebox_override("grabber", g)
	s.add_theme_stylebox_override("grabber_highlight", g)
	s.custom_minimum_size.y = 18

static func style_button(b: Button, kind: String = "ghost") -> void:
	if b == null:
		return
	var normal: StyleBoxFlat
	match kind:
		"primary":
			normal = btn_primary()
		"help":
			normal = btn_help()
		_:
			normal = btn_ghost()
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(
		minf(1.0, normal.bg_color.r * 1.12),
		minf(1.0, normal.bg_color.g * 1.12),
		minf(1.0, normal.bg_color.b * 1.12),
		minf(1.0, normal.bg_color.a + 0.08)
	)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", normal)
	if kind == "primary":
		b.add_theme_color_override("font_color", TEXT_W)
		b.add_theme_color_override("font_hover_color", TEXT_W)
		b.add_theme_color_override("font_pressed_color", TEXT_W)
	elif kind == "help":
		b.add_theme_color_override("font_color", Color(1.0, 0.878, 0.541))
	else:
		b.add_theme_color_override("font_color", MUTED_BTN)
	b.add_theme_font_size_override("font_size", 14)

static func style_sec(lab: Label) -> void:
	if lab == null:
		return
	lab.add_theme_color_override("font_color", SEC)
	lab.add_theme_font_size_override("font_size", 10)

static func style_label(lab: Label) -> void:
	if lab == null:
		return
	lab.add_theme_color_override("font_color", LABEL)
	lab.add_theme_font_size_override("font_size", 13)

static func apply_pause_card(panel: PanelContainer, dim: ColorRect) -> void:
	if dim:
		dim.color = Color(6.0 / 255.0, 4.0 / 255.0, 10.0 / 255.0, 0.72)
	if panel:
		panel.add_theme_stylebox_override("panel", card_style(PINK, 18))
		panel.custom_minimum_size = Vector2(360, 0)

static func apply_settings_card(panel: PanelContainer, dim: ColorRect) -> void:
	if dim:
		dim.color = Color(0.05, 0.03, 0.1, 0.94)
	if panel:
		panel.add_theme_stylebox_override("panel", card_style(VIOLET, 18))
		panel.custom_minimum_size = Vector2(400, 0)
