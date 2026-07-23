extends Node
## Project fonts matching HTML canvas text exactly.
## HTML uses "Trebuchet MS" for UI titles/buttons/dialog; monospace for score/HUD numbers.
## Ship real Trebuchet MS (msttcorefonts) — no silent Noto substitution for Trebuchet requests.

var ui: Font          # Trebuchet MS regular
var ui_bold: Font     # Trebuchet MS Bold
var mono: Font        # DejaVu / mono for score numbers
var serif: Font       # optional serif for charm hearts etc.
var noto_ui: Font     # Noto fallback for missing glyphs only
var noto_bold: Font

func _ready() -> void:
	ui = _build_font("res://assets/fonts/TrebuchetMS.ttf", true)
	if ui == null:
		ui = _build_font("res://assets/fonts/trebuc.ttf", true)
	ui_bold = _build_font("res://assets/fonts/TrebuchetMS-Bold.ttf", true)
	if ui_bold == null:
		ui_bold = _build_font("res://assets/fonts/Trebucbd.ttf", true)
	if ui_bold == null:
		ui_bold = ui
	mono = _build_font("res://assets/fonts/DejaVuSans.ttf", true)
	if mono == null:
		mono = ui
	noto_ui = _build_font("res://assets/fonts/NotoSans-Regular.ttf", true)
	noto_bold = _build_font("res://assets/fonts/NotoSans-Bold.ttf", true)
	serif = mono
	if ui == null:
		# Last resort so WASM never draws with null font
		ui = noto_ui if noto_ui else ThemeDB.fallback_font
		ui_bold = noto_bold if noto_bold else ui
		mono = ui
		push_error("[FontBank] FATAL: Trebuchet MS missing — using Noto (export missing fonts?)")
	else:
		print("[FontBank] Trebuchet MS ready (emoji fallbacks=", ui.fallbacks.size() if ui else 0, ")")

func _build_font(path: String, with_emoji: bool) -> Font:
	var f := _load_font_file(path)
	if f == null:
		return null
	if with_emoji:
		var em := _load_font_file("res://assets/fonts/NotoColorEmoji.ttf")
		if em != null:
			var fb: Array[Font] = []
			fb.append(em)
			# Also chain Noto for rare glyphs if this is Trebuchet
			if "Trebuchet" in path or "trebuc" in path.to_lower():
				var ns := _load_font_file("res://assets/fonts/NotoSans-Regular.ttf")
				if ns != null:
					fb.append(ns)
			f.fallbacks = fb
	return f

func _load_font_file(path: String) -> FontFile:
	## Prefer ResourceLoader (works on Web export / PCK). load_dynamic_font needs a real FS path.
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is FontFile:
			return res as FontFile
		if res is Font:
			return null
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
	## Pick bold / mono / serif / Trebuchet from CSS font string like HTML ctx.font
	var s := str(css).to_lower()
	if "mono" in s:
		return mono if mono else (ui if ui else ThemeDB.fallback_font)
	if "serif" in s and "sans" not in s:
		return serif if serif else (ui if ui else ThemeDB.fallback_font)
	# Explicit Trebuchet / UI titles
	if "trebuchet" in s or "900" in s or "800" in s or "bold" in s or "700" in s:
		return ui_bold if ui_bold else (ui if ui else ThemeDB.fallback_font)
	return ui if ui else ThemeDB.fallback_font

func default_font() -> Font:
	return ui if ui else ThemeDB.fallback_font

func has_trebuchet() -> bool:
	return ui != null and (ResourceLoader.exists("res://assets/fonts/TrebuchetMS.ttf") \
		or ResourceLoader.exists("res://assets/fonts/trebuc.ttf") \
		or FileAccess.file_exists("res://assets/fonts/TrebuchetMS.ttf") \
		or FileAccess.file_exists("res://assets/fonts/trebuc.ttf"))
