extends Node
## Loads every public/ asset with the same keys as HTML IMG{}.
## Animated GIFs: full frame sequences from gif_frames/ (ffmpeg extract of source GIFs).

var IMG: Dictionary = {}           # key -> Texture2D (static) OR current anim frame
var ANIM: Dictionary = {}          # key -> { frames: Array[Texture2D], fps: float, loop: bool }

## Exact mapping from HTML load()
const STATIC_MAP := {
	"peephole": "peephole.png",
	"portrait": "portrait.webp",
	"maid": "maid.png",
	"clear0": "clear-0.png",
	"clear1": "clear-1.png",
	"clear2": "clear-2.png",
	"clear3": "clear-3.png",
	"clear4": "clear-4.png",
	"clear5": "clear-5.png",
	"mumina": "mumina.png",
	"lily": "lily.png",
	"winimg": "win.jpg",
	"honeybadger": "honeybadger.png",
	"campfire": "campfire.jpg",
	"og": "og.png",
	"share_win": "share-win.png",
	"share_over": "share-over.png",
	"favicon": "favicon.png",
	"favicon32": "favicon-32.png",
	"apple": "apple-touch-icon.png",
}

## GIF keys used as HTML <img> / drawImage animated sources
const GIF_KEYS := ["confused", "talk", "leek"]

func _ready() -> void:
	_load_all()

func _process(_delta: float) -> void:
	# Keep IMG[key] pointing at the current animation frame (browser GIF behavior)
	for key in ANIM.keys():
		var a: Dictionary = ANIM[key]
		var frames: Array = a.frames
		if frames.is_empty():
			continue
		var fps: float = float(a.fps)
		var idx := int(floor(Time.get_ticks_msec() / 1000.0 * fps)) % frames.size()
		IMG[key] = frames[idx]

func _load_all() -> void:
	IMG.clear()
	ANIM.clear()
	var missing: Array = []

	for key in STATIC_MAP.keys():
		var path := "res://assets/textures/" + str(STATIC_MAP[key])
		var tex := _load_texture(path)
		if tex:
			IMG[key] = tex
		else:
			missing.append(path)

	# Animated GIFs from full frame extracts
	var meta_path := "res://assets/textures/gif_frames/meta.json"
	if FileAccess.file_exists(meta_path):
		var f := FileAccess.open(meta_path, FileAccess.READ)
		var meta: Dictionary = JSON.parse_string(f.get_as_text())
		# HTML id="leek" uses leekspin.gif — map leek -> leekspin
		var alias := {"leek": "leekspin", "confused": "confused", "talk": "talk"}
		for html_key in alias.keys():
			var meta_key: String = alias[html_key]
			if not meta.has(meta_key):
				missing.append("gif meta missing: " + meta_key)
				continue
			var entry: Dictionary = meta[meta_key]
			var frames: Array = []
			for fp in entry.get("frames", []):
				var t := _load_texture(str(fp))
				if t:
					frames.append(t)
			if frames.is_empty():
				missing.append("gif frames empty: " + meta_key)
				continue
			ANIM[html_key] = {
				"frames": frames,
				"fps": float(entry.get("fps", 12.0)),
				"loop": bool(entry.get("loop", true)),
				"src": str(entry.get("src", "")),
			}
			IMG[html_key] = frames[0]
			# Also expose under meta name for code that uses leekspin
			if html_key != meta_key:
				ANIM[meta_key] = ANIM[html_key]
				IMG[meta_key] = frames[0]
	else:
		missing.append(meta_path)

	if missing.size():
		push_error("[AssetBank] FAILED to load %d assets: %s" % [missing.size(), str(missing)])
	else:
		print("[AssetBank] loaded static=%d anim=%d (full GIF sequences)" % [
			STATIC_MAP.size(), ANIM.size()
		])

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	# Raw image load (PNG/JPG/WebP)
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(abs_path):
		return null
	var img := Image.new()
	var err := img.load(abs_path if FileAccess.file_exists(abs_path) else path)
	if err != OK:
		# Try relative from project
		err = img.load(path.replace("res://", ""))
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)

func get_tex(key: String) -> Texture2D:
	return IMG.get(key, null) as Texture2D

func get_anim_frames(key: String) -> Array:
	if ANIM.has(key):
		return ANIM[key].frames
	return []

func ok(key: String) -> bool:
	## HTML imgOK(i) — texture present and non-null
	return IMG.has(key) and IMG[key] != null

func html_load_keys() -> Array:
	return [
		"peephole", "portrait", "confused", "maid",
		"clear0", "clear1", "clear2", "clear3", "clear4", "clear5",
		"mumina", "lily", "winimg", "honeybadger",
	]
