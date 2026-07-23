function drawPanelPortrait(){
  // ===== TOP BAR (above the playfield): score, stage, rank/kills, lives, bombs =====
  ctx.fillStyle='rgba(16,9,22,0.82)'; ctx.fillRect(0,0,W,PF.y-6);
  ctx.strokeStyle='rgba(255,120,190,0.22)'; ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(0,PF.y-6); ctx.lineTo(W,PF.y-6); ctx.stroke();
  if(!run) return;
  ctx.textAlign='left';
  ctx.fillStyle='#e8d6f0'; ctx.font='9px monospace'; ctx.fillText('SCORE', 14, 15);
  ctx.fillStyle='#fff'; ctx.font='bold 21px monospace'; ctx.fillText(fmtScore(sessionScore), 14, 37);
  ctx.fillStyle='#8fd0ff'; ctx.font='8px monospace'; ctx.fillText((STAGES[run.stageIdx].title+' · '+STAGES[run.stageIdx].name).slice(0,34), 14, 50);
  // rank + kills (middle-top, right-aligned to clear the top-right pause/fullscreen buttons)
  ctx.textAlign='right';
  ctx.fillStyle='#ffd27a'; ctx.font='900 24px "Trebuchet MS"'; ctx.fillText(rankLetter(), W-135, 30);
  ctx.fillStyle='#ff9ab0'; ctx.font='bold 10px monospace'; ctx.fillText(totalKills+' MUMUS  ×'+scoreMult().toFixed(1), W-135, 47);
  // lives + bombs row (y~64)
  ctx.textAlign='left'; ctx.fillStyle='#e8d6f0'; ctx.font='9px monospace'; ctx.fillText('LIVES', 14, 68);
  for(let i=0;i<Math.max(0,run.lives);i++){ drawHeart(52+i*15, 64, 5.4); }
  ctx.textAlign='right'; ctx.fillStyle='#e8d6f0'; ctx.font='9px monospace'; ctx.fillText('BOMBS', W-92, 68);
  ctx.fillStyle='#ff8ad6'; ctx.font='13px monospace'; ctx.textAlign='left'; for(let i=0;i<run.bombs;i++){ ctx.fillText('✸', W-84+i*15, 69); }
  if(difficulty>0||ngPlus>0){ ctx.textAlign='center'; ctx.fillStyle=difficulty>=2?'#ff2a2a':'#ff5b6e'; ctx.font='bold 9px monospace'; ctx.fillText('★'+modeTag(), W/2, 68); }
  ctx.textAlign='left';
  // ===== BOTTOM STRIP (below the playfield): power / special / boss bars — sits above the thumb controls =====
  const x=14, w=W-28; let by=PANEL.y+6;
  // POWER
  ctx.fillStyle='#e8d6f0'; ctx.font='10px monospace'; ctx.fillText('POWER', x, by+8);
  ctx.textAlign='right'; ctx.fillStyle='#ffd27a'; ctx.font='bold 11px monospace'; ctx.fillText('Lv'+shotLevel()+(shotLevel()>=5?' MAX':'  '+Math.round(Math.max(0,Math.min(1,(run.power-1)/5))*100)+'%'), x+w, by+8); ctx.textAlign='left';
  ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x,by+12,w,8,3); ctx.fill();
  const pfrac=Math.max(0,Math.min(1,(run.power-1)/5)); const pg=ctx.createLinearGradient(x,0,x+w,0); pg.addColorStop(0,'#ff6ec7'); pg.addColorStop(1,'#ffd27a'); ctx.fillStyle=pg; ctx.beginPath(); ctx.roundRect(x,by+12,Math.max(0,w*pfrac),8,3); ctx.fill();
  for(let i=1;i<5;i++){ const lx=x+w*(i/5); ctx.strokeStyle='rgba(0,0,0,0.4)'; ctx.beginPath(); ctx.moveTo(lx,by+12); ctx.lineTo(lx,by+20); ctx.stroke(); }
  by+=28;
  // SPECIAL
  { const sp=armedSpec()||{col:'#6a5a72',icon:'—',name:'None'}, ready=run.special>=100;
    ctx.fillStyle='#e8d6f0'; ctx.font='10px monospace'; ctx.fillText('SPECIAL', x, by+8);
    ctx.textAlign='right'; ctx.fillStyle=sp.col; ctx.font='bold 10px monospace'; ctx.fillText(sp.icon+' '+sp.name, x+w, by+8); ctx.textAlign='left';
    ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x,by+12,w,8,3); ctx.fill();
    ctx.fillStyle=sp.col; ctx.globalAlpha=ready?1:0.85; ctx.beginPath(); ctx.roundRect(x,by+12,w*(run.special/100),8,3); ctx.fill(); ctx.globalAlpha=1;
    if(ready){ ctx.fillStyle=(Math.floor(tick/8)%2)?'#fff':'#1a0e14'; ctx.font='bold 8px monospace'; ctx.textAlign='center'; ctx.fillText('READY — tap ★', x+w/2, by+19); ctx.textAlign='left'; }
    by+=28; }
  // WEAPON + MELEE + GRAZE compact line
  { const m=MELEE[(player&&player.melee)||0]||MELEE[0], wp=WEAPONS[run.weapon];
    ctx.fillStyle='#c8b0c4'; ctx.font='10px monospace';
    ctx.fillText((wp?wp.icon+' '+wp.name:'—'), x, by+8);
    ctx.textAlign='center'; ctx.fillStyle=m.col; ctx.fillText(m.icon+' '+m.name, W/2, by+8); ctx.textAlign='left';
    ctx.textAlign='right'; ctx.fillStyle='#8fd0ff'; ctx.fillText('GRAZE '+graze, x+w, by+8); ctx.textAlign='left';
    by+=22; }
  // BOSS bar OR stage progress
  if(boss && !boss.dead && boss.intro<=0){
    ctx.fillStyle=boss.data.color; ctx.font='bold 12px "Trebuchet MS"'; ctx.fillText(boss.hudName||boss.data.name, x, by+8);
    ctx.fillStyle='#3a1020'; ctx.beginPath(); ctx.roundRect(x,by+12,w,9,3); ctx.fill();
    const g=ctx.createLinearGradient(x,0,x+w,0); g.addColorStop(0,'#ff3b30'); g.addColorStop(1,boss.data.color); ctx.fillStyle=g; ctx.beginPath(); ctx.roundRect(x,by+12,w*Math.max(0,boss.hp/boss.maxhp),9,3); ctx.fill();
    if(boss.twin){ const o=boss.active==='igor'?'grichka':'igor', of=boss.tw[o].done?0:boss.tw[o].hp/boss.tw[o].max; ctx.fillStyle='#241633'; ctx.beginPath(); ctx.roundRect(x,by+23,w,5,2); ctx.fill(); ctx.fillStyle=boss.tw[o].done?'#4a4a55':'#9d6bff'; ctx.beginPath(); ctx.roundRect(x,by+23,w*of,5,2); ctx.fill(); ctx.fillStyle='#b8a0d0'; ctx.font='8px monospace'; ctx.textAlign='right'; ctx.fillText((o==='igor'?'Igor':'Grichka')+(boss.tw[o].done?' ✕ down':''), x+w, by+21); ctx.textAlign='left'; }
    else for(let i=0;i<boss.phases;i++){ ctx.fillStyle=i<=boss.phase?'#ffd27a':'#5a4a55'; ctx.beginPath(); ctx.arc(x+6+i*14,by+26,4,0,7); ctx.fill(); }
  } else {
    const prog=Math.min(1,stageTime/STAGES[run.stageIdx].waveDur);
    ctx.fillStyle='#c8b0c4'; ctx.font='10px monospace'; ctx.fillText('STAGE PROGRESS', x, by+8);
    ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x,by+12,w,7,3); ctx.fill(); ctx.fillStyle='#8fd35a'; ctx.beginPath(); ctx.roundRect(x,by+12,w*prog,7,3); ctx.fill();
  }
}
