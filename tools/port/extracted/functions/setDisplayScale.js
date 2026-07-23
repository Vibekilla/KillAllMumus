function setDisplayScale(pct){
  displayScale=Math.max(0.5, Math.min(1, (Number(pct)||100)/100));
  const el=document.getElementById('disp-scale'); if(el) el.value=Math.round(displayScale*100);
  const v=document.getElementById('disp-scale-v'); if(v) v.textContent=Math.round(displayScale*100)+'%';
  document.querySelectorAll('.disp-preset').forEach(b=>{
    b.classList.toggle('on', Number(b.dataset.scale)===Math.round(displayScale*100));
  });
  saveDisplayPrefs(); if(typeof fit==='function') fit();
}
