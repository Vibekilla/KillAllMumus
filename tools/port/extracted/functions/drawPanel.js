function drawPanel(){ if(portrait){ drawPanelPortrait(); return; } if(isTouch){ drawPanelTouch(); return; } const x=PANEL.x, y=PANEL.y, w=PANEL.w;
  ctx.fillStyle='rgba(18,10,24,0.6)'; ctx.beginPath(); ctx.roundRect(x,y,w,PANEL.h,10); ctx.fill(); ctx.strokeStyle='rgba(255,120,190,0.25)'; ctx.lineWidth=1; ctx.stroke();
  let cy=y+24; ctx.textAlign='left';
  ctx.fillStyle='#ff7ab5'; ctx.font='900 18px "Trebuchet MS"'; ctx.fillText('KILL ALL', x+16, cy); cy+=19; ctx.fillStyle='#ffd27a'; ctx.fillText('MUMUS!!', x+16, cy); cy+=6;
  ctx.strokeStyle='rgba(255,255,255,0.12)'; ctx.beginPath(); ctx.moveTo(x+14,cy); ctx.lineTo(x+w-14,cy); ctx.stroke(); cy+=20;
  if(!run) return;
  ctx.fillStyle='#8fd0ff'; ctx.font='bold 11px monospace'; ctx.fillText(STAGES[run.stageIdx].title+' — '+STAGES[run.stageIdx].name, x+16, cy); cy+=20;
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('SCORE', x+16, cy); ctx.textAlign='right'; ctx.fillStyle='#fff'; ctx.font='bold 15px monospace'; ctx.fillText(fmtScore(sessionScore), x+w-16, cy); ctx.textAlign='left'; cy+=22;
  // MUMU counter (compact — leaves room for the weapon/special/melee icon chips below)
  ctx.fillStyle='rgba(255,90,120,0.14)'; ctx.beginPath(); ctx.roundRect(x+12,cy-13,w-24,44,8); ctx.fill();
  ctx.fillStyle='#ff9ab0'; ctx.font='bold 10px monospace'; ctx.fillText('MUMUS EXTERMINATED', x+22, cy-1);
  ctx.fillStyle='#fff'; ctx.font='900 24px "Trebuchet MS"'; ctx.fillText(String(totalKills), x+22, cy+22);
  ctx.textAlign='right'; ctx.fillStyle='#ffd27a'; ctx.font='900 24px "Trebuchet MS"'; ctx.fillText(rankLetter(), x+w-22, cy+18); ctx.fillStyle='#c8b0c4'; ctx.font='9px monospace'; ctx.fillText('x'+scoreMult().toFixed(1), x+w-22, cy+29); ctx.textAlign='left';
  const toNext=KILL_EXTEND-(totalKills%KILL_EXTEND); ctx.fillStyle='#9fe0a4'; ctx.font='8px monospace'; ctx.fillText('♥ 1UP in '+toNext, x+w*0.5-6, cy+22);
  cy+=48;
  // POWER meter
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('POWER', x+16, cy); ctx.textAlign='right'; ctx.fillStyle='#ffd27a'; ctx.font='bold 12px monospace'; ctx.fillText('Lv'+shotLevel()+(shotLevel()>=5?' MAX':'  '+Math.round(Math.max(0,Math.min(1,(run.power-1)/5))*100)+'%'), x+w-16, cy); ctx.textAlign='left'; cy+=6;
  ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x+16,cy,w-32,9,3); ctx.fill();
  const pfrac=(run.power-1)/5, pw=(w-32)*pfrac; const pg=ctx.createLinearGradient(x+16,0,x+w-16,0); pg.addColorStop(0,'#ff6ec7'); pg.addColorStop(1,'#ffd27a'); ctx.fillStyle=pg; ctx.beginPath(); ctx.roundRect(x+16,cy,Math.max(0,pw),9,3); ctx.fill();
  // flames lick up off the filled bar — taller/hotter the more power she has
  if(pfrac>0.04 && pw>4){ ctx.save(); ctx.globalCompositeOperation='lighter';
    const nfl=Math.max(1,Math.floor(pw/6));
    for(let i=0;i<nfl;i++){ const fx=x+18+i*6, h=(2.5+pfrac*8)*(0.5+0.5*Math.abs(Math.sin(tick*0.32+i*1.2)));
      const fg=ctx.createLinearGradient(fx,cy,fx,cy-h); fg.addColorStop(0,`rgba(255,${(170-pfrac*90)|0},70,${0.5+pfrac*0.4})`); fg.addColorStop(1,'rgba(255,240,140,0)');
      ctx.fillStyle=fg; ctx.beginPath(); ctx.moveTo(fx-2.4,cy); ctx.quadraticCurveTo(fx,cy-h*0.7, fx+Math.sin(tick*0.2+i)*1.6,cy-h); ctx.quadraticCurveTo(fx,cy-h*0.7, fx+2.4,cy); ctx.closePath(); ctx.fill(); }
    ctx.restore(); }
  for(let i=1;i<5;i++){ const lx=x+16+(w-32)*(i/5); ctx.strokeStyle='rgba(0,0,0,0.4)'; ctx.beginPath(); ctx.moveTo(lx,cy); ctx.lineTo(lx,cy+9); ctx.stroke(); } cy+=20;
  // WEAPON row — only your Arsenal weapons, in loadout order (current highlighted; C to cycle)
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('WEAPON', x+16, cy);
  ctx.textAlign='right'; ctx.fillStyle=WEAPONS[run.weapon].col; ctx.font='bold 10px monospace'; ctx.fillText(WEAPONS[run.weapon].name, x+w-16, cy); ctx.textAlign='left'; cy+=6;
  let wx=x+16; for(const wk of run.weapons){ const cur=run.weapon===wk;
    ctx.fillStyle=cur?WEAPONS[wk].col:'#3a2a44'; ctx.beginPath(); ctx.roundRect(wx,cy,30,17,4); ctx.fill(); if(cur){ ctx.strokeStyle='#fff'; ctx.lineWidth=1.2; ctx.stroke(); }
    ctx.fillStyle=cur?'#1a0e14':'#d8c8e0'; ctx.font='bold 11px monospace'; ctx.textAlign='center'; ctx.fillText(WEAPONS[wk].icon, wx+15, cy+13); ctx.textAlign='left'; wx+=34; }
  if(run.weapons.length>1){ ctx.fillStyle='#6a5a72'; ctx.font='9px monospace'; ctx.textAlign='right'; ctx.fillText('[C] swap', x+w-14, cy+13); ctx.textAlign='left'; }
  cy+=28;
  // SPECIAL meter
  { const sp=armedSpec()||{col:'#6a5a72',icon:'—',name:'None'}, ready=run.special>=100;
    ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('SPECIAL', x+16, cy);
    ctx.textAlign='right'; ctx.fillStyle=sp.col; ctx.font='bold 10px monospace'; ctx.fillText(sp.icon+' '+sp.name, x+w-16, cy); ctx.textAlign='left'; cy+=6;
    ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x+16,cy,w-32,9,3); ctx.fill();
    ctx.fillStyle=sp.col; ctx.globalAlpha=ready?1:0.85; ctx.beginPath(); ctx.roundRect(x+16,cy,(w-32)*(run.special/100),9,3); ctx.fill(); ctx.globalAlpha=1;
    if(ready){ ctx.fillStyle=(Math.floor(tick/8)%2)?'#fff':sp.col; ctx.font='bold 8px monospace'; ctx.textAlign='center'; ctx.fillText('READY! [V]', x+16+(w-32)/2, cy+7.5); ctx.textAlign='left'; }
    cy+=18;
    if(run.specials && run.specials.length){ let sx=x+16; for(const sk of run.specials){ const s2=SPECIALS.find(s=>s.key===sk); if(!s2)continue; const cur=(sk===run.specials[run.armed]);   // icon chips (weapon-chip styling) — see which special is armed at a glance
      ctx.fillStyle=cur?s2.col:'#3a2a44'; ctx.beginPath(); ctx.roundRect(sx,cy,30,17,4); ctx.fill(); if(cur){ ctx.strokeStyle='#fff'; ctx.lineWidth=1.2; ctx.stroke(); }
      ctx.fillStyle=cur?'#1a0e14':'#d8c8e0'; ctx.font='bold 11px monospace'; ctx.textAlign='center'; ctx.fillText(s2.icon, sx+15, cy+13); ctx.textAlign='left'; sx+=34; }
      if(run.specials.length>1){ ctx.fillStyle='#6a5a72'; ctx.font='9px monospace'; ctx.textAlign='right'; ctx.fillText('[B] cycle', x+w-14, cy+13); ctx.textAlign='left'; } cy+=28; }
  }
  // MELEE row — current weapon + charge bar (SPACE swipe / hold to charge · D switch)
  { const m=MELEE[(player&&player.melee)||0]||MELEE[0];
    ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('MELEE', x+16, cy);
    ctx.textAlign='right'; ctx.fillStyle=m.col; ctx.font='bold 10px monospace'; ctx.fillText(m.name, x+w-16, cy); ctx.textAlign='left'; cy+=5;
    ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x+16,cy,w-32,5,2); ctx.fill();
    const chg=(player&&player.meleeHeld)?(player.meleeChg||0):0;
    if(chg>0){ ctx.fillStyle=chg>=1?'#fff':m.col; ctx.beginPath(); ctx.roundRect(x+16,cy,(w-32)*chg,5,2); ctx.fill(); }
    else { ctx.fillStyle='#6a5a72'; ctx.font='8px monospace'; ctx.textAlign='center'; ctx.fillText(isTouch?'MELEE btn: hold · MEL⇄ switch':'[SPACE] swipe · hold · [D] switch', x+16+(w-32)/2, cy+4.6); ctx.textAlign='left'; }
    cy+=13;
    if(run.melees && run.melees.length){ let mx=x+16; for(const mi of run.melees){ const m2=MELEE[mi]; if(!m2)continue; const cur=(mi===player.melee);   // melee icon chips (weapon-chip styling)
      ctx.fillStyle=cur?m2.col:'#3a2a44'; ctx.beginPath(); ctx.roundRect(mx,cy,30,17,4); ctx.fill(); if(cur){ ctx.strokeStyle='#fff'; ctx.lineWidth=1.2; ctx.stroke(); }
      ctx.fillStyle=cur?'#1a0e14':'#d8c8e0'; ctx.font='bold 11px monospace'; ctx.textAlign='center'; ctx.fillText(m2.icon, mx+15, cy+13); ctx.textAlign='left'; mx+=34; }
      if(run.melees.length>1){ ctx.fillStyle='#6a5a72'; ctx.font='9px monospace'; ctx.textAlign='right'; ctx.fillText('[D] switch', x+w-14, cy+13); ctx.textAlign='left'; } cy+=28; }
  }
  // CONSUMABLES row — icon chips matched to the weapon/special/melee chips (30×17, spacing 34); small qty badge; selected highlighted
  { if(selConsum>=arsenalI.length) selConsum=0; const cur=arsenalI.length?consumById(arsenalI[selConsum]):null; ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('ITEMS', x+16, cy);
    if(cur){ ctx.textAlign='right'; ctx.fillStyle=cur.col; ctx.font='bold 10px monospace'; ctx.fillText(cur.name, x+w-16, cy); ctx.textAlign='left'; } cy+=6;
    let ix=x+16; for(let i=0;i<arsenalI.length;i++){ const c=consumById(arsenalI[i]); if(!c)continue; const sel=i===selConsum, q=consumQty(c.key);
      ctx.globalAlpha=q>0?1:0.5; ctx.fillStyle=sel?c.col:'#3a2a44'; ctx.beginPath(); ctx.roundRect(ix,cy,30,17,4); ctx.fill(); if(sel){ ctx.strokeStyle='#fff'; ctx.lineWidth=1.2; ctx.stroke(); }
      if(c.draw){ ctx.save(); ctx.translate(ix+15, cy+9); c.draw(13); ctx.restore(); } else { ctx.fillStyle=sel?'#1a0e14':'#d8c8e0'; ctx.font='bold 11px monospace'; ctx.textAlign='center'; ctx.fillText(c.icon, ix+15, cy+13); }
      ctx.fillStyle=sel?'#1a0e14':'#9fe0a4'; ctx.font='bold 8px monospace'; ctx.textAlign='right'; ctx.fillText(q, ix+28, cy+7); ctx.textAlign='left'; ctx.globalAlpha=1; ix+=34; }
    if(!arsenalI.length){ ctx.fillStyle='#6a5a72'; ctx.font='9px monospace'; ctx.fillText('— none equipped —', x+16, cy+12); }
    const hp=(cur&&player&&player._eHeld&&!player._eUsed)?Math.min(1,(player._eT||0)/48):0;   // 0.8s hold
    if(hp>0){ ctx.fillStyle=cur.col; ctx.fillRect(x+16, cy+19, (arsenalI.length*34-4)*hp, 2.5); }
    else if(player&&player._eCd>0){ ctx.fillStyle='#6a5a72'; ctx.fillRect(x+16, cy+19, (arsenalI.length*34-4)*(player._eCd/180), 2.5); }   // 3s cooldown drains (grey)
    ctx.fillStyle='#6a5a72'; ctx.font='9px monospace'; ctx.textAlign='right'; ctx.fillText('['+keyName(binds.item_switch)+'] switch · hold ['+keyName(binds.item_use)+']', x+w-14, cy+13); ctx.textAlign='left'; cy+=30;
  }
  // lives
  // LIVES (hearts) + life-frag pips inline on the right
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('LIVES', x+16, cy); for(let i=0;i<Math.max(0,run.lives);i++){ drawHeart(x+56+i*14, cy-2.5, 5); }
  for(let i=0;i<5;i++){ ctx.fillStyle=i<run.lifeFrags?'#ff6ec7':'#3a2a40'; ctx.beginPath(); ctx.arc(x+w-56+i*9,cy-3.5,2.6,0,7); ctx.fill(); } cy+=18;
  // BOMBS + bomb-frag pips inline
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('BOMBS', x+16, cy); for(let i=0;i<run.bombs;i++){ ctx.fillStyle='#ff8ad6'; ctx.font='12px monospace'; ctx.fillText('✸', x+58+i*14, cy+1); }
  for(let i=0;i<3;i++){ ctx.fillStyle=i<run.bombFrags?'#ffd27a':'#3a2a40'; ctx.beginPath(); ctx.arc(x+w-38+i*9,cy-3.5,2.6,0,7); ctx.fill(); } cy+=18;
  // GRAZE + HEADS on one line
  ctx.fillStyle='#e8d6f0'; ctx.font='11px monospace'; ctx.fillText('GRAZE', x+16, cy); ctx.fillStyle='#8fd0ff'; ctx.font='bold 12px monospace'; ctx.fillText(String(graze), x+58, cy);
  ctx.textAlign='right'; ctx.fillStyle='#ffd27a'; ctx.font='bold 12px monospace'; ctx.fillText('💀 '+mumuHeads, x+w-16, cy); ctx.textAlign='left'; cy+=18;
  // active buff chips
  if(player && (player.shieldT>0 || player.rapidT>0)){ let bx=x+16; ctx.font='bold 10px monospace';
    if(player.shieldT>0){ ctx.fillStyle='rgba(232,168,96,0.95)'; ctx.beginPath(); ctx.roundRect(bx,cy-9,86,14,4); ctx.fill(); ctx.fillStyle='#2a1606'; ctx.fillText('🐻 BOBO '+Math.ceil(player.shieldT/60)+'s', bx+5, cy+1); bx+=92; }
    if(player.rapidT>0){ ctx.fillStyle='rgba(255,225,74,0.95)'; ctx.beginPath(); ctx.roundRect(bx,cy-9,84,14,4); ctx.fill(); ctx.fillStyle='#2a2200'; ctx.fillText('🦍 MONKE '+Math.ceil(player.rapidT/60)+'s', bx+5, cy+1); }
    cy+=16;
  }
  // boss bar or progress
  if(boss && !boss.dead && boss.intro<=0){
    ctx.fillStyle=boss.data.color; ctx.font='bold 13px "Trebuchet MS"'; ctx.fillText(boss.hudName||boss.data.name, x+16, cy); cy+=6;
    const bw=w-32; ctx.fillStyle='#3a1020'; ctx.beginPath(); ctx.roundRect(x+16,cy,bw,10,3); ctx.fill();
    const g=ctx.createLinearGradient(x+16,0,x+16+bw,0); g.addColorStop(0,'#ff3b30'); g.addColorStop(1,boss.data.color); ctx.fillStyle=g; ctx.beginPath(); ctx.roundRect(x+16,cy,bw*Math.max(0,boss.hp/boss.maxhp),10,3); ctx.fill(); cy+=15;
    if(boss.twin){ const o=boss.active==='igor'?'grichka':'igor', of=boss.tw[o].done?0:boss.tw[o].hp/boss.tw[o].max; ctx.fillStyle='#241633'; ctx.beginPath(); ctx.roundRect(x+16,cy,bw,5,2); ctx.fill(); ctx.fillStyle=boss.tw[o].done?'#4a4a55':'#9d6bff'; ctx.beginPath(); ctx.roundRect(x+16,cy,bw*of,5,2); ctx.fill(); ctx.fillStyle='#b8a0d0'; ctx.font='8px monospace'; ctx.textAlign='right'; ctx.fillText((o==='igor'?'Igor':'Grichka')+(boss.tw[o].done?' ✕ down':''), x+16+bw, cy-2); ctx.textAlign='left'; cy+=8; }
    else for(let i=0;i<boss.phases;i++){ ctx.fillStyle=i<=boss.phase?'#ffd27a':'#5a4a55'; ctx.beginPath(); ctx.arc(x+22+i*16,cy+4,4,0,7); ctx.fill(); }
  } else {
    const prog=Math.min(1,stageTime/STAGES[run.stageIdx].waveDur);
    ctx.fillStyle='#c8b0c4'; ctx.font='11px monospace'; ctx.fillText('STAGE PROGRESS', x+16, cy); cy+=6;
    ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(x+16,cy,w-32,8,3); ctx.fill(); ctx.fillStyle='#8fd35a'; ctx.beginPath(); ctx.roundRect(x+16,cy,(w-32)*prog,8,3); ctx.fill();
  }
  ctx.fillStyle='#6a5a72'; ctx.font='10px monospace';
  if(isTouch){ ctx.fillText('Stick moves · FIRE toggles auto-shoot', x+16, PANEL.h-30); ctx.fillText('MELEE · SPEC · BOMB · FOCUS (2× = dash)', x+16, PANEL.h-18); }
  else { ctx.fillText('Mouse/arrows move · HOLD Z fire', x+16, PANEL.h-30); ctx.fillText('SHIFT focus · X bomb · C swap', x+16, PANEL.h-18); }
  if(difficulty>0||ngPlus>0){ ctx.fillStyle=difficulty>=2?'#ff2a2a':'#ff5b6e'; ctx.font='bold 10px monospace'; ctx.fillText('★ '+modeTag()+' MODE', x+16, PANEL.h-44); }
}
