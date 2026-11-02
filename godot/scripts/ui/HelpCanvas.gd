extends Control
## 1:1 HTML help modal (openHelp/closeHelp/buildHelp) as canvas UI.

const HelpData = preload("res://scripts/ui/menu/HelpData.gd")
const MenuHelpers = preload("res://scripts/ui/menu/MenuHelpers.gd")

var ctx: RefCounted
var tick: int = 0
var open: bool = false
var help_tab: String = "controls"
var scroll: float = 0.0
var tab_btns: Array = []  # {id,x,y,w,h}
var close_btn: Dictionary = {}
var body_top: float = 0.0
var body_h: float = 0.0
var _content_h: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 40
	ctx = load("res://scripts/render/CanvasCompat.gd").new()
	ctx.bind(self)
	visible = false
	add_to_group("help_canvas")

func open_help() -> void:
	## HTML openHelp
	open = true
	visible = true
	scroll = 0.0
	if help_tab == "":
		help_tab = "controls"
	queue_redraw()
	if AudioBus:
		AudioBus.sfx("item")

func close_help() -> void:
	## HTML closeHelp
	open = false
	visible = false
	queue_redraw()

func _process(_d: float) -> void:
	if not open:
		return
	tick = SimClock.sim_frame if SimClock else tick + 1
	queue_redraw()

func _draw() -> void:
	if not open or ctx == null:
		return
	ctx.begin_frame()
	var W = Config.W
	var H = Config.H
	# dim
	ctx.fill_style("rgba(8,4,14,0.78)")
	ctx.fill_rect(0, 0, W, H)
	# card
	var cw = mini(720.0, W - 48.0)
	var ch = mini(460.0, H - 40.0)
	var cx = (W - cw) / 2.0
	var cy = (H - ch) / 2.0
	ctx.fill_style("rgba(22,12,32,0.98)")
	ctx.begin_path()
	ctx.round_rect(cx, cy, cw, ch, 14)
	ctx.fill()
	ctx.stroke_style("#ff9ecb")
	ctx.line_width(2)
	ctx.stroke()
	# title
	ctx.text_align("center")
	ctx.fill_style("#ffe08a")
	ctx.font("900 20px Trebuchet MS")
	ctx.fill_text("📖 HOW TO PLAY", W / 2.0, cy + 26)
	ctx.fill_style("#c8bce0")
	ctx.font("12px Trebuchet MS")
	ctx.fill_text("Everything Bobina can do — auto-updates as new gear is added", W / 2.0, cy + 44)
	# tabs
	tab_btns.clear()
	var tabs: Array = HelpData.tabs()
	var tx = cx + 16.0
	var ty = cy + 56.0
	var th = 26.0
	for t in tabs:
		var id = str(t.get("id", ""))
		var label = str(t.get("label", id))
		var tw = maxf(88.0, float(ctx.measure_text(label).get("width", 70)) + 18.0)
		if tx + tw > cx + cw - 16:
			# wrap tabs
			ty += th + 4
			tx = cx + 16.0
		var on = id == help_tab
		ctx.fill_style("#3a2048" if on else "rgba(40,28,55,0.9)")
		ctx.begin_path()
		ctx.round_rect(tx, ty, tw, th, 6)
		ctx.fill()
		if on:
			ctx.stroke_style("#ffd27a")
			ctx.line_width(1.5)
			ctx.stroke()
		ctx.fill_style("#ffe08a" if on else "#c8b0d0")
		ctx.font("bold 11px monospace")
		ctx.text_align("center")
		ctx.fill_text(label, tx + tw / 2.0, ty + 17)
		tab_btns.append({"id": id, "x": tx, "y": ty, "w": tw, "h": th})
		tx += tw + 6
	# body area
	body_top = ty + th + 12
	var close_h = 36.0
	body_h = ch - (body_top - cy) - close_h - 20
	ctx.fill_style("rgba(0,0,0,0.25)")
	ctx.begin_path()
	ctx.round_rect(cx + 14, body_top, cw - 28, body_h, 8)
	ctx.fill()
	# items
	var body: Array = []
	for t2 in tabs:
		if str(t2.get("id")) == help_tab:
			body = t2.get("body", [])
			break
	var iy = body_top + 14 - scroll
	var text_w = cw - 56.0
	var content_h = 14.0
	var y0 = body_top
	var y1 = body_top + body_h
	ctx.text_align("left")
	for it in body:
		if typeof(it) != TYPE_DICTIONARY:
			continue
		var icon = str(it.get("icon", ""))
		var name = str(it.get("name", ""))
		var desc = str(it.get("desc", ""))
		ctx.font("11px monospace")
		var lines = _count_lines(desc, text_w)
		var row = 18.0 + float(lines) * 14.0 + 8.0
		if iy + row >= y0 and iy <= y1:
			var head = name if icon == "" else "%s  %s" % [icon, name]
			if iy + 12 >= y0 and iy + 12 <= y1:
				ctx.fill_style("#ffd27a")
				ctx.font("bold 13px monospace")
				ctx.fill_text(head, cx + 28, iy + 12)
			ctx.fill_style("#d8c8e0")
			ctx.font("11px monospace")
			_wrap(desc, cx + 28, iy + 28, text_w, 14.0, y0, y1)
		iy += row
		content_h += row
	_content_h = content_h
	# close button
	var bx = W / 2.0 - 70
	var by = cy + ch - 42
	close_btn = {"x": bx, "y": by, "w": 140, "h": 30}
	ctx.fill_style("#ff5b8d")
	ctx.begin_path()
	ctx.round_rect(bx, by, 140, 30, 8)
	ctx.fill()
	ctx.fill_style("#fff")
	ctx.font("bold 13px Trebuchet MS")
	ctx.text_align("center")
	ctx.fill_text("Close", W / 2.0, by + 20)
	ctx.text_align("left")

