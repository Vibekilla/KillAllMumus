function fire(){
  const p=player, lv=shotLevel(), wep=(run&&run.weapon)||'spread', aim=aimAngle();
  // fire a shot at angular offset from the aim direction
  const shot=(off,spd,dmg,extra)=>{ const a=aim+off, s={ x:p.x+Math.cos(a)*10, y:p.y+Math.sin(a)*10, vx:Math.cos(a)*spd, vy:Math.sin(a)*spd, dmg, dead:false }; if(extra)Object.assign(s,extra); pshots.push(s); };
  if(wep==='laser'){
    if(p.focus){ shot(0,20,3,{foc:true,laser:true}); if(lv>=2){ shot(-0.05,20,2,{laser:true}); shot(0.05,20,2,{laser:true}); } }
    else { const n=Math.min(5,1+lv); for(let i=0;i<n;i++) shot((i-(n-1)/2)*0.06,18,2,{laser:true}); }
  } else if(wep==='homing'){
    const n=lv+1; for(let i=0;i<n;i++) shot((i-(n-1)/2)*0.42,6,1,{home:true});
  } else if(wep==='wave'){
    // Wave Beam — weaving twin beams that snake toward enemies (pierce-ish, medium dmg)
    const ph=tick*0.4; shot(0,11,1,{wv:2.6+lv*0.4, wph:ph}); shot(0,11,1,{wv:2.6+lv*0.4, wph:ph+Math.PI});
    if(lv>=3){ shot(0,11,1,{wv:4+lv*0.4, wph:ph+Math.PI/2}); }
  } else if(wep==='scatter'){
    // Scatter Burst — wide shotgun spray, great crowd clear, short range
    const n=3+lv*2; for(let i=0;i<n;i++){ const off=(i-(n-1)/2)*0.14 + (Math.random()-0.5)*0.06; shot(off,10+Math.random()*3,1,{life:22}); }
  } else if(wep==='gatling'){
    // Mumina's Gatling Lasers — a tight BRAIDED multi-barrel stream firing dead-straight (a minigun of green lasers)
    const barrels=Math.min(5,2+Math.floor(lv/1.5)), perpX=-Math.sin(aim), perpY=Math.cos(aim), cax=Math.cos(aim), cay=Math.sin(aim);
    for(let b=0;b<barrels;b++){ const lat=(b-(barrels-1)/2)*6 + Math.sin(tick*0.9+b*1.6)*2.6;   // barrels weave around the axis → braided rope of light
      pshots.push({x:p.x+perpX*lat+cax*8, y:p.y+perpY*lat+cay*8, vx:cax*20, vy:cay*20, dmg:2, dead:false, gat:true}); }
  } else if(wep==='grenade'){
    // Grrnade Launcher — a deliberate, slow-firing single lob (2 at max power), not a spray
    const n=(lv>=5?3:lv>=4?2:1); for(let i=0;i<n;i++){ const off=(i-(n-1)/2)*0.16; shot(off,7+lv*0.4,2+Math.floor(lv/2),{nade:true, life:30+lv*3}); } sfx('thud',0.6);
  } else if(wep==='voidripper'){
    // Voidripper — PARALLEL piercing rift-lanes that carve straight columns clean through everything (wide-set, no fan)
    const lanes=Math.min(5,1+Math.floor(lv/1.2)), perpX=-Math.sin(aim), perpY=Math.cos(aim), cax=Math.cos(aim), cay=Math.sin(aim);
    for(let i=0;i<lanes;i++){ const lat=(i-(lanes-1)/2)*18;
      pshots.push({x:p.x+perpX*lat+cax*8, y:p.y+perpY*lat+cay*8, vx:cax*15, vy:cay*15, dmg:3+lv, dead:false, vrip:true, pierce:true, hit:new Set()}); }
  } else if(wep==='lotus'){
    // Lotus Petals — a WIDE blooming fan of petals that drift out and curl (area bloom, NOT homing like the bananas)
    const n=6+lv*2, spread=1.5+lv*0.4;
    for(let i=0;i<n;i++){ const off=(i-(n-1)/2)*(spread/(n-1)); shot(off, 6.2+Math.random()*1.4, 1, {petal:true, curl:(off<0?-1:1)*0.03, life:62}); }
  } else if(wep==='shock'){
    // Shock & Awe — an ERRATIC crackling arc-spray: bolts fork out at jittery random angles and speeds, chain-lightning on hit
    const n=2+lv; for(let i=0;i<n;i++){ const off=(Math.random()-0.5)*(0.55+lv*0.09); shot(off, 13+Math.random()*5, 2, {zap:true}); }
  } else {
    if(p.focus){ const n=1+lv; for(let i=0;i<n;i++) shot((i-(n-1)/2)*0.05,16,2,{foc:true}); }
    else { const spreadA=[[0],[-0.13,0.13],[-0.2,0,0.2],[-0.26,-0.09,0.09,0.26],[-0.32,-0.14,0,0.14,0.32]][lv-1];
      for(const off of spreadA) shot(off,13,1);
      if(lv>=4){ shot(-0.5,9,1,{home:true}); shot(0.5,9,1,{home:true}); } }
  }
  // options (familiars) fire a shot that MATCHES the equipped weapon (no more generic default bullet)
  const opts=optionOffsets(lv);
  for(const o of opts){ const q=optionPos(p,o); optionShot(q.x+Math.cos(aim)*4, q.y+Math.sin(aim)*4, aim, wep); }
  sfx('shoot');
}
