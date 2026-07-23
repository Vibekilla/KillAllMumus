function joyReset(){ joy.active=false; joy.vx=0; joy.vy=0;
  const on=document.getElementById('touch').classList.contains('on');
  if(on){ joybase.classList.add('idle'); joyknob.style.transform='translate(-50%,-50%)'; } else if(joybase) joybase.style.display='none'; }
