function drawArsenal(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#101828'); g.addColorStop(1,'#1a1020'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  ctx.textAlign='center';
  ctx.save(); ctx.shadowColor='#7fdfff'; ctx.shadowBlur=14; ctx.fillStyle='#bff0ff'; ctx.font='900 24px "Trebuchet MS"'; ctx.fillText('🎒 ARSENAL', W/2, 30); ctx.restore();
  arsenalTiles=[];
  // ---- tabs ----
  const tabs=[['w','WEAPONS','#ff8ac0','['+kb('swap')+'] cycles these in a run'],['s','SPECIALS','#b98cff','['+kb('special')+'] use · ['+kb('cycle')+'] cycles these'],['m','MELEE','#ff8a6a','['+kb('melee')+'] swipe · ['+kb('meleeswap')+'] cycles these'],['i','ITEMS','#ffd27a','['+kb('item_switch')+'] switch · hold ['+kb('item_use')+'] to use']];
  const tabW=142, tabGap=10, tabsW=tabs.length*tabW+(tabs.length-1)*tabGap, tabX0=W/2-tabsW/2, tabY=42, tabH=30;
  for(let i=0;i<tabs.length;i++){ const [tk,tlabel,tcol]=tabs[i], tx=tabX0+i*(tabW+tabGap), on=arsTab===tk;
    ctx.fillStyle=on?tcol:'rgba(255,255,255,0.05)'; ctx.beginPath(); ctx.roundRect(tx,tabY,tabW,tabH,9); ctx.fill();
    ctx.strokeStyle=on?'#fff':'rgba(255,255,255,0.16)'; ctx.lineWidth=on?2:1; ctx.stroke();
    ctx.fillStyle=on?'#141018':'#c8b0d0'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText(tlabel + '  '+arsArr(tk).length+'/'+ARS_CAP[tk], tx+tabW/2, tabY+20);
    arsenalTiles.push({x:tx,y:tabY,w:tabW,h:tabH,tab:tk}); }
  const type=arsTab, arr=arsArr(type), cap=ARS_CAP[type], accent=(type==='w'?'#ff8ac0':type==='s'?'#b98cff':type==='m'?'#ff8a6a':'#ffd27a'), hint=tabs.find(t=>t[0]===type)[3];
  const dragging=(k)=> arsDrag && arsDrag.moved && arsDrag.key===k;
  // ---- HOTBAR (ordered loadout slots) ----
  ctx.textAlign='center'; ctx.fillStyle=accent; ctx.font='bold 12px monospace';
  ctx.fillText('YOUR LOADOUT  ·  drag items into the slots to equip & order  ·  tap a slot to remove  ·  '+hint, W/2, 92);
  const slotW=Math.min(130,(W-100-(cap-1)*14)/cap), slotH=66, sTotW=cap*slotW+(cap-1)*14, sX0=W/2-sTotW/2, sY=104;
  for(let i=0;i<cap;i++){ const sx=sX0+i*(slotW+14), key=arr[i], over=arsDrag&&arsDrag.moved&&inBtn({x:arsDrag.x,y:arsDrag.y},{x:sx,y:sY,w:slotW,h:slotH});
    ctx.fillStyle='rgba(255,255,255,0.035)'; ctx.beginPath(); ctx.roundRect(sx,sY,slotW,slotH,11); ctx.fill();
    ctx.strokeStyle=over?'#fff':'rgba(255,255,255,0.2)'; ctx.lineWidth=over?2.6:1.4; ctx.setLineDash(over?[]:[5,4]); ctx.stroke(); ctx.setLineDash([]);
    ctx.fillStyle=accent; ctx.font='bold 9px monospace'; ctx.textAlign='left'; ctx.fillText('#'+(i+1), sx+7, sY+13);
    if(key){ const it=arsItemByKey(type,key); if(it){ ctx.globalAlpha=dragging(key)&&arsDrag.from==='hotbar'?0.3:1;
      ctx.fillStyle='rgba(255,210,120,0.12)'; ctx.beginPath(); ctx.roundRect(sx+2,sY+2,slotW-4,slotH-4,9); ctx.fill();
      ctx.strokeStyle=it.col||accent; ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(sx+2,sY+2,slotW-4,slotH-4,9); ctx.stroke();
      if(it.draw){ ctx.save(); ctx.translate(sx+slotW/2, sY+23); it.draw(24); ctx.restore(); } else { ctx.fillStyle='#fff'; ctx.font='26px serif'; ctx.textAlign='center'; ctx.fillText(it.icon, sx+slotW/2, sY+34); }
      ctx.textAlign='center'; ctx.fillStyle='#ffe6b0'; let nfs=10; ctx.font='bold '+nfs+'px "Trebuchet MS"'; while(ctx.measureText(it.name).width>slotW-10&&nfs>6.5){ nfs-=0.5; ctx.font='bold '+nfs+'px "Trebuchet MS"'; } ctx.fillText(it.name, sx+slotW/2, sY+52);
      if(type==='i'){ ctx.fillStyle='#9fe0a4'; ctx.font='900 9px monospace'; ctx.textAlign='right'; ctx.fillText('×'+consumQty(key), sx+slotW-6, sY+14); ctx.textAlign='center'; }   // owned quantity
      ctx.globalAlpha=1; arsenalTiles.push({x:sx,y:sY,w:slotW,h:slotH,type,key,hotbarSlot:i,fromHot:true}); } }
    else { ctx.fillStyle='#46566a'; ctx.font='26px monospace'; ctx.textAlign='center'; ctx.fillText('+', sx+slotW/2, sY+slotH/2+10); arsenalTiles.push({x:sx,y:sY,w:slotW,h:slotH,type,hotbarSlot:i,emptySlot:true}); }
  }
  // ---- POOL (available items) ----
  const tile=(x,y,w,h,icon,name,desc,sel,accentC,drawFn)=>{
    ctx.fillStyle=sel?'rgba(255,210,120,0.14)':'rgba(255,255,255,0.04)'; ctx.beginPath(); ctx.roundRect(x,y,w,h,9); ctx.fill();
    ctx.strokeStyle=sel?accentC:'rgba(255,255,255,0.14)'; ctx.lineWidth=sel?2.2:1.1; ctx.stroke();
    if(drawFn){ ctx.save(); ctx.translate(x+18,y+15); drawFn(19); ctx.restore(); } else { ctx.textAlign='left'; ctx.font='20px serif'; ctx.fillStyle='#fff'; ctx.fillText(icon, x+9, y+24); }
    ctx.fillStyle=sel?'#ffe08a':'#e6d8f0'; let nfs=11.5; const avail=w-52; ctx.font='bold '+nfs+'px "Trebuchet MS"';
    while(ctx.measureText(name).width>avail && nfs>7){ nfs-=0.5; ctx.font='bold '+nfs+'px "Trebuchet MS"'; } ctx.fillText(name, x+37, y+18);
    ctx.fillStyle='#b8a8c8'; ctx.font='8.5px monospace'; wrapText(desc||'', x+10, y+34, w-18, 9);
    if(sel){ ctx.fillStyle=accentC; ctx.textAlign='right'; ctx.font='bold 14px monospace'; ctx.fillText('✓', x+w-8, y+18); }
    ctx.textAlign='left';
  };
  ctx.textAlign='left'; ctx.fillStyle='#c8b0d0'; ctx.font='bold 11px monospace'; ctx.fillText('AVAILABLE  —  tap or drag into a slot above', 40, sY+slotH+26);
  const pool=arsPool(type), pCols=(type==='s'?4:5), pGap=8, pX0=30, pTW=(W-60-(pCols-1)*pGap)/pCols, pY0=sY+slotH+34, pTH=(type==='s'?82:86), pRG=9;   // roomier tiles (~15% more space) so icons + wrapped text breathe
  for(let i=0;i<pool.length;i++){ const it=pool[i], r=Math.floor(i/pCols), c=i%pCols, px=pX0+c*(pTW+pGap), py=pY0+r*(pTH+pRG), sel=arr.includes(it.key);
    ctx.globalAlpha=(dragging(it.key)&&arsDrag.from==='pool')?0.3:(it.locked?0.5:1);
    tile(px,py,pTW,pTH, it.icon, it.name, it.desc, sel, it.col||accent, it.draw);
    if(it.locked){ ctx.globalAlpha=1; ctx.fillStyle='rgba(10,6,16,0.45)'; ctx.beginPath(); ctx.roundRect(px,py,pTW,pTH,10); ctx.fill();
      ctx.font='18px serif'; ctx.textAlign='center'; ctx.fillText('🔒', px+pTW-15, py+21);
      ctx.fillStyle='#ffd27a'; ctx.font='bold 9px monospace'; ctx.fillText('💀 '+lockCost(type,it.key)+' · SHOP', px+pTW/2, py+pTH-6); ctx.textAlign='left'; }
    if(type==='i'){ ctx.globalAlpha=1; ctx.fillStyle='#9fe0a4'; ctx.font='900 10px monospace'; ctx.textAlign='right'; ctx.fillText('×'+consumQty(it.key), px+pTW-8, py+pTH-7); ctx.textAlign='left'; }   // owned quantity
    ctx.globalAlpha=1; arsenalTiles.push({x:px,y:py,w:pTW,h:pTH,type,key:it.key,pool:true,locked:it.locked}); }
  // ---- drag ghost ----
  if(arsDrag && arsDrag.moved && arsDrag.key){ const it=arsItemByKey(type,arsDrag.key);
    if(it){ ctx.save(); ctx.globalAlpha=0.92; ctx.fillStyle='rgba(34,22,50,0.96)'; ctx.strokeStyle='#fff'; ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(arsDrag.x-30,arsDrag.y-19,60,38,9); ctx.fill(); ctx.stroke(); ctx.fillStyle='#fff'; ctx.font='24px serif'; ctx.textAlign='center'; ctx.fillText(it.icon, arsDrag.x, arsDrag.y+8); ctx.textAlign='left'; ctx.restore(); } }
  if(arsMsg){ arsMsg.t--; ctx.save(); ctx.globalAlpha=Math.min(1,arsMsg.t/24); ctx.textAlign='center'; ctx.fillStyle='#ff9aa8'; ctx.font='bold 14px "Trebuchet MS"'; ctx.fillText(arsMsg.txt, W/2, H-26); ctx.restore(); if(arsMsg.t<=0) arsMsg=null; }
  ctx.textAlign='center'; ctx.fillStyle=(Math.floor(tick/30)%2)?'#fff':'#9a7c96'; ctx.font='bold 13px monospace'; ctx.fillText('PRESS '+kb('shoot')+' / TAP EMPTY AREA TO '+(arsenalReturn==='stageclear'?'RESUME':'RETURN'), W/2, H-8); ctx.textAlign='left';
}
