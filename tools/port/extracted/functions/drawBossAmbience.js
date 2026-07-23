function drawBossAmbience(){ if(!boss || boss.dead || boss.intro>0) return;
  const t=tick, cr=_hexRgb(boss.data.color||'#ff5b6e'), bh=_rgbHue(cr[0],cr[1],cr[2]);
  const cx=PF.x+PF.w/2, cy=PF.y+PF.h*0.42, H=PF.h;
  const rage = Math.min(1.6, 0.6 + (boss.specialT>0?0.5:0) + (boss.maxhp?(1-boss.hp/boss.maxhp)*0.5:0));   // deepens as the boss rages / casts
  const spd = 1 + rage*0.5;
  ctx.save(); ctx.beginPath(); ctx.rect(PF.x,PF.y,PF.w,PF.h); ctx.clip();
  // 1) DARKEN the field for projectile contrast — a deep boss-hued vignette + a subtle overall dim
  const vg=ctx.createRadialGradient(cx,cy,H*0.14,cx,cy,H*0.92);
  vg.addColorStop(0,'rgba(0,0,0,0)'); vg.addColorStop(0.68,`hsla(${bh|0},60%,5%,${0.26+0.14*rage})`); vg.addColorStop(1,`hsla(${bh|0},68%,3%,${0.58+0.14*rage})`);
  ctx.fillStyle=vg; ctx.fillRect(PF.x,PF.y,PF.w,PF.h);
  ctx.fillStyle=`rgba(3,1,6,${0.1+0.12*rage})`; ctx.fillRect(PF.x,PF.y,PF.w,PF.h);
  // 2) low-lightness boss-hued spell-mandala (rotating rings + spokes) — a themed dark psychedelic backdrop
  ctx.save(); ctx.translate(cx,cy);
  const seg=10;
  for(let L=0;L<3;L++){ const dir=L%2?-1:1, rr=(0.2+L*0.15)*H*(1+Math.sin(t*0.02+L)*0.05), rotL=t*0.005*spd*dir+L*0.5;
    ctx.strokeStyle=`hsla(${(bh+L*22)%360|0},68%,${15+L*4}%,${0.16+0.14*rage})`; ctx.lineWidth=2;
    ctx.beginPath(); for(let i=0;i<=seg;i++){ const a=rotL+i/seg*6.283, x=Math.cos(a)*rr, y=Math.sin(a)*rr; i?ctx.lineTo(x,y):ctx.moveTo(x,y); } ctx.closePath(); ctx.stroke(); }
  ctx.strokeStyle=`hsla(${bh|0},65%,14%,${0.11+0.1*rage})`; ctx.lineWidth=1.4;   // spell-circle spokes
  { const rotS=t*0.005*spd; ctx.beginPath(); for(let i=0;i<seg;i++){ const a=rotS+i/seg*6.283; ctx.moveTo(0,0); ctx.lineTo(Math.cos(a)*H*0.5,Math.sin(a)*H*0.5); } ctx.stroke(); }
  // 3) slow expanding dark spell-rings (Touhou spell-card pulse) — kept low-lightness so bullets still pop
  for(let k=0;k<3;k++){ const ph=((t*0.008*spd+k/3)%1), rr=24+ph*H*0.7;
    ctx.strokeStyle=`hsla(${(bh+k*16)%360|0},70%,${20-ph*8}%,${(1-ph)*0.3*(0.6+rage*0.4)})`; ctx.lineWidth=2.4*(1-ph)+0.7; ctx.beginPath(); ctx.arc(0,0,rr,0,7); ctx.stroke(); }
  ctx.restore(); ctx.restore();
}
