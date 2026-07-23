function goFullscreenMobile(){ try{
  if(!(('ontouchstart' in window)||navigator.maxTouchPoints>0)) return;
  const el=document.documentElement; const rf=el.requestFullscreen||el.webkitRequestFullscreen;
  if(rf && !document.fullscreenElement && !document.webkitFullscreenElement){ const r=rf.call(el); if(r&&r.catch)r.catch(()=>{}); setTimeout(()=>{ if(typeof fit==='function') fit(); },250); }
}catch(e){} }
