function setDebugLayer(on){
  debugLayer=!!on;
  const b=document.getElementById('disp-debug'), v=document.getElementById('disp-debug-v');
  if(b) b.classList.toggle('on', debugLayer);
  if(v) v.textContent=debugLayer?'ON':'OFF';
  saveDisplayPrefs();
}
