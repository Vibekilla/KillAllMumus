function drawPowerAura(p){ if(!run) return;
  const pf=Math.max(0,Math.min(1,(run.power-1)/5));   // 0 at base power → 1 at max
  if(pf<0.02) return;
  const t=tick, oc=outfitColors();
  const rot=(p.face!==undefined?p.face:-Math.PI/2)+Math.PI/2;
  const R=(30+pf*15)*(1+Math.sin(t*0.09)*0.05*(0.4+pf));   // bubble fits her whole body from the start, grows modestly with power
  const hue0=(t*2.4)%360;
  const _c=bodyCtr(p), cx=_c.x, cy=_c.y;   // keep her dead-centre in the bubble at every facing
  ctx.save(); ctx.translate(cx, cy); ctx.globalCompositeOperation='lighter';
  // outer aura glow — tinted with the outfit colours for cohesion
  const gg=ctx.createRadialGradient(0,0,R*0.3,0,0,R*1.6);
  gg.addColorStop(0,_hexA(oc[0],0.12+pf*0.16)); gg.addColorStop(0.55,_hexA(oc[1],0.10+pf*0.16)); gg.addColorStop(1,_hexA(oc[1],0));
  ctx.fillStyle=gg; ctx.beginPath(); ctx.arc(0,0,R*1.6,0,7); ctx.fill();
  // ===== bubble surface (rotates with her body so it follows the model) =====
  ctx.save(); ctx.rotate(rot);
  // iridescent oil-slick film — concentric hue-shifting bands
  const bands=6+Math.floor(pf*4);
  for(let i=bands;i>=1;i--){ const rr=R*(i/bands+0.03), hue=(hue0+i*(38+pf*26)+Math.sin(t*0.09+i)*18)%360;
    ctx.strokeStyle=`hsla(${hue},100%,60%,${0.07+pf*0.12})`; ctx.lineWidth=(R/bands)*1.6; ctx.beginPath(); ctx.arc(0,0,rr,0,7); ctx.stroke(); }
  // swirling psychedelic ribbons (each segment its own hue)
  ctx.lineCap='round'; const swirls=2+Math.floor(pf*3);
  for(let k=0;k<swirls;k++){ const dir=k%2?1:-1, base=t*(0.02+k*0.006)*dir+k*2.2; let px=null,py=null;
    for(let s=0;s<=1.2;s+=0.075){ const a=base+s*3.6, rr=R*(0.5+0.42*Math.sin(s*5+t*0.11+k)), x=Math.cos(a)*rr, y=Math.sin(a)*rr;
      if(px!==null){ const hue=(hue0+s*180+k*70)%360; ctx.strokeStyle=`hsla(${hue},100%,64%,${0.38+pf*0.34})`; ctx.lineWidth=1.6+pf*1.5; ctx.beginPath(); ctx.moveTo(px,py); ctx.lineTo(x,y); ctx.stroke(); } px=x; py=y; } }
  // rotating rainbow soap-bubble rim
  const rim=26; ctx.lineWidth=2+pf*1.6;
  for(let i=0;i<rim;i++){ const a0=i/rim*6.283+t*0.02, a1=(i+1)/rim*6.283+t*0.02, hue=(hue0+i/rim*360)%360;
    ctx.strokeStyle=`hsla(${hue},100%,66%,${0.4+pf*0.34})`; ctx.beginPath(); ctx.arc(0,0,R*0.98,a0,a1); ctx.stroke(); }
  // twinkling sparkles inside the bubble — smooth hue-shifting fade-in/out (no popping)
  const spk=5+Math.floor(pf*7);
  for(let i=0;i<spk;i++){ const a=i*2.399+t*0.03, rr=R*(0.28+0.62*((i*0.37)%1)), x=Math.cos(a)*rr, y=Math.sin(a)*rr*0.92;
    const sn=Math.sin(t*0.28+i*1.7), tw=sn>0?sn*sn:0;   // 0→1→0, spends time off — smooth twinkle
    if(tw<0.02) continue; const sz=(0.9+pf*1.2)*tw, hue=(hue0+i*47)%360;
    ctx.fillStyle=`hsla(${hue},100%,72%,${0.75*tw})`; ctx.beginPath(); ctx.arc(x,y,sz,0,7); ctx.fill();
    ctx.strokeStyle=`hsla(${(hue+30)%360},100%,82%,${0.5*tw})`; ctx.lineWidth=0.8; ctx.beginPath(); ctx.moveTo(x-sz*2.4,y); ctx.lineTo(x+sz*2.4,y); ctx.moveTo(x,y-sz*2.4); ctx.lineTo(x,y+sz*2.4); ctx.stroke(); }
  ctx.restore();
  // glossy sheen highlight — now hue-shifting + gently breathing so it's not a static white blob
  const shHue=(hue0+150)%360, shA=(0.30+pf*0.22)*(0.7+0.3*Math.sin(t*0.13));
  const sg=ctx.createRadialGradient(-R*0.34,-R*0.42,0,-R*0.34,-R*0.42,R*0.52);
  sg.addColorStop(0,`hsla(${shHue},100%,90%,${shA})`); sg.addColorStop(0.55,`hsla(${shHue},100%,72%,${shA*0.4})`); sg.addColorStop(1,'hsla(0,0%,100%,0)');
  ctx.fillStyle=sg; ctx.beginPath(); ctx.arc(-R*0.34,-R*0.42,R*0.52,0,7); ctx.fill();
  // ===== LEVEL 5 — the SAME soap-bubble aesthetic, overflowing: a second larger iridescent bubble +
  //       gentle rainbow ripples + orbiting mini soap-bubbles (a natural escalation of the Lv4 look) =====
  if(run.power>=5){ const p5=0.5+0.5*Math.sin(t*0.09);
    const R2=R*(1.34+0.05*p5);
    // faint iridescent film filling the gap out to the outer bubble
    const fg=ctx.createRadialGradient(0,0,R*0.96,0,0,R2); fg.addColorStop(0,'rgba(0,0,0,0)'); fg.addColorStop(0.6,`hsla(${(hue0+80)%360},100%,66%,0.10)`); fg.addColorStop(1,`hsla(${(hue0+200)%360},100%,66%,0.15)`);
    ctx.fillStyle=fg; ctx.beginPath(); ctx.arc(0,0,R2,0,7); ctx.fill();
    // a SECOND rainbow soap-bubble rim, concentric with the inner one (counter-rotating)
    const rim2=30; ctx.lineWidth=2.2+0.8*p5;
    for(let i=0;i<rim2;i++){ const a0=i/rim2*6.283-t*0.016, a1=(i+1)/rim2*6.283-t*0.016, hue=(hue0+150+i/rim2*360)%360; ctx.strokeStyle=`hsla(${hue},100%,68%,${0.30+0.12*p5})`; ctx.beginPath(); ctx.arc(0,0,R2,a0,a1); ctx.stroke(); }
    // rainbow bubble-ripples drifting gently outward
    for(let k=0;k<3;k++){ const ph=((t*0.014+k/3)%1), rr=R*(1.0+ph*1.5); ctx.strokeStyle=`hsla(${(hue0+ph*360)%360},100%,70%,${(1-ph)*0.4})`; ctx.lineWidth=2*(1-ph)+0.5; ctx.beginPath(); ctx.arc(0,0,rr,0,7); ctx.stroke(); }
    // little orbiting soap-bubbles with glossy highlights
    for(let i=0;i<5;i++){ const a=t*(0.018+i*0.004)+i*1.257, orb=R*(1.24+0.1*Math.sin(t*0.1+i)), bx=Math.cos(a)*orb, by=Math.sin(a)*orb, br=R*0.14*(0.85+0.3*Math.sin(t*0.2+i)), bh=(hue0+i*72)%360;
      ctx.fillStyle=`hsla(${bh},100%,80%,0.14)`; ctx.beginPath(); ctx.arc(bx,by,br,0,7); ctx.fill();
      ctx.strokeStyle=`hsla(${bh},100%,74%,0.6)`; ctx.lineWidth=1.2; ctx.beginPath(); ctx.arc(bx,by,br,0,7); ctx.stroke();
      ctx.fillStyle='rgba(255,255,255,0.7)'; ctx.beginPath(); ctx.arc(bx-br*0.35,by-br*0.4,br*0.24,0,7); ctx.fill(); } }
  ctx.restore();
  // extra iridescent LV5 sparks streaming up (soap-bubble palette, matching her aura)
  if(run.power>=5 && !paused && t%3===0){ particles.push({x:cx+(Math.random()-.5)*R*1.8, y:cy+R*0.5, vx:(Math.random()-.5)*1.4, vy:-2.0-Math.random()*2.4, life:20+((Math.random()*16)|0), c:`hsl(${(hue0+Math.random()*160)%360|0},100%,76%)`}); }
  // rising psychedelic sparkle particles — the trail she likes, hue-shifting
  if(pf>0.12 && !paused && t%Math.max(2,5-Math.floor(pf*3))===0){ const hue=(hue0+Math.random()*80)%360; particles.push({x:cx+(Math.random()-.5)*R*1.5, y:cy+R*0.4, vx:(Math.random()-.5)*1.3, vy:-1.6-Math.random()*2.2*pf, life:18+((Math.random()*14)|0), c:`hsl(${hue|0},100%,72%)`}); }
}
