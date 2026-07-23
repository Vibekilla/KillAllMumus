function drawSlowmoFx(){ const t=tick, a=Math.min(1, slowmoT/45) * Math.min(1, (300-slowmoT)/16 + 0.25);
  ctx.save();
  ctx.globalCompositeOperation='lighter'; ctx.globalAlpha=0.09*a; ctx.fillStyle='#2ac6ff'; ctx.fillRect(PF.x,PF.y,PF.w,PF.h);
  if(player && !player.dead){ const c=bodyCtr(player);
    ctx.strokeStyle='#bff0ff'; ctx.lineWidth=1.6;
    for(let k=0;k<3;k++){ const ph=((t*0.02+k/3)%1); ctx.globalAlpha=(1-ph)*0.4*a; ctx.beginPath(); ctx.arc(c.x,c.y,10+ph*95,0,7); ctx.stroke(); }
    ctx.globalAlpha=0.6*a; ctx.strokeStyle='#eafcff'; ctx.lineWidth=1.4;
    ctx.beginPath(); ctx.moveTo(c.x,c.y); ctx.lineTo(c.x+Math.cos(t*0.16)*15,c.y+Math.sin(t*0.16)*15); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(c.x,c.y); ctx.lineTo(c.x+Math.cos(t*0.016)*22,c.y+Math.sin(t*0.016)*22); ctx.stroke(); }
  ctx.restore();
  ctx.save(); const cx=PF.x+PF.w/2, cy=PF.y+PF.h/2, vg=ctx.createRadialGradient(cx,cy,PF.h*0.28,cx,cy,PF.h*0.72);
  vg.addColorStop(0,'rgba(0,0,0,0)'); vg.addColorStop(1,`rgba(8,42,64,${0.4*a})`); ctx.fillStyle=vg; ctx.fillRect(PF.x,PF.y,PF.w,PF.h); ctx.restore();
}
