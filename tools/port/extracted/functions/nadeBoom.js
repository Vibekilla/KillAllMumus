function nadeBoom(x,y){ burst(x,y,'#b6e34a'); screenShake=Math.max(screenShake,3); sfx('bomb',0.6);
  for(let i=0;i<14;i++) particles.push({x,y,vx:(Math.random()-.5)*8,vy:(Math.random()-.5)*8,life:20,c:i%2?'#b6e34a':'#fff'});
  for(const e of enemies){ if(Math.hypot(e.x-x,e.y-y)<50){ e.hp-=8; e.flash=5; if(e.hp<=0) killEnemy(e); } }   // still strong crowd-clear
  if(boss&&!boss.dead&&boss.intro<=0 && Math.hypot(boss.x-x,boss.y-y)<58){ boss.hp-=2; boss.flash=4; }   // nerfed vs bosses (was 5) — no more mowing them down
  bullets=bullets.filter(b=>{ if(Math.hypot(b.x-x,b.y-y)<44){ floaters.push({x:b.x,y:b.y,life:10,vy:-0.4,scale:0.28}); return false; } return true; });
  enemies=enemies.filter(e=>e.hp>0); }
