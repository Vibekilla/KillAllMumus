function drawClearGate(){ const t=tick;
  if(clearPortal){ const px=clearPortal.x, py=clearPortal.y;
    const nS=STAGES[run.stageIdx+1]||{}, nb=nS.boss||{}, bc=(STAGES[run.stageIdx]&&STAGES[run.stageIdx].accent)||'#9a6cff';   // portal tinted to the CURRENT stage's theme (so it matches its surroundings); still labelled with what's beyond
    const nearP=player&&Math.hypot(player.x-px,player.y-py)<44, pulse=0.5+0.5*Math.sin(t*0.09);
    ctx.save(); ctx.translate(px,py);
    // ominous dark aura pooling on the ground, in the next boss's colour
    const og=ctx.createRadialGradient(0,0,6,0,0,66); og.addColorStop(0,_hexA(bc,0.55)); og.addColorStop(0.45,_hexA(bc,0.18)); og.addColorStop(1,_hexA(bc,0));
    ctx.fillStyle=og; ctx.beginPath(); ctx.ellipse(0,2,66,58,0,0,7); ctx.fill();
    // creeping shadow tendrils writhing out of the gate
    ctx.strokeStyle=_hexA('#05030a',0.65); ctx.lineWidth=3; ctx.lineCap='round';
    for(let a=0;a<7;a++){ const an=a/7*6.283+t*0.004; ctx.beginPath(); ctx.moveTo(Math.cos(an)*20,Math.sin(an)*17); ctx.quadraticCurveTo(Math.cos(an+0.2)*40,Math.sin(an+0.2)*34, Math.cos(an+0.4)*56, Math.sin(an+0.4)*48); ctx.stroke(); }
    // swirling vortex energy (additive)
    ctx.globalCompositeOperation='lighter';
    for(let a=0;a<5;a++){ ctx.strokeStyle=_hexA(bc,0.55); ctx.lineWidth=2.6; ctx.beginPath(); for(let s=0;s<=1;s+=0.045){ const rr=s*38, an=t*0.055+a*1.257+s*8.5, x=Math.cos(an)*rr, y=Math.sin(an)*rr*0.85; s?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.stroke(); }
    // jagged energy crackle firing out of the core
    ctx.strokeStyle=_hexA(bc,0.5+0.4*pulse); ctx.lineWidth=1.6;
    for(let a=0;a<4;a++){ let ang=t*0.02+a*1.57, rr=2; ctx.beginPath(); ctx.moveTo(0,0); for(let k=0;k<5;k++){ rr+=7; ang+=Math.sin(t*0.11+a*2+k)*1.0; ctx.lineTo(Math.cos(ang)*rr,Math.sin(ang)*rr*0.85);} ctx.stroke(); }
    ctx.globalCompositeOperation='source-over';
    // glowing rim ring + dark void core
    ctx.strokeStyle=_hexA(bc,0.9); ctx.lineWidth=2.4+pulse*2; ctx.beginPath(); ctx.ellipse(0,0,26,22,0,0,7); ctx.stroke();
    const vg=ctx.createRadialGradient(0,0,1,0,0,24); vg.addColorStop(0,'#000'); vg.addColorStop(0.62,'#080512'); vg.addColorStop(1,_hexA(bc,0.6));
    ctx.fillStyle=vg; ctx.beginPath(); ctx.ellipse(0,0,24,20,0,0,7); ctx.fill();
    // inner sucking swirl + rising embers
    ctx.globalCompositeOperation='lighter'; ctx.strokeStyle=_hexA(bc,0.5); ctx.lineWidth=1.4; ctx.beginPath(); for(let s=0;s<=1;s+=0.05){ const rr=s*20, an=-t*0.09+s*10, x=Math.cos(an)*rr, y=Math.sin(an)*rr*0.85; s?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.stroke();
    ctx.fillStyle=_hexA(bc,0.85); for(let i=0;i<6;i++){ const ph=(t*0.9+i*40)%120, yy=20-ph*0.5, xx=Math.sin(t*0.03+i*1.7)*18*(1-ph/120); ctx.globalAlpha=Math.max(0,1-ph/120)*0.9; ctx.beginPath(); ctx.arc(xx,yy,1.6,0,7); ctx.fill(); } ctx.globalAlpha=1;
    ctx.globalCompositeOperation='source-over'; ctx.restore();
    // labels — what's on the far side + the interact prompt (no auto-enter)
    ctx.textAlign='center';
    ctx.fillStyle=_hexA(bc,0.95); ctx.font='bold 10px monospace'; ctx.fillText('▼ BEYOND: '+String(nS.name||'???').toUpperCase(), px, py-46);
    if(nb.title){ ctx.fillStyle='rgba(255,255,255,0.5)'; ctx.font='9px "Trebuchet MS"'; ctx.fillText('“'+nb.title+'” awaits', px, py-34); }
    if(nearP){ ctx.fillStyle=(Math.floor(t/16)%2)?'#fff':bc; ctx.font='bold 12px monospace'; ctx.fillText('['+kb('interact')+'] ENTER PORTAL', px, py+48); }
    ctx.textAlign='left';
  }
  if(clearShop){ const sx=clearShop.x, sy=clearShop.y, near=player&&Math.hypot(player.x-sx,player.y-sy)<40; ctx.save(); ctx.translate(sx,sy);
    const g=ctx.createRadialGradient(0,-4,2,0,-4,40); g.addColorStop(0,'rgba(255,180,90,0.42)'); g.addColorStop(1,'rgba(255,180,90,0)'); ctx.fillStyle=g; ctx.beginPath(); ctx.arc(0,-4,40,0,7); ctx.fill();
    ctx.fillStyle='#3a2416'; ctx.beginPath(); ctx.roundRect(-21,-27,42,37,4); ctx.fill();
    ctx.fillStyle='#2a1810'; ctx.beginPath(); ctx.roundRect(-21,-27,42,8,3); ctx.fill();
    ctx.fillStyle='#1c0f06'; ctx.beginPath(); ctx.roundRect(-10,-12,20,22,3); ctx.fill();
    ctx.fillStyle='#c0392b'; for(let i=-21;i<20;i+=7){ ctx.beginPath(); ctx.moveTo(i,-27); ctx.lineTo(i+3.5,-33); ctx.lineTo(i+7,-27); ctx.closePath(); ctx.fill(); }
    ctx.font='14px serif'; ctx.textAlign='center'; ctx.fillText('🍯',0,-29); ctx.restore();
    ctx.fillStyle='#ffd27a'; ctx.font='bold 10px monospace'; ctx.textAlign='center'; ctx.fillText('SHOP', sx, sy-38);
    if(near){ ctx.fillStyle=(Math.floor(t/16)%2)?'#fff':'#ffd27a'; ctx.font='bold 11px monospace'; ctx.fillText('['+kb('interact')+'] ENTER', sx, sy+30); } ctx.textAlign='left'; }
  if(clearMsgT>0){ ctx.save(); ctx.globalAlpha=Math.min(1,clearMsgT/40); ctx.textAlign='center'; const mcx=PF.x+PF.w/2;
    ctx.fillStyle='#ffe08a'; ctx.font='900 18px "Trebuchet MS"'; ctx.fillText('★ STAGE CLEAR ★', mcx, PF.y+22);
    ctx.fillStyle='#ffd27a'; ctx.font='bold 11px "Trebuchet MS"'; ctx.fillText('Shop ['+kb('interact')+'] to gear up  ·  Portal ['+kb('interact')+'] when ready', mcx, PF.y+40);
    ctx.textAlign='left'; ctx.restore(); }
}
