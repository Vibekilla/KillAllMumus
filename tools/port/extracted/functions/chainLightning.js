function chainLightning(sx,sy,dmg,jumps,col){ let x=sx,y=sy; const hit=new Set(), pts=[{x,y}];
  for(let j=0;j<jumps;j++){ let best=null,bd=1e9; for(const e of enemies){ if(hit.has(e))continue; const d=Math.hypot(e.x-x,e.y-y); if(d<175 && d<bd){bd=d;best=e;} }
    if(!best) break; hit.add(best); best.hp-=dmg+2; best.flash=6; best.stun=Math.max(best.stun||0,24); x=best.x; y=best.y; pts.push({x,y});
    for(let s=0;s<4;s++) particles.push({x,y,vx:(Math.random()-.5)*4,vy:(Math.random()-.5)*4,life:12,c:s%2?col:'#fff'}); }
  for(const e of enemies){ if(e.hp<=0 && hit.has(e)) killEnemy(e); } enemies=enemies.filter(e=>e.hp>0);
  if(pts.length>1) meleeFx.push({bolt:true,pts,col,life:12,t:0});
}
