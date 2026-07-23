function useSpecial(){
  if(!run || player.dead) return;
  if(run.special<100) return;   // not charged — do NOTHING (cycling is a separate button: [B] / CYCLE), so quick/repeat [V] never accidentally cycles
  const sp=armedSpec(); if(!sp) return;   // no special in the loadout
  run.special=0; sfx('bomb'); flashMsg={t:70,txt:'★ '+sp.name.toUpperCase()+'!'};
  estats.specials=(estats.specials||0)+1; if(estats.specials>=25) unlockEmblem('special_25'); saveEstats();
  const px=player.x, py=player.y;
  if(sp.key==='laser'){ fx.push({type:'laser', t:64, w:58, x:px, y:py, ang:aimAngle()}); }
  else if(sp.key==='mech'){ fx.push({type:'mech', t:240, ct:0, x:px, y:py-52}); }
  else if(sp.key==='bearzooka'){ fx.push({type:'bearzooka', t:156, ct:0, x:PF.x-30, y:PF.y+34}); }
  else if(sp.key==='stampede'){ for(let i=0;i<6;i++) fx.push({type:'bull', t:100, x:PF.x+40+i*(PF.w-80)/5, y:PF.y+PF.h+24+Math.random()*40, hit:new Set()}); }
  else if(sp.key==='badger'){ for(let i=0;i<3;i++){ const dir=i%2?-1:1; fx.push({type:'badger', t:90, dir, x:(dir>0?PF.x-30:PF.x+PF.w+30), y:PF.y+70+i*((PF.h-140)/2), hit:new Set()}); } }
  else if(sp.key==='sixth'){ slowmoT=300; slowAcc=0; slowAccE=0; slowAccB=0; sfx('power'); screenShake=Math.max(screenShake,5); }   // time warp
  else if(sp.key==='revenge'){ const N=5; for(let i=0;i<N;i++){ const bx=PF.x+50+((i+0.5)/N)*(PF.w-100)+(Math.random()-.5)*36, by=PF.y+70+Math.random()*(PF.h-170); fx.push({type:'blackhole', t:150, dt:0, x:bx, y:by, vx:0, vy:0, r:0, col:'#3ae66a'}); } sfx('whip'); }
  else if(sp.key==='kiss'){ for(const e of enemies) e.charm=180; fx.push({type:'kiss', t:48, r:0, x:px, y:py}); sfx('power'); }
  else if(sp.key==='kraken'){ const N=5; for(let i=0;i<N;i++){ const tx=PF.x+55+((i+0.5)/N)*(PF.w-110), ty=PF.y+100+Math.random()*(PF.h-200); fx.push({type:'tentacle', t:360, ct:0, x:tx, y:ty, ph:Math.random()*6.28, reach:76}); } sfx('whip'); }
  else if(sp.key==='void'){ const N=4; for(let i=0;i<N;i++){ const a=i/N*6.28; fx.push({type:'servitor', t:600, hp:26, maxhp:26, sz:2.2, x:px+Math.cos(a)*38, y:py+Math.sin(a)*38, ct:i*7}); } sfx('card'); }
  else { for(let i=0;i<3;i++) fx.push({type:'wave', delay:i*16, r:0, x:px, y:py, hit:new Set(), alive:true}); }
  for(let i=0;i<30;i++) particles.push({x:px,y:py,vx:(Math.random()-.5)*12,vy:(Math.random()-.5)*12,life:30,c:sp.col});
}
