extends RefCounted
## Shared StyleBox / colors for HTML #pausescreen / #settings / .set-card chrome.

const PINK := Color(1.0, 0.357, 0.553)  # #ff5b8d
const PINK_DEEP := Color(0.878, 0.141, 0.416)  # #e0246a
const VIOLET := Color(0.690, 0.627, 0.847)  # #b0a0d8
const TITLE_SET := Color(0.902, 0.847, 1.0)  # #e6d8ff
const SUB := Color(0.784, 0.737, 0.878)  # #c8bce0
const SEC := Color(0.604, 0.545, 0.659)  # #9a8ba8
const LABEL := Color(0.910, 0.878, 0.965)  # #e8e0f6
const GOLD := Color(1.0, 0.824, 0.478)  # #ffd27a  HTML .set-row label span
const HINT := Color(0.604, 0.545, 0.659)
const CARD_TOP := Color(0.133, 0.102, 0.204)  # #221a34
const CARD_BOT := Color(0.165, 0.063, 0.188)  # #2a1030
const PAUSE_TOP := Color(0.141, 0.102, 0.204)  # #241a34
const TEXT_W := Color(1, 1, 1)
const MUTED_BTN := Color(0.910, 0.812, 0.878)  # #e8cfe0
const CYAN_TXT := Color(0.749, 0.902, 1.0)  # #bfe6ff
const RESET_TXT := Color(1.0, 0.761, 0.761)  # #ffc2c2
const DONE_TXT := Color(1.0, 0.839, 0.918)  # #ffd6ea

const DIM_SHADER := preload("res://shaders/overlay_dim.gdshader")

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

