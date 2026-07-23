extends Node
## Project fonts matching HTML canvas text — Noto Sans + Noto Color Emoji.
## HTML uses system "Trebuchet MS" / monospace; we ship Noto for glyph + emoji coverage.

var ui: Font
var ui_bold: Font
var mono: Font

func _ready() -> void:
	ui = _build_font("res://assets/fonts/NotoSans-Regular.ttf", true)
	ui_bold = _build_font("res://assets/fonts/NotoSans-Bold.ttf", true)
	if ui_bold == null:
		ui_bold = ui
	mono = _build_font("res://assets/fonts/DejaVuSans.ttf", true)
	if mono == null:
		mono = ui
	if ui == null:
		# Last resort so WASM never draws with null font (can OOB / crash tab)
		ui = ThemeDB.fallback_font
		ui_bold = ui
		mono = ui
		push_error("[FontBank] FATAL: no project fonts — using ThemeDB fallback (export missing fonts?)")
	else:
		print("[FontBank] ui font ready (emoji fallbacks=", ui.fallbacks.size() if ui else 0, ")")

func _build_font(path: String, with_emoji: bool) -> Font:
	var f := _load_font_file(path)
	if f == null:
		return null
	if with_emoji:
		var em := _load_font_file("res://assets/fonts/NotoColorEmoji.ttf")
		if em != null:
			var fb: Array[Font] = []
			fb.append(em)
			f.fallbacks = fb
	return f

func _load_font_file(path: String) -> FontFile:
	## Prefer ResourceLoader (works on Web export / PCK). load_dynamic_font needs a real FS path.
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is FontFile:
			return res as FontFile
		if res is Font:
			# Imported as system font wrapper in some setups
			return null
	# Desktop / editor: load raw TTF from disk
	var abs_path := ProjectSettings.globalize_path(path)
	var try_path := ""
	if FileAccess.file_exists(path):
		try_path = path
	elif FileAccess.file_exists(abs_path):
		try_path = abs_path
	if try_path != "":
		var f := FontFile.new()
		var err := f.load_dynamic_font(try_path)
		if err == OK:
			return f
		push_warning("[FontBank] load_dynamic_font failed %s err=%s" % [try_path, err])
	else:
		push_warning("[FontBank] missing font file %s" % path)
	return null

func font_for(css: String) -> Font:
	## Pick bold / mono / regular from CSS font string like HTML ctx.font
	var s := str(css).to_lower()
	if "mono" in s:
		return mono if mono else (ui if ui else ThemeDB.fallback_font)
	if "bold" in s or "900" in s or "800" in s or "700" in s:
		return ui_bold if ui_bold else (ui if ui else ThemeDB.fallback_font)
	return ui if ui else ThemeDB.fallback_font

func default_font() -> Font:
	return ui if ui else ThemeDB.fallback_font
