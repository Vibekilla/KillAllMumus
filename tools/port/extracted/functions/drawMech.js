function drawMech(x,y,alpha,rot){
  ctx.save(); ctx.translate(x,y); if(rot) ctx.rotate(rot); ctx.globalAlpha=Math.max(0,Math.min(1,alpha===undefined?1:alpha));
  const t=tick, blue='#33507a', blueD='#22384f', blueL='#5a7ba6', red='#d8283a', redD='#9c1420', steel='#c8d2e0';
  ctx.lineJoin='round';
  // aura glow
  ctx.save(); ctx.globalAlpha*=0.5; ctx.shadowColor='#ffb04a'; ctx.shadowBlur=26; ctx.fillStyle='rgba(255,160,60,0.5)'; ctx.beginPath(); ctx.ellipse(0,4,30,26,0,0,7); ctx.fill(); ctx.restore();
  // thruster flames
  ctx.fillStyle='rgba(255,180,60,0.85)'; for(const fx2 of [-8,8]){ ctx.beginPath(); ctx.moveTo(fx2-4,18); ctx.lineTo(fx2,26+Math.sin(t*0.6)*4); ctx.lineTo(fx2+4,18); ctx.fill(); }
  // red jagged wings
  ctx.fillStyle=red; ctx.strokeStyle=redD; ctx.lineWidth=1.5;
  for(const s of [-1,1]){ ctx.save(); ctx.scale(s,1);
    ctx.beginPath(); ctx.moveTo(10,-6); ctx.lineTo(34,-16); ctx.lineTo(26,-8); ctx.lineTo(40,-4); ctx.lineTo(30,-1); ctx.lineTo(42,6); ctx.lineTo(28,6); ctx.lineTo(34,12); ctx.lineTo(16,6); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore(); }
  // torso
  ctx.fillStyle=blue; ctx.beginPath(); ctx.roundRect(-13,-6,26,22,5); ctx.fill();
  ctx.fillStyle=blueL; ctx.beginPath(); ctx.roundRect(-13,-6,26,6,4); ctx.fill();
  ctx.fillStyle=blueD; ctx.beginPath(); ctx.roundRect(-18,-4,7,12,3); ctx.roundRect(11,-4,7,12,3); ctx.fill();
  // panda face
  ctx.fillStyle='#f2efe6'; ctx.beginPath(); ctx.arc(0,5,8,0,7); ctx.fill();
  ctx.fillStyle='#1a1620'; ctx.beginPath(); ctx.ellipse(-3.5,3,2.4,3,0.3,0,7); ctx.ellipse(3.5,3,2.4,3,-0.3,0,7); ctx.fill();
  ctx.fillStyle='#ff3b5c'; ctx.beginPath(); ctx.arc(-3.5,3.5,1,0,7); ctx.arc(3.5,3.5,1,0,7); ctx.fill();
  ctx.fillStyle='#1a1620'; ctx.beginPath(); ctx.arc(0,7,1.4,0,7); ctx.fill();
  // legs
  ctx.fillStyle=blueD; ctx.beginPath(); ctx.roundRect(-10,15,7,7,2); ctx.roundRect(3,15,7,7,2); ctx.fill();
  // missile-pod head
  ctx.fillStyle=blueD; ctx.beginPath(); ctx.roundRect(-11,-20,22,15,3); ctx.fill();
  ctx.fillStyle=steel; for(let cx=-8;cx<=8;cx+=5) for(let cy=-18;cy<=-9;cy+=4){ ctx.beginPath(); ctx.arc(cx,cy,1.6,0,7); ctx.fill(); }
  ctx.fillStyle=blueD; ctx.beginPath(); ctx.arc(-9,-21,3,0,7); ctx.arc(9,-21,3,0,7); ctx.fill();
  ctx.restore();
}
