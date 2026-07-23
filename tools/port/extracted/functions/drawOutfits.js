function drawOutfits(){
  outfitTiles=[]; outfitPoseBtn=null; outfitBackBtn=null; outfitAnimT++;
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#1a0e26'); g.addColorStop(1,'#28121e'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  const unlockedN=OUTFITS.filter(o=>outfitUnlocked(o.key)).length;
  ctx.textAlign='center';
  ctx.save(); ctx.shadowColor='#ff9ecb'; ctx.shadowBlur=16; ctx.fillStyle='#ffd6ea'; ctx.font='900 32px "Trebuchet MS"'; ctx.fillText('👗 OUTFITS', W/2, 40); ctx.restore();
  ctx.fillStyle='#c8b0d0'; ctx.font='12px monospace'; ctx.fillText('Wardrobe · '+unlockedN+' / '+OUTFITS.length+' unlocked · tap a skin to equip · unlock more via 🏅 Emblems', W/2, 60);
  // ===== preview stage (right) =====
  const pvX=W-330, pvY=78, pvW=310, pvH=H-78-16;
  const pg=ctx.createLinearGradient(0,pvY,0,pvY+pvH); pg.addColorStop(0,'#241033'); pg.addColorStop(1,'#140a1c'); ctx.fillStyle=pg; ctx.beginPath(); ctx.roundRect(pvX,pvY,pvW,pvH,14); ctx.fill();
  ctx.strokeStyle='rgba(255,150,205,0.45)'; ctx.lineWidth=2; ctx.stroke();
  ctx.save(); ctx.beginPath(); ctx.roundRect(pvX,pvY,pvW,pvH,14); ctx.clip();
  const pcx=pvX+pvW/2, t=tick;
  // spotlight cone + floor shimmer
  const spot=ctx.createRadialGradient(pcx,pvY+40,10,pcx,pvY+220,220); spot.addColorStop(0,'rgba(255,190,235,0.26)'); spot.addColorStop(1,'rgba(255,190,235,0)');
  ctx.fillStyle=spot; ctx.beginPath(); ctx.moveTo(pcx-40,pvY+10); ctx.lineTo(pcx+40,pvY+10); ctx.lineTo(pcx+150,pvY+pvH); ctx.lineTo(pcx-150,pvY+pvH); ctx.closePath(); ctx.fill();
  const figCy=pvY+pvH*0.47, figScale=4.7, feetY=figCy+figScale*22;
  ctx.fillStyle='rgba(255,120,190,0.16)'; ctx.beginPath(); ctx.ellipse(pcx,feetY,90,18,0,0,7); ctx.fill();
  // floating notes/hearts
  for(let i=0;i<8;i++){ const base=(t*0.7+i*80); const ny=pvY+20+(((pvH-70)-(base%(pvH-70)))); const nx=pcx+Math.sin(t*0.03+i*1.3)*(60+i*9); ctx.globalAlpha=0.45+0.3*Math.sin(t*0.1+i);
    ctx.fillStyle=['#ff9ecb','#ffd27a','#8fd0ff','#b8f08a'][i%4]; ctx.font='bold '+(14+i%3*4)+'px monospace'; ctx.textAlign='center'; ctx.fillText(['♪','♫','♥','✦','♬'][i%5], nx, ny); }
  ctx.globalAlpha=1;
  drawOutfitFigure(pcx, figCy, figScale, t);
  ctx.restore();
  // preview labels
  const po=OUTFITS.find(o=>o.key===outfitPreview)||OUTFITS[0], pUnl=outfitUnlocked(outfitPreview);
  ctx.textAlign='center'; ctx.fillStyle='#fff'; ctx.font='900 22px "Trebuchet MS"'; ctx.fillText((OUTFIT_EMOJI[outfitPreview]||'👗')+' '+po.name, pcx, pvY+34);
  const equipped=(outfitPreview===selectedOutfit);
  ctx.font='bold 12px monospace';
  ctx.fillStyle = equipped?'#8fd0a0' : pUnl?'#ffd27a' : '#ff7a9a';
  ctx.fillText(equipped?'✓ EQUIPPED' : pUnl?'tap tile to equip' : '🔒 locked — earn its Emblem', pcx, pvY+52);
  // victory-pose controls — pick the POSE (motion) and the FACE (expression) for her stage-clear celebration
  { const bw=204,bh=27,bx=pcx-bw/2, byF=pvY+pvH-77, byP=pvY+pvH-42;
    ctx.fillStyle='#c8b0d0'; ctx.font='9px monospace'; ctx.textAlign='center'; ctx.fillText('★ YOUR STAGE-CLEAR VICTORY POSE', pcx, byF-7);
    faceBtn={x:bx,y:byF,w:bw,h:bh};   // FACE (expression) toggle
    ctx.fillStyle='rgba(140,200,255,0.14)'; ctx.beginPath(); ctx.roundRect(bx,byF,bw,bh,9); ctx.fill(); ctx.strokeStyle='#8fd0ff'; ctx.lineWidth=1.5; ctx.stroke();
    ctx.fillStyle='#d8ecff'; ctx.font='bold 12px "Trebuchet MS"'; ctx.fillText('☺ FACE:  '+VICTORY_FACES[victoryFace].name, pcx, byF+18);
    outfitPoseBtn={x:bx,y:byP,w:bw,h:bh};   // POSE (motion) toggle
    ctx.fillStyle='rgba(255,140,200,0.16)'; ctx.beginPath(); ctx.roundRect(bx,byP,bw,bh,9); ctx.fill(); ctx.strokeStyle='#ff9ecb'; ctx.lineWidth=1.5; ctx.stroke();
    ctx.fillStyle='#ffd6ea'; ctx.font='bold 12px "Trebuchet MS"'; ctx.fillText('↻ POSE:  '+OUTFIT_POSES[outfitPose].name, pcx, byP+18); }
  // ===== grid (left) =====
  const cols=4, gx=20, gyTop=80, gap=8, gridW=W-360, cellW=(gridW-(cols-1)*gap)/cols;
  const rows=Math.ceil(OUTFITS.length/cols), botY=H-52, cellH=Math.min(66,(botY-gyTop-(rows-1)*gap)/rows);
  for(let i=0;i<OUTFITS.length;i++){ const o=OUTFITS[i], unl=outfitUnlocked(o.key), sel=(o.key===selectedOutfit), prev=(o.key===outfitPreview);
    const cx=gx+(i%cols)*(cellW+gap), cy=gyTop+Math.floor(i/cols)*(cellH+gap);
    ctx.fillStyle=sel?'rgba(143,208,160,0.16)':unl?'rgba(255,255,255,0.04)':'rgba(255,255,255,0.02)'; ctx.beginPath(); ctx.roundRect(cx,cy,cellW,cellH,10); ctx.fill();
    ctx.strokeStyle=prev?'#fff':sel?'rgba(143,208,160,0.7)':unl?'rgba(255,180,215,0.28)':'rgba(255,255,255,0.07)'; ctx.lineWidth=prev?2.4:1.3; ctx.stroke();
    ctx.textAlign='left'; ctx.globalAlpha=unl?1:0.4; ctx.font='24px serif'; ctx.fillText(unl?(OUTFIT_EMOJI[o.key]||'👗'):'🔒', cx+10, cy+cellH/2+8); ctx.globalAlpha=1;
    ctx.fillStyle=sel?'#bff0cc':unl?'#f0dce8':'#8a7a92'; ctx.font='bold 12px "Trebuchet MS"'; ctx.fillText(o.name.slice(0,13), cx+42, cy+cellH/2-2);
    ctx.fillStyle=sel?'#8fd0a0':unl?'#a894b2':'#6a5a72'; ctx.font='9px monospace'; ctx.fillText(sel?'EQUIPPED':unl?'tap to wear':'locked', cx+42, cy+cellH/2+12);
    outfitTiles.push({x:cx,y:cy,w:cellW,h:cellH,key:o.key,unlocked:unl}); }
  // back button
  { const bw=180,bh=30,bx=20,by=H-42; outfitBackBtn={x:bx,y:by,w:bw,h:bh};
    ctx.fillStyle='rgba(30,16,40,0.85)'; ctx.beginPath(); ctx.roundRect(bx,by,bw,bh,8); ctx.fill(); ctx.strokeStyle='#8fd0ff'; ctx.lineWidth=1.5; ctx.stroke();
    ctx.fillStyle='#8fd0ff'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText('⌂ BACK  ['+kb('shoot')+']', bx+bw/2, by+20); ctx.textAlign='left'; }
}
