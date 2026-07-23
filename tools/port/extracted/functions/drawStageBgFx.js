function drawStageBgFx(s){
  const t=tick, cx=PF.x+PF.w/2, cy=PF.y+PF.h*0.42, H=PF.h, W=PF.w;
  const atBoss = boss && !boss.dead && boss.intro<=0;
  const bi = atBoss ? Math.min(1.4, 0.8 + (boss.specialT>0?0.4:0) + (1-boss.hp/boss.maxhp)*0.35) : 0.5;   // rests/ramps at the boss
  const drift=Math.sin(t*0.006+bgSeed)*30 + bgHueSeed;
  ctx.save(); ctx.beginPath(); ctx.rect(PF.x,PF.y,PF.w,PF.h); ctx.clip();
  if(s===0){ // JUNGLE — nested rotating emerald canopy polygons + drifting leaf-triangles
    for(let L=0;L<4;L++){ const rr=(0.2+L*0.2)*H*(1+Math.sin(t*0.01+L+bgSeed)*0.05), a0=t*0.003*(L%2?1:-1)+L*0.6+bgSeed, N=5+L;
      ctx.strokeStyle=`hsla(${140+L*16+drift},55%,${18+L*5}%,${0.13+0.07*bi})`; ctx.lineWidth=2.4;
      ctx.beginPath(); for(let i=0;i<=N;i++){ const a=a0+i/N*6.283; const x=cx+Math.cos(a)*rr, y=cy+Math.sin(a)*rr*0.92; i?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.closePath(); ctx.stroke(); }
    for(let i=0;i<16;i++){ const px=PF.x+((i*83+t*0.6)%W), py=PF.y+((i*127+t*1.4)%H), r=5+i%4*3; ctx.fillStyle=`hsla(${115+i*6+drift},50%,24%,${0.09+0.05*bi})`; ctx.save(); ctx.translate(px,py); ctx.rotate(t*0.02+i); ctx.beginPath(); ctx.moveTo(0,-r); ctx.lineTo(r,r); ctx.lineTo(-r,r); ctx.closePath(); ctx.fill(); ctx.restore(); }
  }
  else if(s===1){ // FROZEN — 6-fold kaleidoscopic snowflake mandala + pink complement glints
    ctx.translate(cx,cy); const arms=6, rot=t*0.004+bgSeed;
    for(let a=0;a<arms;a++){ ctx.save(); ctx.rotate(rot+a/arms*6.283); ctx.strokeStyle=`hsla(${205+drift},50%,30%,${0.13+0.07*bi})`; ctx.lineWidth=2;
      ctx.beginPath(); ctx.moveTo(0,0); for(let r=0;r<H*0.52;r+=14){ ctx.lineTo(Math.sin(r*0.06+t*0.03)*10,-r); } ctx.stroke();
      for(let r=28;r<H*0.5;r+=34){ const w=Math.sin(r*0.06+t*0.03)*10; ctx.beginPath(); ctx.moveTo(w,-r); ctx.lineTo(w+11,-r+8); ctx.moveTo(w,-r); ctx.lineTo(w-11,-r+8); ctx.stroke(); } ctx.restore(); }
    for(let i=0;i<8;i++){ const a=t*0.01+i*0.785+bgSeed, rr=H*0.18+Math.sin(t*0.02+i)*H*0.14; ctx.fillStyle=`hsla(330,60%,42%,${0.07+0.05*bi})`; ctx.beginPath(); ctx.arc(Math.cos(a)*rr,Math.sin(a)*rr,3,0,7); ctx.fill(); }
  }
  else if(s===2){ // KINGDOM — blooming rose-curve (rhodonea) mandala, green + violet, petal count RNG'd
    ctx.translate(cx,cy); const k=bgPetals;
    for(let L=0;L<2;L++){ const scale=(0.3+L*0.12)*H, hue=L?280:130;
      ctx.strokeStyle=`hsla(${hue+drift},55%,${20+L*6}%,${0.12+0.07*bi})`; ctx.lineWidth=2;
      ctx.beginPath(); for(let a=0;a<=6.4;a+=0.05){ const r=Math.cos(k*a+t*0.01*(L?-1:1)+bgSeed)*scale, x=Math.cos(a)*r, y=Math.sin(a)*r; a?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.stroke(); }
  }
  else if(s===3){ // SOLANA — warping hex-grid tessellation, purple pulses + sol-green
    const hx=52, hy=46, ph=t*0.5;
    for(let gy=-1;gy<H/hy+1;gy++) for(let gx=-1;gx<W/hx+1;gx++){ const ox=(gy&1)*hx*0.5, bx=PF.x+gx*hx+ox, by=PF.y+((gy*hy+ph)%(H+hy)); const pulse=0.5+0.5*Math.sin((gx+gy)*0.6+t*0.05+bgSeed);
      ctx.strokeStyle=`hsla(${268+pulse*50+drift},60%,${16+pulse*20}%,${(0.07+0.08*bi)*(0.35+pulse*0.65)})`; ctx.lineWidth=1.4;
      ctx.beginPath(); for(let i=0;i<6;i++){ const a=i/6*6.283+0.52, x=bx+Math.cos(a)*15, y=by+Math.sin(a)*15; i?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.closePath(); ctx.stroke(); }
  }
  else if(s===4){ // CALL CENTER — concentric "signal" rings + a drifting scan-grid, amber + teal
    ctx.translate(cx,cy);
    for(let k=0;k<6;k++){ const ph=((t*0.01+k/6+bgSeed*0.16)%1), rr=ph*H*0.62; ctx.strokeStyle=`hsla(${32+Math.sin(t*0.02)*18+drift},65%,28%,${(1-ph)*(0.13+0.08*bi)})`; ctx.lineWidth=2; ctx.beginPath(); ctx.arc(0,0,rr,0,7); ctx.stroke(); }
    ctx.strokeStyle=`hsla(185,50%,28%,${0.06+0.04*bi})`; ctx.lineWidth=1; const sp=(t*0.6)%22; for(let y=-H/2;y<H/2;y+=22){ ctx.beginPath(); ctx.moveTo(-W/2,y+sp); ctx.lineTo(W/2,y+sp); ctx.stroke(); }
  }
  else if(s===5){ // AKASHIC RECORDS — rotating astral record-dials + radiating spokes + drifting glyph "pages", violet + gold
    ctx.translate(cx,cy); const rot=t*0.004+bgSeed;
    // concentric cosmic ledgers with tick marks, alternating violet / gold, counter-rotating
    for(let L=0;L<4;L++){ const rr=(0.16+L*0.12)*H, hue=(L%2?266:44), ta=rot*(L%2?1:-1);
      ctx.strokeStyle=`hsla(${hue+drift},58%,${20+L*4}%,${0.12+0.07*bi})`; ctx.lineWidth=1.8;
      ctx.beginPath(); ctx.arc(0,0,rr,0,7); ctx.stroke();
      const ticks=10+L*6; for(let i=0;i<ticks;i++){ const a=ta+i/ticks*6.283; ctx.beginPath(); ctx.moveTo(Math.cos(a)*rr,Math.sin(a)*rr); ctx.lineTo(Math.cos(a)*(rr+5),Math.sin(a)*(rr+5)); ctx.stroke(); } }
    // faint astral spokes radiating from the centre (the all-seeing record)
    ctx.strokeStyle=`hsla(${45+drift},60%,32%,${0.05+0.05*bi})`; ctx.lineWidth=1.3;
    for(let k=0;k<18;k++){ const a=k/18*6.283 - t*0.004; ctx.beginPath(); ctx.moveTo(Math.cos(a)*24,Math.sin(a)*24); ctx.lineTo(Math.cos(a)*H*0.52,Math.sin(a)*H*0.52); ctx.stroke(); }
    // drifting glyph "pages" — little rotating diamonds rising through the records
    for(let i=0;i<16;i++){ const gx=((i*71+bgSeed*30)%W)-W/2, gy=(((i*143 - t*0.6)%H)+H)%H - H/2, r=4+i%3*2.4;
      ctx.save(); ctx.translate(gx,gy); ctx.rotate(t*0.02+i); ctx.strokeStyle=`hsla(${(i%2?266:45)+drift},60%,30%,${0.08+0.06*bi})`; ctx.lineWidth=1.3;
      ctx.beginPath(); ctx.moveTo(0,-r); ctx.lineTo(r,0); ctx.lineTo(0,r); ctx.lineTo(-r,0); ctx.closePath(); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-r*0.5,0); ctx.lineTo(r*0.5,0); ctx.stroke(); ctx.restore(); }
  }
  else { // LAIR — recursive spiked pentagram fractal, crimson + violet
    ctx.translate(cx,cy); const rot=t*0.005+bgSeed;
    for(let L=0;L<4;L++){ const rr=(0.5-L*0.1)*H, N=5, a0=rot*(L%2?1:-1); ctx.strokeStyle=`hsla(${350+L*14+drift},60%,${16+L*5}%,${0.13+0.07*bi})`; ctx.lineWidth=2.2;
      ctx.beginPath(); for(let i=0;i<=N;i++){ const a=a0+i/N*6.283, x=Math.cos(a)*rr, y=Math.sin(a)*rr; i?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.closePath(); ctx.stroke();
      if(L<2) for(let i=0;i<N;i++){ const a=a0+i/N*6.283; ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(Math.cos(a)*rr,Math.sin(a)*rr); ctx.stroke(); } }
  }
  ctx.restore();
}
