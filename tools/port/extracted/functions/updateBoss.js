function updateBoss(){
  const b=boss, p=player;
  if(b.intro>0){ b.y+=(b.ty-b.y)*0.06;
    // once the monologue finishes (or is skipped in speedrun), instantly sweep any leftover wave mobs so the
    // boss opens on a clean arena — no awkward lingering, no wasted power waiting them out
    if(b.introDlg){ if(!dialog){ b.intro=0; b.introDlg=false; clearWaveMobs(); } }
    else if(--b.intro<=0){ b.intro=0; }
    return; }
  if(b.dead){ b.deadT++;
    if(b.hell){ updateWynnHell(b); return; }   // James Wynn's hell-portal cutscene runs its own course
    if(b.deadT===1){ for(let i=0;i<12;i++) dropItem(b.x+(Math.random()-.5)*40,b.y,'power'); for(let i=0;i<8;i++) dropItem(b.x+(Math.random()-.5)*50,b.y,'point'); dropItem(b.x,b.y,'life'); dropItem(b.x-10,b.y,'bomb'); dropWeapon(b.x+14,b.y); }
    if(b.deadT%3===0) burst(b.x+(Math.random()-.5)*b.r*2,b.y+(Math.random()-.5)*b.r*2,b.data.color); if(b.deadT>150) spawnClearGate(); return; }
  b.t++; if(b.flash>0)b.flash--;
  // twins trade the stage back and forth "when they feel like it" — but never bail out at a sliver of HP (let you finish him)
  if(b.twin){ const other=b.active==='igor'?'grichka':'igor'; if(b.swapCd>0)b.swapCd--; if(b.swapCd<=0 && !b.tw[other].done && b.hp>b.maxhp*0.16) twinSwap(b); }
  // ---- roaming movement: wander to RANDOM spots across the whole map (never homing in on the player) ----
  if(b.mtx===undefined || b.t%100===0){
    b.mtx = PF.x+55 + Math.random()*(PF.w-110);
    b.mty = PF.y+55 + Math.random()*(PF.h-135);
    b.dash = Math.random()<0.34;
  }
  const ez = b.dash?0.055:0.03;
  b.x += (b.mtx-b.x)*ez + Math.sin(b.t*0.05)*0.5;
  b.y += (b.mty-b.y)*ez + Math.sin(b.t*0.033)*0.4;
  b.x=Math.max(PF.x+40,Math.min(PF.x+PF.w-40,b.x)); b.y=Math.max(PF.y+40,Math.min(PF.y+PF.h-80,b.y));   // full-map range
  // if the player hugs the boss's model, keep her on the edge of it (never inside) with one gentle bump per touch —
  // small radius so you can still fly right up and fire; no launch, so she never snaps to the top
  if(!p.dead){ const dxp=p.x-b.x, dyp=p.y-b.y, dp=Math.hypot(dxp,dyp), near=b.r+12;
    if(dp<near){ const nx=dp>0.01?dxp/dp:0, ny=dp>0.01?dyp/dp:-1, push=(near-dp);
      p.x+=nx*push; p.y+=ny*push;                                     // resolve the overlap only — ride the model's edge
      p.x=Math.max(PF.x+8,Math.min(PF.x+PF.w-8,p.x)); p.y=Math.max(PF.y+8,Math.min(PF.y+PF.h-8,p.y));
      if(p.knock<=0){ p.vx=nx*4.5; p.vy=ny*4.5; p.knock=6;            // one soft shove per contact cycle (not every frame)
        if(!b._push){ sfx('hit'); b._push=true; } for(let i=0;i<3;i++) particles.push({x:p.x,y:p.y,vx:nx*2.4,vy:ny*2.4,life:12,c:b.data.color}); } }
    else b._push=false; }
  // boss turns to face its travel direction too
  const bvx=b.x-(b.px===undefined?b.x:b.px), bvy=b.y-(b.py===undefined?b.y:b.py); b.px=b.x; b.py=b.y;
  const bfaceT = Math.hypot(bvx,bvy)>0.4 ? Math.atan2(bvy,bvx) : Math.PI/2;
  b.face = lerpAngle(b.face===undefined?Math.PI/2:b.face, bfaceT, 0.08);
  const cx=b.x, cy=b.y, s=run.stageIdx, ph=b.phase, hm=(hardMode?0.7:1.25)*(1-Math.min(s,3)*0.07);
  if(b.stun>0){ b.stun--; }   // Monke-charge stagger — boss skips its attack while stunned
  else if(b.specialT>0){ b.specialT--; bossSpecial(b,cx,cy); }
  else if(s===0){
    if(ph===0){ if(b.t%Math.floor(40*hm)===0) fanAt(cx,cy,p.x,p.y,7,1.0,2.6,7,'#e6c65a'); if(b.t%90===0) ring(cx,cy,16,1.8,6,'#c9a24b',b.t*0.05); if(b.t%150===0) heavyShell(cx,cy,p.x,p.y,3); }
    else { b.spin+=0.3; if(b.t%3===0){ for(let a=0;a<3;a++) eb(cx,cy,b.spin+a*2.094,2.4,6,'#ffd27a'); } if(b.t%70===0) fanAt(cx,cy,p.x,p.y,9,1.2,3,6,'#e6c65a'); }
  } else if(s===1){
    if(ph===0){ if(b.t%Math.floor(46*hm)===0) ring(cx,cy,20,1.7,6,'#8fd0ff',b.t*0.04); if(b.t%64===0) fanAt(cx,cy,p.x,p.y,5,0.7,3.2,7,'#7ea8ff'); }
    else if(ph===1){ b.spin+=0.22; if(b.t%3===0){ for(let a=0;a<4;a++) eb(cx,cy,b.spin+a*1.5708,2.2,6,'#a0e0ff'); } if(b.t%140===0) heavyShell(cx,cy,p.x,p.y,3.2); }
    else { if(b.t%Math.floor(30*hm)===0) fanAt(cx,cy,p.x,p.y,11,1.4,3.4,6,'#c7f0ff'); if(b.t%100===0) ring(cx,cy,24,1.9,5,'#8fd0ff',0); }
  } else if(s===2){ // Mumina — green
    if(ph===0){ if(b.t%Math.floor(42*hm)===0) ring(cx,cy,18,1.7,6,'#7ed957',b.t*0.04); if(b.t%60===0) fanAt(cx,cy,p.x,p.y,6,0.8,3.2,7,'#bff58a'); }
    else if(ph===1){ b.spin+=0.2; if(b.t%3===0){ for(let a=0;a<5;a++) eb(cx,cy,b.spin+a*1.2566,2.2,6,'#9ff06a'); } if(b.t%130===0) heavyShell(cx,cy,p.x,p.y,3.2); }
    else { if(b.t%Math.floor(30*hm)===0) fanAt(cx,cy,p.x,p.y,11,1.5,3.2,6,'#d6ffa8'); if(b.t%96===0) ring(cx,cy,22,1.9,5,'#7ed957',0); }
  } else if(s===3){ // Lily — Solana purple/teal, low-latency barrage
    if(ph===0){ if(b.t%Math.floor(40*hm)===0) ring(cx,cy,18,1.8,5,'#9945ff',b.t*0.05); if(b.t%54===0) fanAt(cx,cy,p.x,p.y,7,0.9,3.4,6,'#14f195'); }
    else if(ph===1){ b.spin+=0.24; if(b.t%2===0){ for(let a=0;a<4;a++) eb(cx,cy,b.spin+a*1.5708,2.6,5,'#14f195'); } if(b.t%120===0) heavyShell(cx,cy,p.x,p.y,3.2); }
    else { if(b.t%Math.floor(26*hm)===0) fanAt(cx,cy,p.x,p.y,12,1.5,3.6,6,'#c9a0ff'); if(b.t%88===0) ring(cx,cy,24,2.0,5,'#9945ff',0); }
  } else if(s===4){ // India Police — spam-call saffron/orange barrage
    if(ph===0){ if(b.t%Math.floor(42*hm)===0) ring(cx,cy,20,1.7,5,'#e08a2a',b.t*0.05); if(b.t%58===0) fanAt(cx,cy,p.x,p.y,7,0.9,3.2,6,'#ffd27a'); }
    else if(ph===1){ b.spin+=0.22; if(b.t%3===0){ for(let a=0;a<4;a++) eb(cx,cy,b.spin+a*1.5708,2.4,5,'#f0a020'); } if(b.t%64===0) fanAt(cx,cy,p.x,p.y,5,0.7,3.4,7,'#ff7a3c'); if(b.t%140===0) heavyShell(cx,cy,p.x,p.y,3.2); }
    else { if(b.t%Math.floor(28*hm)===0) fanAt(cx,cy,p.x,p.y,11,1.4,3.4,6,'#ffe0a0'); if(b.t%92===0) ring(cx,cy,26,1.9,5,'#e08a2a',0); }
  } else if(s===5){ // Bogdanoff twins — the attack changes with whoever's on the strings
    const rage=b.hp<b.maxhp*0.4;
    if(b.active==='igor'){ // Igor — astral violet: weaving spiral "puppet strings" + expanding ring pulses
      b.spin+=0.16; const arms=rage?6:5; if(b.t%3===0){ for(let a=0;a<arms;a++) eb(cx,cy,b.spin+a*(6.2832/arms),2.2,6,'#b48ce0'); }
      if(b.t%Math.floor(72*hm)===0) ring(cx,cy,18,1.7,6,'#9d6bff',b.t*0.05);
      if(rage && b.t%42===0) fanAt(cx,cy,p.x,p.y,7,0.9,3.0,6,'#c9a0ff');
    } else { // Grichka — akashic gold: fate-reading aimed fans + heavy predicted shells
      if(b.t%Math.floor(40*hm)===0) fanAt(cx,cy,p.x,p.y,rage?11:8,1.2,3.2,7,'#e0b84a');
      if(b.t%96===0) ring(cx,cy,22,1.8,5,'#ffd27a',0);
      if(b.t%150===0) heavyShell(cx,cy,p.x,p.y,3.2);
      if(rage && b.t%6===0){ b.spin+=0.4; for(let a=0;a<3;a++) eb(cx,cy,b.spin+a*2.094,2.4,6,'#ffe08a'); }
    }
  } else { // Wynn — final
    if(ph===0){ if(b.t%Math.floor(38*hm)===0) fanAt(cx,cy,p.x,p.y,9,1.2,3.2,7,'#ff8a3c'); if(b.t%84===0) ring(cx,cy,18,2.0,6,'#ff5b7d',b.t*0.05); }
    else if(ph===1){ b.spin+=0.26; if(b.t%2===0){ for(let a=0;a<4;a++) eb(cx,cy,b.spin+a*1.5708,2.5,6,'#ff6ec7'); } if(b.t%70===0) fanAt(cx,cy,p.x,p.y,7,1.0,3.6,7,'#ffd27a'); if(b.t%160===0) heavyShell(cx,cy,p.x,p.y,3.4); }
    else { b.spin+=0.16; if(b.t%2===0){ for(let a=0;a<5;a++) eb(cx,cy,b.spin+a*1.2566,2.3,6,'#ff5b3c'); } if(b.t%40===0) fanAt(cx,cy,p.x,p.y,13,1.6,3.6,6,'#ff9ecb'); if(b.t%140===0) ring(cx,cy,28,2.2,5,'#ff5b7d',0); }
  }
  if(b.t%24===0) sfx('shoot');
  const _bm=bossDmgMul(), _wm=bossWepMul();
  for(const ps of pshots){ if(!ps.dead){ const dx=ps.x-b.x,dy=ps.y-b.y; if(dx*dx+dy*dy<(b.r+6)*(b.r+6)){ ps.dead=true; b.hp-=(ps.voidbolt? ps.dmg*0.3*_bm : ps.dmg*_bm*_wm); b.flash=3; sparks(ps.x,ps.y,ps.voidbolt?'#9d6bff':'#ffd27a'); } } }   // void-servitor bolts keep their own 0.3; regular shots scale down with power (_bm) AND a single-target/difficulty weapon debuff (_wm) so bosses don't melt
  // BOSS SPECIAL — fires once at 45% HP
  if(!b.specialUsed && b.hp<=b.maxhp*0.45){ b.specialUsed=true; b.specialT=200; bulletCancelAll(); b.flash=10; sfx('card'); flashMsg={t:120,txt:'★ SPECIAL: '+b.data.special}; startDialog([{w:0,t:b.data.taunt}], b.data); for(let i=0;i<40;i++) particles.push({x:b.x,y:b.y,vx:(Math.random()-.5)*11,vy:(Math.random()-.5)*11,life:34,c:b.data.color}); }
  // phase transitions
  const perPhase=b.maxhp/b.phases;
  if(b.hp<=b.maxhp-perPhase*(b.phase+1) && b.phase<b.phases-1){ b.phase++; bulletCancelAll(); b.flash=8; sfx('card');
    if(!dialog && b.data.taunts){ const tt=b.data.taunts[(Math.random()*b.data.taunts.length)|0], rr=b.data.retorts?b.data.retorts[(Math.random()*b.data.retorts.length)|0]:null; startDialog(rr?[{w:0,t:tt},{w:1,t:rr}]:[{w:0,t:tt}], b.data); }  // taunt + Bobina's comeback
    for(let i=0;i<40;i++) particles.push({x:b.x,y:b.y,vx:(Math.random()-.5)*10,vy:(Math.random()-.5)*10,life:34,c:'#fff'}); }
  if(b.hp<=0 && !b.dead){
    if(b.twin){ const other=b.active==='igor'?'grichka':'igor'; b.tw[b.active].hp=0; b.tw[b.active].done=true;
      if(!b.tw[other].done){   // one twin felled — the survivor seizes the strings; fight continues
        b.active=other; b.hp=b.tw[other].hp; b.maxhp=b.tw[other].max; b.hudName=(other==='igor'?'Igor':'Grichka')+' Bogdanoff';
        b.swapCd=480+((Math.random()*180)|0); b.flash=14; b.spin=0; bullets=[]; bulletCancelAll(); sfx('win');
        flashMsg={t:130,txt:'⚔ '+(other==='igor'?'IGOR':'GRICHKA')+' RISES — beat BOTH!'};
        for(let i=0;i<40;i++) particles.push({x:b.x,y:b.y,vx:(Math.random()-.5)*10,vy:(Math.random()-.5)*10,life:34,c:'#fff'});
        if(!dialog) startDialog([{w:0,t:'One of us falls — the other pulls the strings. WE ARE LEGION.'},{w:1,t:'“Legion.” There are two of you. With the same face.'}], b.data);
        b.mtx=PF.x+55+Math.random()*(PF.w-110); b.mty=PF.y+55+Math.random()*(PF.h-135);
        return; }   // still one Bogdanoff standing — not defeated yet
    }
    b.dead=true; b.hp=0; bullets=[]; sfx('win'); unlockEmblem('boss_first');
    estats.bosses=(estats.bosses||0)+1; if(estats.bosses>=15) unlockEmblem('boss_hunter'); saveEstats();
    if(b.data.portrait==='bogdanoff') unlockEmblem('bog_slayer');   // both twins down → unlock the Voidling skin
    if(b.data.portrait==='wynn'){ startWynnHell(b); }
    else if(b.data.victory) startDialog([{w:1,t:b.data.victory}], b.data); }
}
