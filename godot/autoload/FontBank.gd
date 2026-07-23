extends Node
## Project fonts matching HTML canvas text — Noto Sans + Noto Color Emoji (no ThemeDB fallback).
## HTML uses system "Trebuchet MS" / monospace; we ship Noto for cross-platform glyph coverage
## including the same emoji codepoints used as weapon/special/emblem icons in public/index.html.

var ui: Font
var ui_bold: Font
var mono: Font

func _ready() -> void:
	ui = _build_font("res://assets/fonts/NotoSans-Regular.ttf", true)
	ui_bold = _build_font("res://assets/fonts/NotoSans-Bold.ttf", true)
	if ui_bold == null:
		ui_bold = ui
	# monospaced HUD numbers — DejaVu Mono if present, else Noto Sans
	mono = _build_font("res://assets/fonts/DejaVuSans.ttf", true)
	if mono == null:
		mono = ui
	if ui == null:
		push_error("[FontBank] FATAL: no UI font at res://assets/fonts/ — public emoji/icons will not render 1:1")
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
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(abs_path):
		push_warning("[FontBank] missing font file %s" % path)
		return null
	var f := FontFile.new()
	var try_path := path if FileAccess.file_exists(path) else abs_path
	var err := f.load_dynamic_font(try_path)
	if err != OK:
		# Some exports only resolve via ResourceLoader after import
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is FontFile:
				return res as FontFile
		push_warning("[FontBank] load_dynamic_font failed %s err=%s" % [path, err])
		return null
	return f

func font_for(css: String) -> Font:
	## Pick bold / mono / regular from CSS font string like HTML ctx.font
	var s := str(css).to_lower()
	if "mono" in s:
		return mono if mono else ui
	if "bold" in s or "900" in s or "800" in s or "700" in s:
		return ui_bold if ui_bold else ui
	return ui

func default_font() -> Font:
	return ui if ui else ThemeDB.fallback_font
