function drawStageClear(){ ctx.fillStyle='rgba(6,4,10,0.92)'; ctx.fillRect(0,0,W,H); ctx.textAlign='center';
  const img=IMG['clear'+clearInfo.stage]; const bw=460, bh=Math.round(bw*440/1000), bx=W/2-bw/2, byy=18;
  if(imgOK(img)){ ctx.save(); ctx.shadowColor='rgba(255,120,190,0.5)'; ctx.shadowBlur=24; ctx.beginPath(); ctx.roundRect(bx,byy,bw,bh,14); ctx.clip(); ctx.drawImage(img,bx,byy,bw,bh); ctx.restore(); ctx.strokeStyle='rgba(255,210,120,0.7)'; ctx.lineWidth=3; ctx.beginPath(); ctx.roundRect(bx,byy,bw,bh,14); ctx.stroke(); }
  else { ctx.save(); ctx.shadowColor='#ffd27a'; ctx.shadowBlur=22; ctx.fillStyle='#ffe08a'; ctx.font='900 42px "Trebuchet MS"'; ctx.fillText('STAGE CLEAR', W/2, 110); ctx.restore(); }
  let yb=byy+bh+16;
  // celebratory leek-spin Bobina — fixed-height box; the live #leek gif overlay is positioned here (see manageGifOverlays)
  if(leekEl && leekEl.complete && leekEl.naturalWidth){ const lh=100, lw=Math.round(lh*leekEl.naturalWidth/leekEl.naturalHeight);
    leekRect={ cx:W/2, cy:yb+lh/2, w:lw, h:lh }; yb+=lh+36; }   // generous gap so the heading never clips the gif
  else { leekRect=null; yb+=8; }
  ctx.fillStyle='#ff9ecb'; ctx.font='bold 22px "Trebuchet MS"'; ctx.fillText(clearInfo.killsThisStage+' MUMUS ELIMINATED', W/2, yb); yb+=24;
  ctx.fillStyle='#e8d6f0'; ctx.font='13px monospace'; ctx.fillText('Total '+totalKills+'  ·  Rank '+rankLetter()+'  ·  Power Lv'+shotLevel()+'  ·  Score '+fmtScore(sessionScore), W/2, yb); yb+=20;
  if(clearInfo.emblems && clearInfo.emblems.length){ ctx.font='bold 12px monospace'; for(const em of clearInfo.emblems.slice(0,3)){ ctx.fillStyle='#8fd0ff'; ctx.fillText('🏅 '+(em.icon||'◆')+' '+em.name+' Emblem earned!'+(em.outfit?' (skin unlocked!)':''), W/2, yb); yb+=16; } }   // ONLY real, newly-earned emblems from this stage — not a per-clear fake
  // arsenal button — tweak your loadout between stages
  { const aw=224,ah=30,ax=W/2-aw/2,ay=H-86; scArsenalBtn={x:ax,y:ay,w:aw,h:ah}; ctx.fillStyle='rgba(20,40,58,0.85)'; ctx.beginPath(); ctx.roundRect(ax,ay,aw,ah,8); ctx.fill(); ctx.strokeStyle='#7fdfff'; ctx.lineWidth=1.5; ctx.stroke(); ctx.fillStyle='#bff0ff'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText('🎒 EDIT ARSENAL', W/2, ay+20); ctx.textAlign='left'; }
  // action buttons — cleanly spaced pair
  drawMenuBtn(W/2-90, H-50);
  { const nw=150,nh=28,nx=W/2+90-nw/2,ny=H-50; ctx.fillStyle='rgba(40,20,16,0.85)'; ctx.beginPath(); ctx.roundRect(nx,ny,nw,nh,8); ctx.fill(); ctx.strokeStyle='#ffd27a'; ctx.lineWidth=1.5; ctx.stroke(); ctx.fillStyle=(Math.floor(tick/26)%2)?'#fff':'#ffd27a'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText('NEXT STAGE ▶  ['+kb('shoot')+']', W/2+90, ny+19); ctx.textAlign='left'; } }
