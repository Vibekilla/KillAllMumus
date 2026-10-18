extends Node
## HTML lofi YouTube playlist bridge, shuffled.
## Playlist PLC6gDrhD6E1X_mZ8arMGO48Ta-cpsnuzR (the radio stream rPjez8z61rI ended).
## Web: JavaScriptBridge → window.kamMusicPlay (export HTML head + runtime inject fallback).
## Desktop: preference only (no YT embed unless a local stream is added later).
## Does NOT iframe the HTML game — music only.

const YT_LIST := "PLC6gDrhD6E1X_mZ8arMGO48Ta-cpsnuzR"

## HTML lofiOn — user opted into music at soundgate
var enabled: bool = false
var _want_play: bool = false
var _retry_left: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_ensure_js_bridge()
		call_deferred("_cold_volume")

func _cold_volume() -> void:
	## HTML applyMusicVol on load (localStorage) before the first play() gesture.
	if AudioBus:
		set_volume(AudioBus.music_volume)

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
	# YT iframe API may still be loading — retry ~6s (cold social-tab / slow iframe)
	_retry_left = 360
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
	var has_list = JavaScriptBridge.eval("window.__kamMusicList==='%s'" % YT_LIST, true)
	if str(has_list) == "true" or has_list == true:
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
	# Same playlist player as godot/export/web_music_head.html.
	# Replaces a page that still points at the ended radio stream.
	var inject := """
(function(){
  var YT_LIST='%s';
  if(window.__kamMusicList===YT_LIST && window.kamMusicPlay) return;
  window.__kamMusicList=YT_LIST;
  var ytPlayer=null, ytReady=false, ytWant=false, ytVol=100, ytShuffled=false, ytErrSkips=0, ytKickUntil=0, booted=false;
  function ytPost(func, args){
    try{
      var iframe=document.getElementById('ytmusic');
      if(!iframe||!iframe.contentWindow) return;
      iframe.contentWindow.postMessage(JSON.stringify({event:'command',func:func,args:args||[],id:'ytmusic',channel:'widget'}),'*');
    }catch(e){}
  }
  function ytKick(){
    if(!ytWant) return;
    try{ if(ytPlayer){ ytPlayer.setVolume(ytVol); ytPlayer.unMute(); ytPlayer.playVideo(); } }catch(e){}
    ytPost('setVolume',[ytVol]); ytPost('unMute'); ytPost('playVideo');
  }
  function ytShuffle(){
    if(ytShuffled) return;
    ytShuffled=true;
    var ytShuffleJump=-1, listed=false;
    try{
      if(ytPlayer){
        ytPlayer.setLoop(true);
        ytPlayer.setShuffle(true);
        var list=(ytPlayer.getPlaylist&&ytPlayer.getPlaylist())||[];
        listed=!!(list&&list.length);
        if(list&&list.length>1){
          var cur=0; try{ cur=ytPlayer.getPlaylistIndex()||0; }catch(e1){}
          if(cur<0||cur>=list.length) cur=0;
          ytShuffleJump=Math.floor(Math.random()*(list.length-1));
          if(ytShuffleJump>=cur) ytShuffleJump++;
        }
      }
    }catch(e){}
    ytPost('setLoop',[true]); ytPost('setShuffle',[true]);
    if(ytShuffleJump>=0){
      try{ if(ytPlayer) ytPlayer.playVideoAt(ytShuffleJump); }catch(e2){}
      ytPost('playVideoAt',[ytShuffleJump]);
    }else if(!listed){
      try{ if(ytPlayer) ytPlayer.nextVideo(); }catch(e3){}
      ytPost('nextVideo');
    }
  }
  function ensureDiv(){
    var el=document.getElementById('ytmusic');
    if(el && el.tagName==='IFRAME'){
      var d=document.createElement('div'); d.id='ytmusic';
      d.style.cssText='position:fixed;width:2px;height:2px;left:0;bottom:0;opacity:0;pointer-events:none;overflow:hidden';
      el.parentNode.replaceChild(d, el); el=d;
    }
    if(!el){ el=document.createElement('div'); el.id='ytmusic';
      el.style.cssText='position:fixed;width:2px;height:2px;left:0;bottom:0;opacity:0;pointer-events:none;overflow:hidden';
      (document.body||document.documentElement).appendChild(el); }
    return el;
  }
  function boot(){
    if(booted) return;
    ensureDiv();
    if(typeof YT==='undefined'||!YT.Player){ setTimeout(boot,200); return; }
    booted=true;
    try{
      if(ytPlayer&&ytPlayer.destroy){ try{ ytPlayer.destroy(); }catch(e){} }
      ytPlayer=new YT.Player('ytmusic',{width:2,height:2,playerVars:{autoplay:0,controls:0,disablekb:1,loop:1,listType:'playlist',list:YT_LIST,modestbranding:1,playsinline:1,rel:0,fs:0,origin:location.origin},
        events:{onReady:function(){ ytReady=true; ytKick(); },
          onStateChange:function(e){ if(e.data===YT.PlayerState.PLAYING){ ytErrSkips=0; ytKickUntil=0; ytShuffle(); } if(e.data===YT.PlayerState.CUED&&ytWant) ytKick(); if(e.data===YT.PlayerState.ENDED&&ytWant){ try{ ytPlayer.nextVideo(); }catch(e2){} ytPost('nextVideo'); } },
          onError:function(){ if(!ytWant) return; ytErrSkips++; if(ytErrSkips>12) return; try{ ytPlayer.nextVideo(); }catch(e){} ytPost('nextVideo'); }}});
      window.__kamYtPlayer=ytPlayer;
    }catch(e){ booted=false; console.warn('[kamMusic] inject', e); }
  }
  window.kamMusicPlay=function(vol01){ ytWant=true; if(typeof vol01==='number') ytVol=Math.round(Math.max(0,Math.min(1,vol01))*100);
    ytKickUntil=Date.now()+12000; ytKick(); };
  window.kamMusicPause=function(){ ytWant=false; ytKickUntil=0; if(ytPlayer){ try{ ytPlayer.pauseVideo(); }catch(e){} } ytPost('pauseVideo'); };
  window.kamMusicSoftPause=function(){ ytKickUntil=0; if(ytPlayer){ try{ ytPlayer.pauseVideo(); }catch(e){} } ytPost('pauseVideo'); };
  setInterval(function(){ if(ytWant && Date.now()<ytKickUntil) ytKick(); }, 1000);
  window.kamMusicVol=function(vol01){ ytVol=Math.round(Math.max(0,Math.min(1,Number(vol01)||0))*100);
    if(ytReady&&ytPlayer){ try{ ytPlayer.setVolume(ytVol); }catch(e){} } };
  if(!document.querySelector('script[src*="youtube.com/iframe_api"]')){
    var s=document.createElement('script'); s.src='https://www.youtube.com/iframe_api'; document.head.appendChild(s);
  }
  window.onYouTubeIframeAPIReady=function(){ boot(); };
  if(typeof YT!=='undefined'&&YT.Player) boot(); else setTimeout(boot,300);
})();
""" % YT_LIST
	_js_eval(inject.replace("\n", " "))
