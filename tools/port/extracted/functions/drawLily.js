function drawLily(b,flash){ const R=b.r;
  const fur=flash?'#fff':'#f5f2ec', furSh=flash?'#fff':'#dcd6c9', pink='#e8b8c0';
  // fluffy body with tufted outline
  ctx.fillStyle=furSh; for(let i=-4;i<=4;i++){ ctx.beginPath(); ctx.arc(i*R*0.2, R*0.92, R*0.17,0,7); ctx.fill(); }
  ctx.fillStyle=fur; ctx.beginPath(); ctx.ellipse(0,R*0.52,R*0.82,R*0.6,0,0,7); ctx.fill();
  ctx.fillStyle=fur; for(let i=-4;i<=4;i++){ ctx.beginPath(); ctx.arc(i*R*0.2, R*0.82, R*0.15,0,7); ctx.fill(); }
  // Solana collar (purple→teal) with ◎ tag
  const cg=ctx.createLinearGradient(-R*0.5,0,R*0.5,0); cg.addColorStop(0,'#9945ff'); cg.addColorStop(1,'#14f195');
  ctx.strokeStyle=cg; ctx.lineWidth=R*0.15; ctx.lineCap='round'; ctx.beginPath(); ctx.arc(0,R*0.28,R*0.52,Math.PI*0.16,Math.PI*0.84); ctx.stroke();
  ctx.fillStyle='#14f195'; circle(0,R*0.55,R*0.11,'#14f195'); ctx.fillStyle='#0a2e1a'; ctx.font='bold '+(R*0.15)+'px monospace'; ctx.textAlign='center'; ctx.fillText('◎',0,R*0.6); ctx.textAlign='left';
  // pointy ears (with pink inner)
  ctx.fillStyle=fur; ctx.beginPath(); ctx.moveTo(-R*0.5,-R*0.55); ctx.lineTo(-R*0.66,-R*1.16); ctx.lineTo(-R*0.16,-R*0.7); ctx.closePath(); ctx.fill();
  ctx.beginPath(); ctx.moveTo(R*0.5,-R*0.55); ctx.lineTo(R*0.66,-R*1.16); ctx.lineTo(R*0.16,-R*0.7); ctx.closePath(); ctx.fill();
  ctx.fillStyle=pink; ctx.beginPath(); ctx.moveTo(-R*0.44,-R*0.64); ctx.lineTo(-R*0.55,-R*1.0); ctx.lineTo(-R*0.26,-R*0.72); ctx.closePath(); ctx.fill();
  ctx.beginPath(); ctx.moveTo(R*0.44,-R*0.64); ctx.lineTo(R*0.55,-R*1.0); ctx.lineTo(R*0.26,-R*0.72); ctx.closePath(); ctx.fill();
  // head — big fluffy round with cheek tufts
  ctx.fillStyle=furSh; for(let a=0;a<14;a++){ const ang=a/14*Math.PI*2; ctx.beginPath(); ctx.arc(Math.cos(ang)*R*0.7, -R*0.12+Math.sin(ang)*R*0.66, R*0.14,0,7); ctx.fill(); }
  ctx.fillStyle=fur; ctx.beginPath(); ctx.arc(0,-R*0.12,R*0.68,0,7); ctx.fill();
  // sleepy dark eyes
  ctx.fillStyle='#1a1410'; ctx.beginPath(); ctx.ellipse(-R*0.25,-R*0.14,R*0.1,R*0.11,0,0,7); ctx.ellipse(R*0.25,-R*0.14,R*0.1,R*0.11,0,0,7); ctx.fill();
  ctx.fillStyle='#fff'; circle(-R*0.28,-R*0.17,R*0.03,'#fff'); circle(R*0.22,-R*0.17,R*0.03,'#fff');
  // muzzle + black nose
  ctx.fillStyle=furSh; ctx.beginPath(); ctx.ellipse(0,R*0.12,R*0.28,R*0.22,0,0,7); ctx.fill();
  ctx.fillStyle=fur; ctx.beginPath(); ctx.ellipse(0,R*0.16,R*0.2,R*0.15,0,0,7); ctx.fill();
  ctx.fillStyle=flash?'#888':'#141014'; ctx.beginPath(); ctx.ellipse(0,R*0.02,R*0.12,R*0.09,0,0,7); ctx.fill();
  ctx.fillStyle='rgba(255,255,255,0.5)'; circle(-R*0.03,-R*0.01,R*0.03,'rgba(255,255,255,0.5)');
  // little frown mouth
  ctx.strokeStyle='#3a2e28'; ctx.lineWidth=2; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(0,R*0.1); ctx.lineTo(0,R*0.2); ctx.moveTo(0,R*0.2); ctx.quadraticCurveTo(-R*0.12,R*0.28,-R*0.2,R*0.2); ctx.moveTo(0,R*0.2); ctx.quadraticCurveTo(R*0.12,R*0.28,R*0.2,R*0.2); ctx.stroke();
  // cross forehead crease (she's grumpy at ETH)
  ctx.strokeStyle='rgba(80,60,50,0.5)'; ctx.lineWidth=1.4; ctx.beginPath(); ctx.moveTo(-R*0.06,-R*0.4); ctx.lineTo(-R*0.02,-R*0.28); ctx.moveTo(R*0.06,-R*0.4); ctx.lineTo(R*0.02,-R*0.28); ctx.stroke();
}
