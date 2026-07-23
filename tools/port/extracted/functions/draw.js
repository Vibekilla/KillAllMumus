function draw(){
  ctx.clearRect(0,0,W,H);
  if(state==='title'){ drawTitle(); return; }
  if(state==='leaderboard'){ drawLeaderboard(); return; }
  if(state==='emblems'){ drawEmblems(); return; }
  if(state==='outfits'){ drawOutfits(); return; }
  if(state==='ngselect'){ drawNgSelect(); return; }
  if(state==='arsenal'){ drawArsenal(); return; }
  if(state==='shop'){ drawShop(); return; }
  ctx.save(); ctx.beginPath(); ctx.rect(PF.x,PF.y,PF.w,PF.h); ctx.clip();
  if(screenShake>0.3){ ctx.translate((Math.random()-.5)*screenShake, (Math.random()-.5)*screenShake); screenShake*=0.85; } else screenShake=0;   // melee impact shake
  drawStageBg();
  drawBossAmbience();                                   // Touhou-style psychedelic boss backdrop
  let _celebOff=null;   // during her victory pose, shift the aura/bubble/radiance to follow the bobbing sprite so she stays perfectly centred in them
  if(player && !player.dead && boss && boss.dead && boss.intro<=0){ const _P=poseParams(outfitPose,tick); _celebOff={x:player.x,y:player.y}; player.x+=_P.sway*0.4; player.y-=_P.bounce*0.4; }   // keep her real facing so the victory pose follows her orientation
  if(player && !player.dead) drawPowerRadiance(player); // her bubble warps the map slightly
  for(const f of floaters) drawFloater(f);
  for(const e of enemies){ drawMumu(e); if(e.stun>0) drawStunStars(e); if(e.charm>0){ ctx.save(); ctx.globalAlpha=0.7+0.3*Math.sin(tick*0.3); ctx.font='13px serif'; ctx.textAlign='center'; ctx.fillText('💗', e.x, e.y-e.r-5); ctx.textAlign='left'; ctx.restore(); } }
  drawBurns();                                          // plasma-flame fields (Kuma charged)
  if(boss) drawBoss(boss);
  if(run && run.cleared) drawClearGate();   // post-boss portal + shop entrance
  for(const it of items) drawItem(it);
  for(const s of pshots) drawPShot(s);
  for(const b of bullets) drawBullet(b);
  if(player && player.phaseT>0) drawPhaseVeil();   // Wormhole — dim the "other reality" so Bobina draws bright on top of it
  if(player && !player.dead){ const _celeb = boss && boss.dead && boss.intro<=0;   // boss down → she performs her chosen victory pose (the full animation) on the field
    if(_celeb){ drawPowerAura(player); drawPosedFigure(player.x, player.y, 1, tick, outfitPose, selectedOutfit, 0, VICTORY_FACES[victoryFace].expr, player.face); }   // motionScale 0 — player already offset by the bob; pass her facing so the pose follows her orientation
    else { drawDashComet(player); drawPowerAura(player); drawBobina(player); }
    if(player.shieldT>0){ const _sc=bodyCtr(player); ctx.save(); ctx.translate(_sc.x,_sc.y); ctx.globalAlpha=0.55*(player.shieldT<50?player.shieldT/50:1); ctx.strokeStyle='#e8a860'; ctx.lineWidth=2.5; ctx.shadowColor='#e8a860'; ctx.shadowBlur=12; ctx.beginPath(); ctx.arc(0,0,23,0,7); ctx.stroke(); ctx.strokeStyle='rgba(255,240,214,0.75)'; ctx.lineWidth=1.2; for(let i=0;i<6;i++){ const ang=tick*0.05+i*1.047; ctx.beginPath(); ctx.arc(0,0,23,ang,ang+0.35); ctx.stroke(); } ctx.restore(); }
    if(player.rapidT>0){ const _rc=bodyCtr(player); ctx.save(); ctx.translate(_rc.x,_rc.y); ctx.globalAlpha=0.5; ctx.fillStyle='#ffe14a'; for(let i=0;i<3;i++){ ctx.beginPath(); ctx.arc((Math.random()-.5)*12, 10+Math.random()*8, 1.6,0,7); ctx.fill(); } ctx.restore(); }
    if(player.vialHits>0){ const _vc=bodyCtr(player); ctx.save(); ctx.translate(_vc.x,_vc.y); const vf=player.vialT<50?player.vialT/50:1;   // Unholy Vial — void ward ring + a shard per remaining charge
      ctx.globalAlpha=0.62*vf; ctx.strokeStyle='#9d6bff'; ctx.lineWidth=2.4; ctx.shadowColor='#9d6bff'; ctx.shadowBlur=14; ctx.beginPath(); ctx.arc(0,0,25,0,7); ctx.stroke();
      ctx.shadowBlur=0; ctx.globalAlpha=vf; ctx.fillStyle='#c9a6ff'; for(let i=0;i<player.vialHits;i++){ const ang=tick*0.06+i*(6.283/3); ctx.beginPath(); ctx.arc(Math.cos(ang)*25,Math.sin(ang)*25,3.4,0,7); ctx.fill(); } ctx.restore(); }
    if(player.phaseT>0){ const _pc=bodyCtr(player); ctx.save(); ctx.translate(_pc.x,_pc.y); ctx.globalCompositeOperation='lighter';   // Wormhole — phase aura on Bobina (the "real" one) + a depleting timer ring
      for(let k=0;k<2;k++){ ctx.strokeStyle=k?'rgba(150,120,255,0.5)':'rgba(90,220,255,0.55)'; ctx.lineWidth=1.6; const rr=24+Math.sin(tick*0.2+k*2.1)*4; ctx.beginPath(); ctx.arc(k?3:-3,0,rr,0,7); ctx.stroke(); }
      ctx.globalCompositeOperation='source-over'; ctx.strokeStyle='rgba(180,240,255,0.78)'; ctx.lineWidth=2; ctx.beginPath(); ctx.arc(0,0,28,-Math.PI/2,-Math.PI/2+6.283*(player.phaseT/180)); ctx.stroke(); ctx.restore(); }
  }
  if(_celebOff){ player.x=_celebOff.x; player.y=_celebOff.y; }   // restore after the victory-pose draw
  drawFx();
  for(const q of particles){ ctx.globalAlpha=Math.max(0,q.life/30); ctx.fillStyle=q.c; ctx.beginPath(); ctx.arc(q.x,q.y,2.2,0,7); ctx.fill(); ctx.globalAlpha=1; }
  drawMeleeFx();
  for(const st of scoreTexts){ ctx.globalAlpha=Math.max(0,st.life/44); ctx.fillStyle=st.color; ctx.font='bold 12px monospace'; ctx.textAlign='center'; ctx.fillText(st.txt,st.x,st.y); ctx.textAlign='left'; ctx.globalAlpha=1; }
  for(const em of emotes) drawEmote(em);
  if(player&&player.bombFx>0){ ctx.fillStyle='rgba(255,180,230,'+(player.bombFx/46*0.5)+')'; ctx.fillRect(PF.x,PF.y,PF.w,PF.h); }
  if(slowmoT>0) drawSlowmoFx();
  // collection line hint
  if(player&&player.focus){ ctx.strokeStyle='rgba(255,255,255,0.12)'; ctx.setLineDash([6,6]); ctx.beginPath(); ctx.moveTo(PF.x,COLLECT_LINE); ctx.lineTo(PF.x+PF.w,COLLECT_LINE); ctx.stroke(); ctx.setLineDash([]); }
  if(dialog) drawDialog();
  if(flashMsg){ ctx.save(); ctx.globalAlpha=Math.min(1,flashMsg.t/20); ctx.textAlign='center'; ctx.fillStyle='#fff'; ctx.font='900 26px "Trebuchet MS"';
    const maxW=PF.w-30, words=String(flashMsg.txt).split(' '); let line='', lines=[];   // wrap so long alerts (item use, shop notices) fit the play window
    for(const wd of words){ const test=line?line+' '+wd:wd; if(ctx.measureText(test).width>maxW && line){ lines.push(line); line=wd; } else line=test; } if(line) lines.push(line);
    const lh=30, y0=PF.y+PF.h/2-(lines.length-1)*lh/2;
    for(let i=0;i<lines.length;i++) ctx.fillText(lines[i], PF.x+PF.w/2, y0+i*lh);
    ctx.textAlign='left'; ctx.restore(); }
  ctx.restore();
  ctx.strokeStyle='rgba(255,140,200,0.5)'; ctx.lineWidth=2; ctx.strokeRect(PF.x-1,PF.y-1,PF.w+2,PF.h+2);
  drawPanel();
  if(state==='intro') drawIntro();
  if(state==='stageclear') drawStageClear();
  if(state==='win') drawWin();
  if(state==='gameover') drawGameOver();
  /* paused state now shown via the #pausescreen HTML overlay (tap to resume) */
}
