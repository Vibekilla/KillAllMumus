function enemyExplode(e){ if(e._exploded) return; e._exploded=true; e.hp=0;
  burst(e.x,e.y,'#ffd27a'); for(let i=0;i<12;i++) particles.push({x:e.x,y:e.y,vx:(Math.random()-.5)*9,vy:(Math.random()-.5)*9,life:22,c:i%2?'#ffd27a':'#fff'});
  for(const o of enemies){ if(o!==e && o.hp>0 && Math.hypot(o.x-e.x,o.y-e.y)<46){ o.hp-=6; o.flash=5; if(o.hp<=0) killEnemy(o); } }
  bullets=bullets.filter(b=>{ if(Math.hypot(b.x-e.x,b.y-e.y)<42){ floaters.push({x:b.x,y:b.y,life:12,vy:-0.5,scale:0.3}); return false; } return true; });
  killEnemy(e); screenShake=Math.max(screenShake,3.5); sfx('hit'); }
