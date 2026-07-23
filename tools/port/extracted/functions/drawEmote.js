function drawEmote(em){
  const a=Math.min(1, em.life/12), yy=em.y - (50-em.life)*0.55, pop=Math.min(1.15,(50-em.life)/5);
  ctx.save(); ctx.translate(em.x, yy); ctx.scale(pop,pop); ctx.globalAlpha=a;
  // speech bubble
  ctx.fillStyle='#fff'; ctx.strokeStyle='#ff6ec7'; ctx.lineWidth=1.8; ctx.beginPath(); ctx.arc(0,0,13,0,7); ctx.fill(); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(-3.5,11); ctx.lineTo(0,17); ctx.lineTo(3.5,11); ctx.closePath(); ctx.fillStyle='#fff'; ctx.fill();
  const k=em.kind;
  if(k==='love'){ ctx.fillStyle='#ff4d8d'; ctx.beginPath(); ctx.moveTo(0,3); ctx.bezierCurveTo(0,-2,-6,-2,-6,1); ctx.bezierCurveTo(-6,4,0,6,0,8); ctx.bezierCurveTo(0,6,6,4,6,1); ctx.bezierCurveTo(6,-2,0,-2,0,3); ctx.fill(); }
  else if(k==='star'){ ctx.fillStyle='#ffd24a'; ctx.beginPath(); for(let i=0;i<5;i++){ const a2=-Math.PI/2+i*2*Math.PI/5, r=i%1?0:6; ctx.lineTo(Math.cos(a2)*6,Math.sin(a2)*6); const a3=a2+Math.PI/5; ctx.lineTo(Math.cos(a3)*2.6,Math.sin(a3)*2.6); } ctx.closePath(); ctx.fill(); }
  else if(k==='wow'){ // >o< excited
    ctx.strokeStyle='#3a2030'; ctx.lineWidth=1.6; ctx.beginPath(); ctx.moveTo(-6,-3); ctx.lineTo(-2,-1); ctx.lineTo(-6,1); ctx.moveTo(6,-3); ctx.lineTo(2,-1); ctx.lineTo(6,1); ctx.stroke(); ctx.fillStyle='#ff4d6d'; ctx.beginPath(); ctx.ellipse(0,4,2.6,3,0,0,7); ctx.fill(); }
  else { // happy ^_^
    ctx.strokeStyle='#3a2030'; ctx.lineWidth=1.6; ctx.beginPath(); ctx.moveTo(-6,-1); ctx.lineTo(-3,-4); ctx.lineTo(0,-1); ctx.moveTo(0,-1); ctx.lineTo(3,-4); ctx.lineTo(6,-1); ctx.stroke(); ctx.beginPath(); ctx.arc(0,3,3,0.15*Math.PI,0.85*Math.PI); ctx.stroke(); }
  ctx.restore();
}
