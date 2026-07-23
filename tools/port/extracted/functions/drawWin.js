function drawWin(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#2a1030'); g.addColorStop(1,'#4a1828'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  for(let i=0;i<24;i++){ const hx=(i*97+tick*1.5)%W, hyy=H-((i*61+tick*2)%H); ctx.globalAlpha=0.5; drawHeart(hx,hyy,6+i%3*2); } ctx.globalAlpha=1;
  ctx.textAlign='center';
  // title
  ctx.save(); ctx.shadowColor='#ffd27a'; ctx.shadowBlur=24; ctx.fillStyle='#ffe08a'; ctx.font='900 44px "Trebuchet MS"'; ctx.fillText('BOBO IS SAVED!', W/2, 62); ctx.restore();
  // hero: the reunion feast image (falls back to a drawn scene if not yet loaded)
  const cimg=IMG.winimg, iw2=178, ih2=150, ix=W/2-iw2/2, iy=78;
  if(imgOK(cimg)){ ctx.save(); ctx.shadowColor='rgba(255,180,80,0.5)'; ctx.shadowBlur=22; ctx.beginPath(); ctx.roundRect(ix,iy,iw2,ih2,14); ctx.clip();
    const s=Math.max(iw2/cimg.naturalWidth, ih2/cimg.naturalHeight), dw=cimg.naturalWidth*s, dh=cimg.naturalHeight*s;
    ctx.drawImage(cimg, ix+(iw2-dw)/2, iy+(ih2-dh)/2, dw, dh); ctx.restore();
    ctx.strokeStyle='rgba(255,210,120,0.8)'; ctx.lineWidth=3; ctx.beginPath(); ctx.roundRect(ix,iy,iw2,ih2,14); ctx.stroke(); }
  else { ctx.save(); ctx.fillStyle='rgba(255,255,255,0.05)'; ctx.beginPath(); ctx.roundRect(ix,iy,iw2,ih2,14); ctx.fill(); ctx.clip();
    const cyf=iy+ih2-20; const pb={x:W/2-34,y:cyf,iframe:0,focus:false,walk:0,bombFx:0,lean:0}; drawBobina(pb); drawBobo(W/2+34, cyf-24, 1.05, true);
    ctx.globalAlpha=0.9; drawHeart(W/2, iy+ih2*0.4+Math.sin(tick*0.1)*3, 6); ctx.globalAlpha=1; ctx.restore();
    ctx.strokeStyle='rgba(255,210,120,0.6)'; ctx.lineWidth=3; ctx.beginPath(); ctx.roundRect(ix,iy,iw2,ih2,14); ctx.stroke(); }
  let y=iy+ih2+24;
  ctx.fillStyle='#ff9ecb'; ctx.font='italic 15px "Trebuchet MS"'; ctx.fillText('Every last Mumu exterminated. James Wynn finished. Dad is safe.', W/2, y); y+=25;
  ctx.fillStyle='#fff'; ctx.font='bold 16px monospace'; ctx.fillText('MUMU KILLS '+totalKills+'   ·   RANK '+rankLetter()+'   ·   SCORE '+fmtScore(sessionScore), W/2, y); y+=22;
  if(difficulty>0||ngPlus>0){ ctx.fillStyle=difficulty>=2?'#ff5b6e':'#ffd27a'; ctx.font='bold 12px monospace'; ctx.fillText('— cleared on '+modeTag()+' —', W/2, y); y+=19; }
  // unlock celebrations
  if(winCabalUnlock){ ctx.save(); ctx.shadowColor='#ff2a00'; ctx.shadowBlur=12; ctx.fillStyle=(Math.floor(tick/16)%2)?'#ff6a6a':'#ffd27a'; ctx.font='900 16px "Trebuchet MS"'; ctx.fillText('☠  CABAL SKIN UNLOCKED!  ☠', W/2, y); ctx.restore(); y+=21; }
  if(ngUnlocked>0){ ctx.fillStyle='#8fd0a0'; ctx.font='bold 12px monospace'; ctx.fillText('🔁 New Game+ Lv'+ngUnlocked+' ready — pick it on the menu for ×'+(1+ngUnlocked)+' points & tougher Mumus', W/2, y); y+=19; }
  // emblems earned THIS run (persistent achievements), capped to the space above the buttons
  ctx.fillStyle='#ffd27a'; ctx.font='bold 13px monospace'; ctx.fillText('🏅 EMBLEMS EARNED  ·  '+emblemCount()+'/'+EMBLEMS.length+' total', W/2, y); y+=17;
  const earned=newEmblems.map(id=>emblemDef(id)).filter(Boolean);
  if(earned.length){ const maxEm=Math.max(1, Math.floor((H-116-y)/15)), shown=earned.slice(0,maxEm);
    for(const em of shown){ ctx.fillStyle='#8fd0ff'; ctx.font='bold 12px monospace'; ctx.fillText((em.icon||'★')+' '+em.name+(em.outfit?'  — unlocked a skin!':''), W/2, y); y+=15; }
    if(earned.length>shown.length){ ctx.fillStyle='#9a8ba8'; ctx.font='11px monospace'; ctx.fillText('+'+(earned.length-shown.length)+' more this run', W/2, y); } }
  else { ctx.fillStyle='#9a8ba8'; ctx.font='italic 12px "Trebuchet MS"'; ctx.fillText('No new Emblems this run — check the 🏅 Emblems menu for more to chase.', W/2, y); }
  // buttons pinned to the bottom
  const sy=H-104; drawShareBtn(W/2, sy, true); drawMenuBtn(W/2, sy+38);
  ctx.textAlign='center'; ctx.fillStyle=(Math.floor(tick/26)%2)?'#fff':'#9a7c96'; ctx.font='bold 14px monospace'; ctx.fillText('PRESS '+kb('shoot')+' / TAP TO PLAY AGAIN', W/2, H-14); ctx.textAlign='left';
}
