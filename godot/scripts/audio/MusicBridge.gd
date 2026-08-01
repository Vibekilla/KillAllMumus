extends Node
## HTML lofi YouTube stream bridge (video rPjez8z61rI).
## Web: JavaScriptBridge → window.kamMusicPlay (export HTML head + runtime inject fallback).
## Desktop: preference only (no YT embed unless a local stream is added later).
## Does NOT iframe the HTML game — music only.

const YT_ID := "rPjez8z61rI"

## HTML lofiOn — user opted into music at soundgate
var enabled: bool = false
var _want_play: bool = false
var _retry_left: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_ensure_js_bridge()

func _process(_d: float) -> void:
	if _retry_left <= 0:
		return
	_retry_left -= 1
	if _want_play and enabled:
		_js_play_once()
	if _retry_left <= 0:
		set_process(false)

func play() -> void:
	## HTML musicPlay / soundgate enable (must run from user gesture on web)
	enabled = true
	_want_play = true
	if not OS.has_feature("web"):
		return
	_ensure_js_bridge()
	_js_resume_audio_context()
	_js_play_once()
	# YT iframe API may still be loading — retry for ~3s
	_retry_left = 180
	set_process(true)

func pause() -> void:
	## HTML musicPause / mute gate — hard stop; clears lofi preference
	_want_play = false
	enabled = false
	_retry_left = 0
	set_process(false)
	_js_eval("try{if(window.kamMusicPause)window.kamMusicPause();}catch(e){}")

func soft_pause() -> void:
	## Optional: pause video without clearing enabled/ytWant.
	## Prefer not to call on visibilitychange — HTML never does; autoplay blocks resume.
	if not enabled:
		return
	_js_eval("try{if(window.kamMusicSoftPause)window.kamMusicSoftPause();}catch(e){}")

func soft_resume() -> void:
	## Tab visible again / recover from browser throttle — resume if user still wants lofi
	if not enabled or not _want_play:
		return
	_js_resume_audio_context()
	_js_play_once()
	_retry_left = maxi(_retry_left, 60)
	set_process(true)

func set_volume(v: float) -> void:
	## 0..1 → YT 0..100 (HTML applyMusicVol)
	var vv := clampf(v, 0.0, 1.0)
	_js_eval("try{if(window.kamMusicVol)window.kamMusicVol(%s);}catch(e){}" % _js_num(vv))
	# If user had music on and volume leaves zero, keep stream going
	if vv > 0.01 and enabled and _want_play:
		_js_play_once()

func is_web_music() -> bool:
	return OS.has_feature("web")

func _js_play_once() -> void:
	var vol := 1.0
	if AudioBus:
		vol = clampf(AudioBus.music_volume, 0.0, 1.0)
	_js_eval(
		"try{if(window.kamMusicPlay){window.kamMusicPlay(%s);}else{console.warn('[kamMusic] play before bridge');}}catch(e){console.warn('[kamMusic]',e);}"
		% _js_num(vol)
	)

func _js_resume_audio_context() -> void:
	## HTML initMaster / actx resume after user gesture (SFX WebAudio)
	_js_eval(
		"try{var AC=window.AudioContext||window.webkitAudioContext;if(AC){if(!window.__kamAC)window.__kamAC=new AC();if(window.__kamAC.state==='suspended')window.__kamAC.resume();}}catch(e){}"
	)

func _js_num(v: float) -> String:
	## Always emit a JS number literal (avoid locale commas)
	return "%.4f" % v

func _js_eval(code: String) -> void:
	if not OS.has_feature("web"):
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	# Global execution context so window.kamMusicPlay is the page bridge (not a sandbox)
	JavaScriptBridge.eval(code, true)

func _ensure_js_bridge() -> void:
	## Inject bridge if export head patch missing (hot reload / alternate shell)
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	var has_bridge = JavaScriptBridge.eval("!!(window.kamMusicPlay)", true)
	if str(has_bridge) == "true" or has_bridge == true:
		# Ensure soft-pause API exists even on older patched shells
		var has_soft = JavaScriptBridge.eval("!!(window.kamMusicSoftPause)", true)
		if str(has_soft) != "true" and has_soft != true:
			_js_eval("""
(function(){
  if(window.kamMusicSoftPause) return;
  window.kamMusicSoftPause=function(){
    try{
      if(window.__kamYtPlayer&&window.__kamYtPlayer.pauseVideo)window.__kamYtPlayer.pauseVideo();
    }catch(e){}
  };
})();
""".replace("\n", " "))
		return
	# Minimal inject (same API as godot/export/web_music_head.html)
	var inject := """
(function(){
  if(window.kamMusicPlay) return;
  var YT_ID='%s';
  var ytPlayer=null, ytReady=false, ytWant=false, ytVol=100;
  function ensureDiv(){
    var el=document.getElementById('ytmusic');
    if(!el){ el=document.createElement('div'); el.id='ytmusic';
      el.style.cssText='position:fixed;width:2px;height:2px;left:0;bottom:0;opacity:0;pointer-events:none;overflow:hidden';
      document.body.appendChild(el); }
    return el;
  }
  function boot(){
    ensureDiv();
    if(typeof YT==='undefined'||!YT.Player){ setTimeout(boot,200); return; }
    try{
      ytPlayer=new YT.Player('ytmusic',{videoId:YT_ID,playerVars:{autoplay:0,controls:0,disablekb:1,loop:1,playlist:YT_ID,modestbranding:1,playsinline:1,rel:0,fs:0},
        events:{onReady:function(){ytReady=true;try{ytPlayer.setVolume(ytVol);ytPlayer.unMute();}catch(e){} if(ytWant){try{ytPlayer.playVideo();}catch(e2){}}},
          onStateChange:function(e){if(e.data===YT.PlayerState.ENDED){try{ytPlayer.playVideo();}catch(e3){}}}}});
      window.__kamYtPlayer=ytPlayer;
    }catch(e){console.warn('[kamMusic] inject',e);}
  }
  window.kamMusicPlay=function(vol01){ytWant=true;if(typeof vol01==='number')ytVol=Math.round(Math.max(0,Math.min(1,vol01))*100);
    if(ytReady&&ytPlayer){try{ytPlayer.setVolume(ytVol);ytPlayer.unMute();ytPlayer.playVideo();}catch(e){}}};
  window.kamMusicPause=function(){ytWant=false;if(ytReady&&ytPlayer){try{ytPlayer.pauseVideo();}catch(e){}}};
  window.kamMusicSoftPause=function(){if(ytReady&&ytPlayer){try{ytPlayer.pauseVideo();}catch(e){}}};
  window.kamMusicVol=function(vol01){ytVol=Math.round(Math.max(0,Math.min(1,Number(vol01)||0))*100);
    if(ytReady&&ytPlayer){try{ytPlayer.setVolume(ytVol);}catch(e){}}};
  if(!document.querySelector('script[src*="youtube.com/iframe_api"]')){
    var s=document.createElement('script'); s.src='https://www.youtube.com/iframe_api'; document.head.appendChild(s);
  }
  var prev=window.onYouTubeIframeAPIReady;
  window.onYouTubeIframeAPIReady=function(){ if(prev)try{prev();}catch(e){} boot(); };
  if(typeof YT!=='undefined'&&YT.Player) boot(); else setTimeout(boot,300);
})();
""" % YT_ID
	_js_eval(inject.replace("\n", " "))
