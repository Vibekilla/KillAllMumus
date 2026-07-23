function meleeChargeFx(p, m, dir, reach, half, dmg, kb){
  if(m.fx==='flame'){   // Kuma Katana — lingering plasma-flame field burns the swipe zone
    burns.push({x:p.x,y:p.y,dir,half:half+0.15,reach:reach*1.05,life:78,max:78,col:m.col,dt:0}); sfx('bomb');
  } else if(m.fx==='chain'){   // Kraken Lash — chain lightning leaps between Mumus
    chainLightning(p.x,p.y,dmg,6,m.col); sfx('graze');
  } else if(m.fx==='blackhole'){   // Ourbie's Scythe — hurl a green black hole that sucks Mumus in, grouping them
    fx.push({type:'blackhole', t:96, dt:0, x:p.x+Math.cos(dir)*18, y:p.y+Math.sin(dir)*18, vx:Math.cos(dir)*5.5, vy:Math.sin(dir)*5.5, r:0, col:m.col}); sfx('whip'); sfx('power');
  } else if(m.fx==='shockwall'){   // Vault Hammer — fling Mumus into the walls; they detonate on impact
    meleeFx.push({ring:true,x:p.x,y:p.y,r0:reach*0.4,r1:reach*1.6,col:m.col,life:22,t:0});
    for(const e of enemies){ const dx=e.x-p.x,dy=e.y-p.y,d=Math.hypot(dx,dy); if(d<reach*1.4){ const sx=dx>=0?1:-1; e.vx=sx*(13+Math.random()*4); e.vy=(dy>=0?1:-1)*(3+Math.random()*3); e.flung=44; e.stun=Math.max(e.stun||0,70); } }
    let rc=0,vap=0; bullets=bullets.filter(b=>{ if(Math.hypot(b.x-p.x,b.y-p.y)<reach*1.2){ vap++; floaters.push({x:b.x,y:b.y,life:14,vy:-0.5,scale:0.34}); if(rc<44){dropItem(b.x,b.y,'point');rc++;} return false; } return true; });
    if(vap>=20) unlockEmblem('melee_shock'); screenShake=Math.max(screenShake,8); sfx('boom');
  } else if(m.fx==='flurry'){   // Badger Claws — a thousand-strike flurry mows the area in front
    p.flurry=30; p.flurryDir=dir; p.flurryDmg=Math.max(1,Math.round(dmg*0.5)); sfx('claw');
  }
}
