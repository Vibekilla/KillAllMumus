function drawBobo(cx,cy,sc,happy){
  ctx.save(); ctx.translate(cx,cy); ctx.scale(sc,sc); ctx.lineJoin='round'; ctx.lineCap='round';
  const fur='#6e4a2e',furD='#4e3320',ear='#7a5540',muz='#e8cfa4',nose='#241812',shirt='#cf2f38',shirtD='#9c1f27',ln='#241611';
  const bob=Math.sin(tick*0.08)*1.2;
  // body / red shirt
  ctx.fillStyle=shirt; ctx.beginPath(); ctx.ellipse(0,30+bob,26,22,0,0,7); ctx.strokeStyle=ln; ctx.lineWidth=2; ctx.stroke(); ctx.fill();
  ctx.fillStyle=shirtD; ctx.beginPath(); ctx.ellipse(0,40+bob,24,10,0,0,7); ctx.fill();
  // arms
  ctx.fillStyle=fur; ctx.beginPath(); ctx.ellipse(-22,26+bob,7,9,0.4,0,7); ctx.ellipse(22,26+bob,7,9,-0.4,0,7); ctx.fill();
  ctx.fillStyle=fur; ctx.beginPath(); ctx.ellipse(-12,50+bob,8,6,0,0,7); ctx.ellipse(12,50+bob,8,6,0,0,7); ctx.fill();
  // ears
  ctx.fillStyle=fur; ctx.beginPath(); ctx.arc(-22,-30+bob,13,0,7); ctx.arc(22,-30+bob,13,0,7); ctx.fill();
  ctx.fillStyle=ear; ctx.beginPath(); ctx.arc(-22,-30+bob,6.5,0,7); ctx.arc(22,-30+bob,6.5,0,7); ctx.fill();
  // head
  ctx.fillStyle=fur; ctx.beginPath(); ctx.arc(0,-12+bob,30,0,7); ctx.strokeStyle=ln; ctx.lineWidth=2; ctx.stroke(); ctx.fill();
  // muzzle
  ctx.fillStyle=muz; ctx.beginPath(); ctx.ellipse(0,0+bob,16,13,0,0,7); ctx.fill();
  // nose
  ctx.fillStyle=nose; ctx.beginPath(); ctx.moveTo(-5,-4+bob); ctx.lineTo(5,-4+bob); ctx.lineTo(0,1+bob); ctx.closePath(); ctx.fill();
  ctx.beginPath(); ctx.moveTo(0,1+bob); ctx.quadraticCurveTo(0,6+bob,-4,7+bob); ctx.moveTo(0,1+bob); ctx.quadraticCurveTo(0,6+bob,4,7+bob); ctx.strokeStyle=nose; ctx.lineWidth=1.4; ctx.stroke();
  // eyes (happy)
  if(happy){ ctx.strokeStyle=ln; ctx.lineWidth=2.4; ctx.beginPath(); ctx.arc(-12,-16+bob,5,Math.PI*1.15,Math.PI*1.85); ctx.arc(12,-16+bob,5,Math.PI*1.15,Math.PI*1.85); ctx.stroke(); }
  else { for(const ex of [-12,12]){ ctx.fillStyle='#fff'; ctx.beginPath(); ctx.ellipse(ex,-15+bob,4,5,0,0,7); ctx.fill(); ctx.fillStyle='#1a120c'; ctx.beginPath(); ctx.arc(ex,-14+bob,2.4,0,7); ctx.fill(); ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(ex-1,-16+bob,1,0,7); ctx.fill(); } }
  // cheek blush
  ctx.fillStyle='rgba(220,120,120,0.4)'; ctx.beginPath(); ctx.arc(-18,-6+bob,4,0,7); ctx.arc(18,-6+bob,4,0,7); ctx.fill();
  ctx.restore();
}
