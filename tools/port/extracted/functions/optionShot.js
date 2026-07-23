function optionShot(x,y,aim,wep){ const s={x,y,dead:false,dmg:1};
  if(wep==='laser'){ s.vx=Math.cos(aim)*17; s.vy=Math.sin(aim)*17; s.laser=true; }
  else if(wep==='homing'){ s.vx=Math.cos(aim)*6; s.vy=Math.sin(aim)*6; s.home=true; }
  else if(wep==='wave'){ s.vx=Math.cos(aim)*11; s.vy=Math.sin(aim)*11; s.wv=3.2; s.wph=tick*0.4; }
  else if(wep==='scatter'){ const off=(Math.random()-0.5)*0.14, sp=10+Math.random()*3; s.vx=Math.cos(aim+off)*sp; s.vy=Math.sin(aim+off)*sp; s.life=22; }
  else if(wep==='gatling'){ s.vx=Math.cos(aim)*19; s.vy=Math.sin(aim)*19; s.gat=true; s.dmg=2; }
  else if(wep==='grenade'){ s.vx=Math.cos(aim)*8; s.vy=Math.sin(aim)*8; s.nade=true; s.life=32; s.dmg=3; }
  else if(wep==='voidripper'){ s.vx=Math.cos(aim)*15; s.vy=Math.sin(aim)*15; s.vrip=true; s.pierce=true; s.hit=new Set(); s.dmg=2; }
  else if(wep==='lotus'){ const off=(Math.random()-0.5)*0.7; s.vx=Math.cos(aim+off)*7; s.vy=Math.sin(aim+off)*7; s.petal=true; s.curl=(off<0?-1:1)*0.035; s.life=58; }
  else if(wep==='shock'){ const j=(Math.random()-0.5)*0.5; s.vx=Math.cos(aim+j)*(13+Math.random()*4); s.vy=Math.sin(aim+j)*(13+Math.random()*4); s.zap=true; s.dmg=2; }
  else { s.vx=Math.cos(aim)*13; s.vy=Math.sin(aim)*13; }   // spread / default
  pshots.push(s); }
