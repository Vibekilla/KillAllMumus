function drawHellPortal(b){ const R=b.hellR||0; if(R<=1) return; const cx=b.x, cy=b.hy||b.y;
  ctx.save(); ctx.translate(cx,cy);
  ctx.save(); ctx.shadowColor='#ff2a00'; ctx.shadowBlur=42; ctx.globalAlpha=0.5; ctx.fillStyle='#3a0008'; ctx.beginPath(); ctx.ellipse(0,0,R*1.16,R*0.76,0,0,7); ctx.fill(); ctx.restore();
  const sp=(b.hellT||0)*0.12, cols=['#ff5a1a','#ff2a00','#c01020','#7a0818','#3a0410'];
  for(let i=0;i<5;i++){ const rr=R*(1-i*0.16); ctx.strokeStyle=cols[i]; ctx.lineWidth=3; ctx.globalAlpha=0.9;
    ctx.beginPath(); for(let a=0;a<=6.3;a+=0.3){ const r=rr+Math.sin(a*3+sp+i)*R*0.05; const px=Math.cos(a+sp+i*0.5)*r, py=Math.sin(a+sp+i*0.5)*r*0.66; if(a===0)ctx.moveTo(px,py); else ctx.lineTo(px,py); } ctx.closePath(); ctx.stroke(); }
  ctx.globalAlpha=1; ctx.fillStyle='#08020a'; ctx.beginPath(); ctx.ellipse(0,0,R*0.4,R*0.26,0,0,7); ctx.fill();
  ctx.restore();
}
