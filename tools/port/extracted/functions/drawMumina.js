function drawMumina(b,flash){ const R=b.r;
  // body (green uniform)
  ctx.fillStyle=flash?'#fff':'#2f6b3a'; ctx.beginPath(); ctx.ellipse(0,R*0.55,R*0.85,R*0.7,0,0,7); ctx.fill();
  ctx.fillStyle='#f4efe6'; ctx.fillRect(-R*0.06,R*0.08,R*0.12,R*0.36);
  ctx.fillStyle=flash?'#fff':'#3f8a4a'; ctx.beginPath(); ctx.moveTo(0,R*0.08); ctx.lineTo(-R*0.16,R*0.5); ctx.lineTo(R*0.16,R*0.5); ctx.closePath(); ctx.fill();
  // hair back
  ctx.fillStyle=flash?'#fff':'#c96a24'; ctx.beginPath(); ctx.arc(0,-R*0.18,R*0.78,0,7); ctx.fill();
  // face
  ctx.fillStyle=flash?'#fff':'#f0c9a0'; ctx.beginPath(); ctx.arc(0,-R*0.24,R*0.55,0,7); ctx.fill();
  // white bull horns
  ctx.fillStyle=flash?'#fff':'#f0ead6'; ctx.strokeStyle='#cbbf9a'; ctx.lineWidth=1.5;
  ctx.beginPath(); ctx.moveTo(-R*0.4,-R*0.55); ctx.quadraticCurveTo(-R*0.98,-R*0.85,-R*0.78,-R*1.16); ctx.quadraticCurveTo(-R*0.55,-R*0.8,-R*0.25,-R*0.6); ctx.fill();
  ctx.beginPath(); ctx.moveTo(R*0.4,-R*0.55); ctx.quadraticCurveTo(R*0.98,-R*0.85,R*0.78,-R*1.16); ctx.quadraticCurveTo(R*0.55,-R*0.8,R*0.25,-R*0.6); ctx.fill();
  // bangs
  ctx.fillStyle=flash?'#fff':'#e8873a'; ctx.beginPath(); ctx.moveTo(-R*0.56,-R*0.28); ctx.quadraticCurveTo(-R*0.5,-R*0.82,0,-R*0.84); ctx.quadraticCurveTo(R*0.5,-R*0.82,R*0.56,-R*0.28); ctx.quadraticCurveTo(R*0.3,-R*0.5,R*0.16,-R*0.32); ctx.quadraticCurveTo(0,-R*0.5,-R*0.16,-R*0.32); ctx.quadraticCurveTo(-R*0.3,-R*0.5,-R*0.56,-R*0.28); ctx.fill();
  ctx.beginPath(); ctx.ellipse(-R*0.53,-R*0.08,R*0.14,R*0.4,0.1,0,7); ctx.ellipse(R*0.53,-R*0.08,R*0.14,R*0.4,-0.1,0,7); ctx.fill();
  // green bow
  ctx.fillStyle=flash?'#fff':'#4a9e3a'; ctx.beginPath(); ctx.moveTo(R*0.46,-R*0.5); ctx.lineTo(R*0.64,-R*0.62); ctx.lineTo(R*0.64,-R*0.38); ctx.closePath(); ctx.moveTo(R*0.46,-R*0.5); ctx.lineTo(R*0.28,-R*0.62); ctx.lineTo(R*0.28,-R*0.38); ctx.closePath(); ctx.fill(); circle(R*0.46,-R*0.5,R*0.06,flash?'#fff':'#3a7e2a');
  // green eyes
  ctx.fillStyle='#fff'; ctx.beginPath(); ctx.ellipse(-R*0.2,-R*0.2,R*0.13,R*0.17,0,0,7); ctx.ellipse(R*0.2,-R*0.2,R*0.13,R*0.17,0,0,7); ctx.fill();
  ctx.fillStyle='#5fae3a'; circle(-R*0.2,-R*0.18,R*0.09,'#5fae3a'); circle(R*0.2,-R*0.18,R*0.09,'#5fae3a');
  ctx.fillStyle='#123a0a'; circle(-R*0.2,-R*0.18,R*0.045,'#123a0a'); circle(R*0.2,-R*0.18,R*0.045,'#123a0a');
  ctx.fillStyle='#fff'; circle(-R*0.23,-R*0.22,R*0.03,'#fff'); circle(R*0.17,-R*0.22,R*0.03,'#fff');
  ctx.fillStyle='rgba(220,120,120,0.4)'; circle(-R*0.33,-R*0.04,R*0.07,'rgba(220,120,120,0.4)'); circle(R*0.33,-R*0.04,R*0.07,'rgba(220,120,120,0.4)');
  ctx.fillStyle='#a94a4a'; ctx.beginPath(); ctx.ellipse(0,-R*0.02,R*0.06,R*0.045,0,0,7); ctx.fill();
  // gold crown
  ctx.fillStyle=flash?'#fff':'#ffd24a'; ctx.beginPath(); ctx.moveTo(-R*0.26,-R*0.72); ctx.lineTo(-R*0.26,-R*0.9); ctx.lineTo(-R*0.13,-R*0.78); ctx.lineTo(0,-R*0.98); ctx.lineTo(R*0.13,-R*0.78); ctx.lineTo(R*0.26,-R*0.9); ctx.lineTo(R*0.26,-R*0.72); ctx.closePath(); ctx.fill();
  ctx.fillStyle='#e0102a'; circle(0,-R*0.85,R*0.04,'#e0102a');
}
