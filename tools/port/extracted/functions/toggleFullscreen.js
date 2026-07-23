function toggleFullscreen(){ const el=document.documentElement;
  if(!document.fullscreenElement && !document.webkitFullscreenElement){
    (el.requestFullscreen||el.webkitRequestFullscreen||function(){}).call(el);
  } else {
    (document.exitFullscreen||document.webkitExitFullscreen||function(){}).call(document);
  } }
