extends Node
## godot-platform-web: block browser context menu + arrow/space scroll on web export.
## No game state ownership — infrastructure only.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("""
		(function(){
			if (window.__kamInputGuard) return;
			window.__kamInputGuard = true;
			window.addEventListener('contextmenu', function(e){ e.preventDefault(); }, {passive:false});
			window.addEventListener('keydown', function(e){
				// space + arrows — prevent page scroll when game focused
				if ([32,37,38,39,40].indexOf(e.keyCode) > -1) {
					var t = e.target && e.target.tagName;
					if (t === 'INPUT' || t === 'TEXTAREA') return;
					e.preventDefault();
				}
			}, {passive:false});
		})();
	""", true)