func _count_lines(text: String, max_w: float) -> int:
	if text == "":
		return 0
	var words = text.split(" ")
	var line = ""
	var n = 1
	for w in words:
		var trial = (line + " " + w).strip_edges()
		if float(ctx.measure_text(trial).get("width", 0)) > max_w and line != "":
			n += 1
			line = str(w)
		else:
			line = trial
	return n

func _wrap(text: String, x: float, y: float, max_w: float, line_h: float, y0: float, y1: float) -> void:
	var words = text.split(" ")
	var line = ""
	var ly = y
	for w in words:
		var trial = (line + " " + w).strip_edges()
		var tw = float(ctx.measure_text(trial).get("width", 0))
		if tw > max_w and line != "":
			if ly >= y0 and ly <= y1:
				ctx.fill_text(line, x, ly)
			ly += line_h
			line = str(w)
		else:
			line = trial
	if line != "" and ly >= y0 and ly <= y1:
		ctx.fill_text(line, x, ly)

func _gui_input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			scroll = maxf(0.0, scroll - 28.0)
			queue_redraw()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			scroll = minf(scroll + 28.0, maxf(0.0, _content_h - body_h))
			queue_redraw()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var p = mb.position
			if MenuHelpers.in_btn(p, close_btn):
				close_help()
				accept_event()
				return
			for b in tab_btns:
				if MenuHelpers.in_btn(p, b):
					help_tab = str(b.get("id"))
					scroll = 0.0
					if AudioBus:
						AudioBus.sfx("item")
					queue_redraw()
					accept_event()
					return
			# click dim outside card → close
			var W = Config.W
			var H = Config.H
			var cw = mini(720.0, W - 48.0)
			var ch = mini(460.0, H - 40.0)
			var cx = (W - cw) / 2.0
			var cy = (H - ch) / 2.0
			if p.x < cx or p.x > cx + cw or p.y < cy or p.y > cy + ch:
				close_help()
				accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# HTML #help closes from its button or a click on the dim, not from Escape.
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			close_help()
			get_viewport().set_input_as_handled()
