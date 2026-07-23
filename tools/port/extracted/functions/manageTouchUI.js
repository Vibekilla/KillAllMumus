function manageTouchUI(){ const show=isTouch && state==='play';
  const el=document.getElementById('touch'); if(!el)return;
  if(el._on!==show){ el._on=show; el.classList.toggle('on',show);
    if(show){ joyShowHome(); } else { joy.active=false; joy.vx=0; joy.vy=0; if(joybase) joybase.style.display='none'; } }
  if(paused && joy.active) joyReset();
  if(show) updateTouchButtons(); }
