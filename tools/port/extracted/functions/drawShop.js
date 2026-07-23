function drawShop(){ const t=tick; if(shopMsgT>0)shopMsgT--; shopBtns=[];
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#2a1c12'); g.addColorStop(1,'#150d07'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  ctx.textAlign='center'; ctx.save(); ctx.shadowColor='#ffd27a'; ctx.shadowBlur=12; ctx.fillStyle='#ffe08a'; ctx.font='900 24px "Trebuchet MS"'; ctx.fillText("HONEY BADGER'S SHOP", W/2, 30); ctx.restore();
  ctx.fillStyle='#241810'; ctx.beginPath(); ctx.roundRect(W-176,10,158,24,8); ctx.fill(); ctx.strokeStyle='#ffd27a'; ctx.lineWidth=1.4; ctx.stroke();
  ctx.fillStyle='#ffd27a'; ctx.font='bold 14px monospace'; ctx.textAlign='left'; ctx.fillText('💀 '+mumuHeads+' HEADS', W-166, 27);
  // tabs
  const tabs=[['w','WEAPONS','#ff8ac0'],['s','SPECIALS','#b98cff'],['m','MELEE','#ff8a6a'],['i','ITEMS','#ffd27a']];
  const tw=150, tg=10, tot=tabs.length*tw+(tabs.length-1)*tg, tx0=W/2-tot/2, ty=42, thh=28;
  for(let i=0;i<tabs.length;i++){ const [tk,tl,tc]=tabs[i], tx=tx0+i*(tw+tg), on=shopTab===tk;
    ctx.fillStyle=on?tc:'rgba(255,255,255,0.05)'; ctx.beginPath(); ctx.roundRect(tx,ty,tw,thh,8); ctx.fill(); ctx.strokeStyle=on?'#fff':'rgba(255,255,255,0.16)'; ctx.lineWidth=on?2:1; ctx.stroke();
    ctx.fillStyle=on?'#141018':'#c8b0d0'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText(tl, tx+tw/2, ty+19); shopBtns.push({x:tx,y:ty,w:tw,h:thh,tab:tk}); }
  // catalogue grid for the current tab
  const list=shopList(shopTab); if(shopSel>=list.length)shopSel=list.length-1; if(shopSel<0)shopSel=0;
  const cols=(shopTab==='s'?4:(shopTab==='i'&&W>=800?6:5)), gap=8, gx=18, tW=(W-2*gx-(cols-1)*gap)/cols, gy=80, rg=9;
  const rows=Math.max(1,Math.ceil(list.length/cols)), gridBot=H-206, tHwant=(shopTab==='i'?104:78);   // keep the ENTIRE grid above Honey Badger's portrait + dialogue bar
  const tH=Math.min(tHwant, Math.floor((gridBot-gy-(rows-1)*rg)/rows));   // shrink tiles only if a tab needs extra rows, so nothing ever falls behind him
  for(let i=0;i<list.length;i++){ const it=list[i], c=i%cols, r=Math.floor(i/cols), cx=gx+c*(tW+gap), cy=gy+r*(tH+rg), sel=i===shopSel;
    const owned=it.kind==='gear'&&it.owned, afford=mumuHeads>=it.cost;
    ctx.globalAlpha=owned?0.55:1;
    ctx.fillStyle=sel?'rgba(255,210,120,0.16)':'rgba(255,255,255,0.045)'; ctx.beginPath(); ctx.roundRect(cx,cy,tW,tH,9); ctx.fill();
    ctx.strokeStyle=sel?'#ffd27a':(it.col?_hexA(it.col,0.4):'rgba(255,255,255,0.14)'); ctx.lineWidth=sel?2.2:1.1; ctx.stroke();
    if(it.draw){ ctx.save(); ctx.translate(cx+18,cy+15); it.draw(19); ctx.restore(); } else { ctx.textAlign='left'; ctx.font='20px serif'; ctx.fillStyle='#fff'; ctx.fillText(it.icon, cx+9, cy+24); }
    ctx.textAlign='left'; ctx.fillStyle=sel?'#ffe08a':'#e6d8f0'; ctx.font='bold 11.5px "Trebuchet MS"'; ctx.fillText(it.name.slice(0,18), cx+36, cy+17);
    ctx.fillStyle='#b8a8c8'; ctx.font='8.5px monospace'; wrapText(it.desc, cx+10, cy+33, tW-16, 9);
    ctx.textAlign='right';
    if(it.kind==='consumable'){ ctx.fillStyle='#9fe0a4'; ctx.font='bold 9px monospace'; ctx.fillText('HAVE ×'+it.qty, cx+tW-9, cy+tH-18); ctx.fillStyle=afford?'#bff0a0':'#ff9a9a'; ctx.font='bold 11px monospace'; ctx.fillText('💀 '+it.cost, cx+tW-9, cy+tH-6); }
    else if(owned){ ctx.fillStyle='#8fd0a0'; ctx.font='bold 10px monospace'; ctx.fillText('✓ OWNED', cx+tW-9, cy+tH-7); }
    else if(it.cost>0){ ctx.fillStyle=afford?'#bff0a0':'#ff9a9a'; ctx.font='bold 11px monospace'; ctx.fillText('💀 '+it.cost, cx+tW-9, cy+tH-7); }
    else { ctx.fillStyle='#9a8aa2'; ctx.font='bold 8.5px monospace'; ctx.fillText('🏅 EMBLEM', cx+tW-9, cy+tH-7); }
    ctx.textAlign='left'; ctx.globalAlpha=1; shopBtns.push({x:cx,y:cy,w:tW,h:tH,i}); }
  // bottom: Honey Badger — big transparent portrait + a boss-style dialogue bar with rotating, in-character lines
  { const hb=IMG.honeybadger, iw=216, ih=Math.round(iw*473/527), ix=4, iy=H-4-ih;
    if(imgOK(hb)) ctx.drawImage(hb, ix, iy, iw, ih);   // transparent PNG — no frame; he stands in the corner
    else drawHoneyBadger(66, H-64, 0.66);
    // dialogue box styled like the boss / Bobina bar (dark panel, amber stroke, name + title + quoted line)
    const dx=230, dw=W-dx-14, dh=64, dy=H-172;
    ctx.fillStyle='rgba(20,12,6,0.92)'; ctx.beginPath(); ctx.roundRect(dx,dy,dw,dh,8); ctx.fill();
    ctx.strokeStyle='#ffb347'; ctx.lineWidth=2; ctx.save(); ctx.shadowColor='#ff9a2a'; ctx.shadowBlur=12; ctx.stroke(); ctx.restore();
    ctx.textAlign='left';
    ctx.fillStyle='#ffd27a'; ctx.font='bold 15px "Trebuchet MS"'; ctx.fillText('Honey Badger', dx+18, dy+24);
    ctx.fillStyle='#c8a878'; ctx.font='italic 12px "Trebuchet MS"'; ctx.fillText('Reality-Bending Merchant', dx+18, dy+40);
    ctx.fillStyle='#fff'; ctx.font='bold 14px "Trebuchet MS"'; ctx.fillText('“'+HONEY_LINES[Math.floor(t/220)%HONEY_LINES.length]+'”', dx+18, dy+58); }
  if(shopMsgT>0){ ctx.globalAlpha=Math.min(1,shopMsgT/20); const bad=/^(Not|Already|Earn)/.test(shopMsg); ctx.fillStyle=bad?'#ff9aa8':'#9fe0a4'; ctx.font='bold 14px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText(shopMsg, W*0.63, H-96); ctx.globalAlpha=1; }
  const sit=list[shopSel]; if(sit){ let hint, act=false; if(sit.kind==='gear'&&sit.owned) hint='✓ Already owned'; else if(sit.kind==='gear'&&sit.cost<=0) hint='🏅 Unlock this via its Emblem'; else if(mumuHeads>=sit.cost){ hint='['+kb('shoot')+'] / tap again to BUY — '+sit.name; act=true; } else hint='need '+(sit.cost-mumuHeads)+' more heads';
    ctx.fillStyle=act?((Math.floor(t/16)%2)?'#fff':'#ffd27a'):'#a07a7a'; ctx.font='bold 12px monospace'; ctx.textAlign='center'; ctx.fillText(hint, W*0.63, H-62); }
  ctx.fillStyle=(Math.floor(t/26)%2)?'#fff':'#9a7c96'; ctx.font='bold 12px monospace'; ctx.textAlign='center'; ctx.fillText('◀▶ browse  ·  ['+kb('swap')+'] switch tab  ·  ['+kb('shoot')+'] buy  ·  ['+kb('interact')+'] LEAVE → stage clear', W*0.63, H-32); ctx.textAlign='left';
}
