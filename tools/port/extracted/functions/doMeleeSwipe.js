function doMeleeSwipe(charge, dirOverride){ const p=player; if(!p||p.dead) return;
  charge=Math.min(1,charge||0); const m=MELEE[p.melee||0]||MELEE[0], pw=0.55+charge*0.85;
  const reach=m.reach*pw, kb=m.kb*pw, dmg=Math.max(1,Math.round(m.dmg*pw)), half=m.arc/2;
  const dir=(dirOverride!==undefined?dirOverride:(p.aim!==undefined?p.aim:-Math.PI/2)), cancel=(charge>0.6);
  meleeFx.push({x:p.x,y:p.y,dir,reach,half,col:m.col,key:m.key,life:16,t:0,charge});
  // enemies in the arc: damage + knock outward + bright hit sparks
  let hitAny=false, mk=0;
  for(const e of enemies){ const dx=e.x-p.x,dy=e.y-p.y,d=Math.hypot(dx,dy);
    if(d<reach+e.r && angDiff(Math.atan2(dy,dx),dir)<half+0.25){ e.hp-=dmg; e.flash=6; hitAny=true;
      const nx=d>0.5?dx/d:0, ny=d>0.5?dy/d:-1; e.x+=nx*kb*2.2; e.y+=ny*kb*2.2; e.vy=(e.vy||0)+ny*kb*0.25;
      for(let s=0;s<5;s++) particles.push({x:e.x,y:e.y,vx:nx*3+(Math.random()-.5)*5,vy:ny*3+(Math.random()-.5)*5,life:15,c:s%2?m.col:'#fff'});
      if(e.hp<=0){ estats.mkills=(estats.mkills||0)+1; mk++; killEnemy(e); } } }
  enemies=enemies.filter(e=>e.hp>0);
  // bullets: point-blank / charged ones get cancelled (points); the rest get shoved outward for room
  let cnt=0; bullets=bullets.filter(b=>{ const dx=b.x-p.x,dy=b.y-p.y,d=Math.hypot(dx,dy);
    if(d<reach+18 && (d<46 || angDiff(Math.atan2(dy,dx),dir)<half+0.4)){
      if(cancel || d<30){ floaters.push({x:b.x,y:b.y,life:14,vy:-0.5,scale:0.34}); if(cnt<28){ dropItem(b.x,b.y,'point'); cnt++; } return false; }
      const sp=Math.max(2.6,Math.hypot(b.vx,b.vy)), nx=d>0.5?dx/d:0, ny=d>0.5?dy/d:-1; b.vx=nx*sp; b.vy=ny*sp; return true; }
    return true; });
  // boss: chip damage + a little shove
  if(boss && !boss.dead && boss.intro<=0){ const dx=boss.x-p.x,dy=boss.y-p.y,d=Math.hypot(dx,dy);
    if(d<reach+boss.r && angDiff(Math.atan2(dy,dx),dir)<half+0.3){ boss.hp-=dmg; boss.flash=4; hitAny=true; boss.x+=(d>0.5?dx/d:0)*kb*0.5; boss.y+=(d>0.5?dy/d:-1)*kb*0.5; } }
  // melee emblems
  if(mk>0) unlockEmblem('melee_first'); if((estats.mkills||0)>=300) unlockEmblem('melee_slayer');
  if(hitAny){ estats.mweps=(estats.mweps||0)|(1<<(p.melee||0)); if((estats.mweps & ((1<<MELEE.length)-1))===((1<<MELEE.length)-1)) unlockEmblem('melee_all'); }
  for(let i=0;i<12+((charge*12)|0);i++){ const a=dir-half+Math.random()*m.arc, rr=reach*(0.45+Math.random()*0.55); particles.push({x:p.x+Math.cos(a)*rr,y:p.y+Math.sin(a)*rr,vx:Math.cos(a)*2.4,vy:Math.sin(a)*2.4,life:16,c:Math.random()<0.5?m.col:'#fff'}); }
  // CHARGED: each weapon triggers its own signature effect on a full charge
  if(charge>=0.85) meleeChargeFx(p, m, dir, reach, half, dmg, kb);
  screenShake=Math.max(screenShake, 2.5 + charge*5 + (m.kb/9)*2.5);   // heavier weapons / bigger charge shake more
  p.meleeCd=m.cd||18; sfx(m.snd||'kill'); sfx('graze');
}
