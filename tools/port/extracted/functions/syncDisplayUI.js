function syncDisplayUI(){
  setDisplayScale(Math.round((displayScale||1)*100));
  setRefreshRate(refreshRate||60);
  setDebugLayer(!!debugLayer);
  const fsOn=!!(document.fullscreenElement||document.webkitFullscreenElement);
  const fv=document.getElementById('disp-fs-v'); if(fv) fv.textContent=fsOn?'Fullscreen':'Windowed';
  const fb=document.getElementById('disp-fs'); if(fb) fb.classList.toggle('on', fsOn);
}
