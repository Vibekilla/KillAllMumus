function drawBurns(){ for(const bn of burns){ const lifeF=bn.life/bn.max, a0=bn.dir-bn.half, a1=bn.dir+bn.half;
  ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.translate(bn.x,bn.y);
  const g=ctx.createRadialGradient(0,0,4,0,0,bn.reach); g.addColorStop(0,`rgba(255,140,50,${0.16*lifeF})`); g.addColorStop(0.6,`rgba(255,60,60,${0.11*lifeF})`); g.addColorStop(1,'rgba(255,60,60,0)');
  ctx.fillStyle=g; ctx.beginPath(); ctx.moveTo(0,0); ctx.arc(0,0,bn.reach,a0,a1); ctx.closePath(); ctx.fill();
  ctx.restore(); } }
