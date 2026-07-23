function drawStunStars(e){ const t=tick; ctx.save(); ctx.translate(e.x,e.y-e.r-5); ctx.textAlign='center'; ctx.font='9px monospace'; ctx.fillStyle='#ffe08a';
  for(let i=0;i<3;i++){ const a=t*0.12+i*2.094; ctx.fillText('★', Math.cos(a)*8, Math.sin(a)*3+3); } ctx.textAlign='left'; ctx.restore(); }
