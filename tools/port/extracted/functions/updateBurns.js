function updateBurns(){ if(!burns.length) return;
  for(const bn of burns){ bn.life--; bn.dt++;
    if(bn.dt%6===0){ for(const e of enemies){ const dx=e.x-bn.x,dy=e.y-bn.y,d=Math.hypot(dx,dy); if(d<bn.reach && angDiff(Math.atan2(dy,dx),bn.dir)<bn.half){ e.hp-=2; e.flash=4; if(e.hp<=0) killEnemy(e); } }
      enemies=enemies.filter(e=>e.hp>0);
      if(boss && !boss.dead && boss.intro<=0){ const dx=boss.x-bn.x,dy=boss.y-bn.y,d=Math.hypot(dx,dy); if(d<bn.reach && angDiff(Math.atan2(dy,dx),bn.dir)<bn.half){ boss.hp-=2; boss.flash=2; } }
      bullets=bullets.filter(b=>{ const dx=b.x-bn.x,dy=b.y-bn.y,d=Math.hypot(dx,dy); if(d<bn.reach*0.9 && angDiff(Math.atan2(dy,dx),bn.dir)<bn.half){ floaters.push({x:b.x,y:b.y,life:10,vy:-0.4,scale:0.28}); return false; } return true; }); }
    if(!paused){ const a=bn.dir-bn.half+Math.random()*(bn.half*2), rr=bn.reach*(0.3+Math.random()*0.7);
      particles.push({x:bn.x+Math.cos(a)*rr,y:bn.y+Math.sin(a)*rr,vx:(Math.random()-.5)*1.5,vy:-1.4-Math.random()*1.6,life:14+((Math.random()*8)|0),c:Math.random()<0.4?'#fff':(Math.random()<0.5?bn.col:'#ff7a2a')}); }
  }
  burns=burns.filter(b=>b.life>0);
}
