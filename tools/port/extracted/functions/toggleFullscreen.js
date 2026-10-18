function toggleFullscreen(){ const el=document.documentElement;
  if(!document.fullscreenElement && !document.webkitFullscreenElement){
    (el.requestFullscreen||el.webkitRequestFullscreen||function(){}).call(el);
  } else {
    (document.exitFullscreen||document.webkitExitFullscreen||function(){}).call(document);
  } }
const fsBtn=document.getElementById('fsbtn');
const fsSupported=!!(document.documentElement.requestFullscreen||document.documentElement.webkitRequestFullscreen);
if(fsBtn){ if(!fsSupported){ fsBtn.style.display='none'; const _pb=document.getElementById('pausebtn'); if(_pb) _pb.classList.add('nofs'); } else { fsBtn.addEventListener('click', toggleFullscreen); } }
