extends Node
## HTML lofi YouTube stream bridge (video rPjez8z61rI).
## Web: JavaScriptBridge → YT iframe API (injected in export HTML head).
## Desktop: volume is stored; no stream unless a local file is added later.
## Does NOT iframe the HTML game — music only.

const YT_ID := "rPjez8z61rI"

var enabled: bool = false
var _want_play: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_inject_ready_poll()

func _inject_ready_poll() -> void:
	## Ensure bridge exists even if head_include failed to load yet
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	# no-op poll — API ready callback is in head_include
	pass

func play() -> void:
	## HTML musicPlay / soundgate enable
	enabled = true
	_want_play = true
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	var vol := 1.0
	if AudioBus:
		vol = AudioBus.music_volume
	JavaScriptBridge.eval(
		"try{if(window.kamMusicPlay)window.kamMusicPlay(%s);}catch(e){}" % str(vol),
		true
	)

func pause() -> void:
	## HTML musicPause / mute gate
	_want_play = false
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("try{if(window.kamMusicPause)window.kamMusicPause();}catch(e){}", true)

func set_volume(v: float) -> void:
	## 0..1 → YT 0..100
	var vv := clampf(v, 0.0, 1.0)
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval(
		"try{if(window.kamMusicVol)window.kamMusicVol(%s);}catch(e){}" % str(vv),
		true
	)

func is_web_music() -> bool:
	return OS.has_feature("web")
