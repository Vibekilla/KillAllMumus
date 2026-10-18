function joyReset(){ joy.active=false; joy.vx=0; joy.vy=0;
  const on=document.getElementById('touch').classList.contains('on');
  if(on){ joybase.classList.add('idle'); joyknob.style.transform='translate(-50%,-50%)'; } else if(joybase) joybase.style.display='none'; }
joyzone.addEventListener('touchstart',joyStart,{passive:false});
joyzone.addEventListener('touchmove',joyMove,{passive:false});
addEventListener('touchend',joyEnd); addEventListener('touchcancel',joyEnd);
// show touch controls ONLY during play (keep them up while paused so the pause button can un-pause); reset the stick when hidden or paused