static func btn_cyan() -> StyleBoxFlat:
	## HTML #set-display / #set-keybinds / #ps-display / #ps-keybinds
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(143.0 / 255.0, 208.0 / 255.0, 1.0, 0.12)
	sb.set_border_width_all(1)
	sb.border_color = Color(143.0 / 255.0, 208.0 / 255.0, 1.0, 0.4)
	sb.set_corner_radius_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static func btn_reset() -> StyleBoxFlat:
	## HTML #set-resetinv
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 90.0 / 255.0, 90.0 / 255.0, 0.12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 120.0 / 255.0, 120.0 / 255.0, 0.45)
	sb.set_corner_radius_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static func btn_done() -> StyleBoxFlat:
	## HTML #set-close
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 120.0 / 255.0, 190.0 / 255.0, 0.14)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_corner_radius_all(12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static func btn_toggle(on: bool) -> StyleBoxFlat:
	## HTML .set-toggle / .set-toggle.on
	var sb := StyleBoxFlat.new()
	if on:
		sb.bg_color = Color(0.494, 0.851, 0.341, 0.18)
		sb.border_color = Color(0.494, 0.851, 0.341)
	else:
		sb.bg_color = Color(1, 1, 1, 0.05)
		sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
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

static var _grabber_tex: Texture2D

static func grabber_texture() -> Texture2D:
	## Godot 4 HSlider grabber is a Texture2D, not a StyleBox (HTML range thumb is #ff5b8d).
	if _grabber_tex != null:
		return _grabber_tex
	var s := 18
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (s - 1) * 0.5
	var r := 6.5
	for y in range(s):
		for x in range(s):
			var d := Vector2(float(x), float(y)).distance_to(Vector2(cx, cx))
			if d <= r + 0.6:
				var a := clampf(r + 0.6 - d, 0.0, 1.0)
				var col := PINK
				if d <= r - 1.2:
					col = Color(1.0, 0.48, 0.64)  # inner highlight like HTML thumb
				col.a = a
				img.set_pixel(x, y, col)
	_grabber_tex = ImageTexture.create_from_image(img)
	return _grabber_tex

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
	var gt := grabber_texture()
	s.add_theme_icon_override("grabber", gt)
	s.add_theme_icon_override("grabber_highlight", gt)
	s.add_theme_icon_override("grabber_disabled", gt)
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
		"cyan":
			normal = btn_cyan()
		"reset":
			normal = btn_reset()
		"done":
			normal = btn_done()
		"toggle_on":
			normal = btn_toggle(true)
		"toggle_off":
			normal = btn_toggle(false)
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
	var fc := MUTED_BTN
	match kind:
		"primary":
			fc = TEXT_W
		"help":
			fc = Color(1.0, 0.878, 0.541)
		"cyan":
			fc = CYAN_TXT
		"reset":
			fc = RESET_TXT
		"done":
			fc = DONE_TXT
		"toggle_on":
			fc = Color(0.776, 0.949, 0.682)
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_hover_color", fc)
	b.add_theme_color_override("font_pressed_color", fc)
	b.add_theme_font_size_override("font_size", 14)
	if kind != "primary":
		b.custom_minimum_size.y = 40

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

static func vbox_child(n: Node) -> Node:
	## After split_value_row, the VBox child is the HBox wrapper, not the Label.
	if n == null:
		return null
	var p := n.get_parent()
	if p is HBoxContainer:
		return p
	return n

static func hide_row(n: Node) -> void:
	var c := vbox_child(n)
	if c is CanvasItem:
		(c as CanvasItem).visible = false

static func split_value_row(lab: Label) -> Label:
	## HTML `.set-row label { display:flex; justify-content:space-between }` + gold span.
	## Returns the right-hand value Label (creates an HBox wrapper once).
	if lab == null:
		return null
	if lab.has_meta("value_lab"):
		var existing = lab.get_meta("value_lab")
		if existing is Label and is_instance_valid(existing):
			return existing as Label
	var parent := lab.get_parent()
	if parent == null:
		return null
	var idx := lab.get_index()
	var row := HBoxContainer.new()
	row.name = str(lab.name) + "Row"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	parent.move_child(row, idx)
	lab.reparent(row)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_label(lab)
	var val := Label.new()
	val.name = str(lab.name) + "Val"
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_color_override("font_color", GOLD)
	val.add_theme_font_size_override("font_size", 13)
	row.add_child(val)
	row.visible = lab.visible
	lab.set_meta("value_lab", val)
	return val

static func set_row_value(lab: Label, left: String, right: String) -> void:
	if lab == null:
		return
	lab.text = left
	var val := split_value_row(lab)
	if val:
		val.text = right

static func apply_dim(dim: ColorRect, kind: String) -> void:
	## HTML #settings radial+blur(4) · #pausescreen flat rgba(6,4,10,0.72)+blur(3)
	if dim == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = DIM_SHADER
	if kind == "pause":
		var veil := Color(6.0 / 255.0, 4.0 / 255.0, 10.0 / 255.0, 0.72)
		mat.set_shader_parameter("inner", veil)
		mat.set_shader_parameter("outer", Color(6.0 / 255.0, 4.0 / 255.0, 10.0 / 255.0, 0.82))
		mat.set_shader_parameter("radial", 0.0)
		mat.set_shader_parameter("blur_px", 3.0)
		dim.color = veil
	else:
		mat.set_shader_parameter("inner", Color(30.0 / 255.0, 24.0 / 255.0, 54.0 / 255.0, 0.94))
		mat.set_shader_parameter("outer", Color(6.0 / 255.0, 4.0 / 255.0, 12.0 / 255.0, 0.97))
		mat.set_shader_parameter("center", Vector2(0.5, 0.4))
		mat.set_shader_parameter("radius", Vector2(0.73, 0.96))
		mat.set_shader_parameter("radial", 1.0)
		mat.set_shader_parameter("blur_px", 4.0)
		dim.color = Color(0.05, 0.03, 0.1, 0.94)
	dim.material = mat
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

static func apply_pause_card(panel: PanelContainer, dim: ColorRect) -> void:
	apply_dim(dim, "pause")
	if panel:
		var sb := card_style(PINK, 18)
		sb.bg_color = PAUSE_TOP
		panel.add_theme_stylebox_override("panel", sb)
		panel.custom_minimum_size = Vector2(380, 0)

static func apply_settings_card(panel: PanelContainer, dim: ColorRect) -> void:
	apply_dim(dim, "settings")
	if panel:
		var sb := card_style(VIOLET, 18)
		sb.bg_color = CARD_TOP
		panel.add_theme_stylebox_override("panel", sb)
		panel.custom_minimum_size = Vector2(440, 0)
