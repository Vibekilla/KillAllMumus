function drawDashComet(p){ const active = p.dash>0 || (p.trail && p.trail.length);
  if(!active) return;
  const slash=!!p.slashDash, t=tick, hue0=(t*4)%360;
  ctx.save(); ctx.globalCompositeOperation='lighter';
  // --- rainbow tail (each trail point a shifting hue) — head is about as wide as her body ---
  if(p.trail && p.trail.length>1){ const n=p.trail.length;
    for(let i=n-1;i>=0;i--){ const q=p.trail[i], f=1-i/n, r=(4+f*(slash?26:20)), hue=(hue0+i*22)%360;
      const g=ctx.createRadialGradient(q.x,q.y,0,q.x,q.y,r);
      g.addColorStop(0,`hsla(${hue},100%,74%,1)`); g.addColorStop(0.5,`hsla(${(hue+45)%360},100%,56%,0.55)`); g.addColorStop(1,'hsla(0,0%,0%,0)');
      ctx.globalAlpha=0.14+f*0.55; ctx.fillStyle=g; ctx.beginPath(); ctx.arc(q.x,q.y,r,0,7); ctx.fill(); }
    // bright white motion streak down the centre of the tail
    ctx.globalAlpha=slash?0.85:0.55; ctx.strokeStyle='rgba(255,255,255,0.9)'; ctx.lineWidth=slash?2.6:1.5; ctx.lineCap='round'; ctx.lineJoin='round';
    ctx.beginPath(); for(let i=0;i<n;i++){ const q=p.trail[i]; if(i===0)ctx.moveTo(q.x,q.y); else ctx.lineTo(q.x,q.y);} ctx.stroke(); ctx.globalAlpha=1;
  }
  // --- comet head: a mini psychedelic bubble that follows her (rotating rainbow rim + glow) ---
  const aura = p.dash>0 ? 1 : Math.min(1, (p.trail?p.trail.length:0)/16);
  if(aura>0.02){ const ar=(slash?26:19)+4*Math.sin(t*0.5);
    const gg=ctx.createRadialGradient(p.x,p.y,0,p.x,p.y,ar+12);
    gg.addColorStop(0,`hsla(${hue0},100%,74%,${(slash?0.7:0.5)*aura})`); gg.addColorStop(0.4,`hsla(${(hue0+60)%360},100%,56%,${0.32*aura})`); gg.addColorStop(1,'hsla(0,0%,0%,0)');
    ctx.fillStyle=gg; ctx.beginPath(); ctx.arc(p.x,p.y,ar+12,0,7); ctx.fill();
    ctx.save(); ctx.translate(p.x,p.y); const rim=18; ctx.lineWidth=slash?2.6:1.7; ctx.globalAlpha=aura;
    for(let i=0;i<rim;i++){ const a0=i/rim*6.283+t*0.05, a1=(i+1)/rim*6.283+t*0.05, hue=(hue0+i/rim*360)%360; ctx.strokeStyle=`hsla(${hue},100%,66%,0.7)`; ctx.beginPath(); ctx.arc(0,0,ar*0.7,a0,a1); ctx.stroke(); }
    ctx.restore();
  }
  ctx.restore(); ctx.globalAlpha=1;
  // --- trailing psychedelic sparkles flung out behind her ---
  if(p.dash>0 && !paused){ const hue=(hue0+Math.random()*60)%360, n=slash?2:1;
    for(let k=0;k<n;k++) particles.push({x:p.x+(Math.random()-.5)*12, y:p.y+(Math.random()-.5)*12, vx:-Math.cos(p.dashAng)*(1+Math.random()*2)+(Math.random()-.5)*2, vy:-Math.sin(p.dashAng)*(1+Math.random()*2)+(Math.random()-.5)*2, life:16+((Math.random()*12)|0), c:`hsl(${hue|0},100%,70%)`}); }
}
