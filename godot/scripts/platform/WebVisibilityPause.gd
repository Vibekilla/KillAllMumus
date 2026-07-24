extends Node
## godot-platform-web: pause engine + audio when the browser tab is hidden.
## Owns no game data — only tree pause + MusicBridge / AudioServer mute.

var _js_callback: JavaScriptObject = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	_js_callback = JavaScriptBridge.create_callback(_on_visibility_changed)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	window.kamOnVisibilityChange = _js_callback
	JavaScriptBridge.eval("""
		(function(){
			if (window.__kamVisBound) return;
			window.__kamVisBound = true;
			document.addEventListener('visibilitychange', function(){
				try {
					if (window.kamOnVisibilityChange)
						window.kamOnVisibilityChange(document.hidden);
				} catch (e) {}
			});
		})();
	""", true)

func _on_visibility_changed(args: Array) -> void:
	## JS: kamOnVisibilityChange(document.hidden)
	var is_hidden := false
	if args.size() > 0:
		is_hidden = bool(args[0])
	_apply_hidden(is_hidden)

func _apply_hidden(is_hidden: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if is_hidden:
		# Pause sim + gameplay; Main stays PROCESS_MODE_ALWAYS for input
		var auto := false
		if GameState and GameState.state == GameState.State.PLAY:
			GameState.set_state(GameState.State.PAUSED)
			auto = true
		if auto:
			set_meta("auto_paused", true)
		tree.paused = true
		AudioServer.set_bus_mute(0, true)
		if MusicBridge and MusicBridge.has_method("pause"):
			MusicBridge.pause()
	else:
		tree.paused = false
		AudioServer.set_bus_mute(0, false)
		# Only resume PLAY if we auto-paused (user manual pause stays paused)
		if has_meta("auto_paused") and bool(get_meta("auto_paused")):
			remove_meta("auto_paused")
			if GameState and GameState.state == GameState.State.PAUSED:
				GameState.set_state(GameState.State.PLAY)
			if MusicBridge and MusicBridge.has_method("play"):
				MusicBridge.play()
