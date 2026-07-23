function joyShowHome(){ if(!joybase) return; joyHome=joyHomePos(); joy.cx=joyHome.x; joy.cy=joyHome.y;
  joybase.style.left=joyHome.x+'px'; joybase.style.top=joyHome.y+'px'; joybase.style.display='block'; joybase.classList.add('idle'); joyknob.style.transform='translate(-50%,-50%)'; }
