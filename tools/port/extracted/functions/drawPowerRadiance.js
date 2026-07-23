function drawPowerRadiance(p){ if(!run||p.dead) return;
  const pf=Math.max(0,Math.min(1,(run.power-1)/5)); if(pf<0.12) return;
  const t=tick, _c=bodyCtr(p), cx=_c.x, cy=_c.y, hue0=(t*2.4)%360;
  ctx.save(); ctx.globalCompositeOperation='lighter';
  const HR=55+pf*95, hg=ctx.createRadialGradient(cx,cy,10,cx,cy,HR);
  hg.addColorStop(0,`hsla(${hue0},90%,60%,${0.035+pf*0.06})`); hg.addColorStop(1,`hsla(${hue0},90%,60%,0)`);
  ctx.fillStyle=hg; ctx.beginPath(); ctx.arc(cx,cy,HR,0,7); ctx.fill();
  const rings=2+Math.floor(pf*3);
  for(let k=0;k<rings;k++){ const ph=((t*0.009 + k/rings)%1), rr=22+ph*(66+pf*120), al=(1-ph)*(0.05+pf*0.09), hue=(hue0+k*55)%360;
    ctx.strokeStyle=`hsla(${hue},95%,66%,${al})`; ctx.lineWidth=1.4*(1-ph)+0.4;
    ctx.beginPath(); for(let a=0;a<=6.3;a+=0.32){ const wob=1+Math.sin(a*5+t*0.14+k)*0.06*pf; const x=cx+Math.cos(a)*rr*wob, y=cy+Math.sin(a)*rr*wob; if(a===0)ctx.moveTo(x,y); else ctx.lineTo(x,y);} ctx.closePath(); ctx.stroke(); }
  ctx.restore();
}
