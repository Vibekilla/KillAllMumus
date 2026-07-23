function joyApply(t){ let dx=t.clientX-joy.cx, dy=t.clientY-joy.cy; const d=Math.hypot(dx,dy); if(d>JOY_R){ dx*=JOY_R/d; dy*=JOY_R/d; }
  joy.vx=dx/JOY_R; joy.vy=dy/JOY_R; joyknob.style.transform=`translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px))`; }
