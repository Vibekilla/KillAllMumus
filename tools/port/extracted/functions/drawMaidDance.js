function drawMaidDance(){
  unlockEmblem('afk_dance');   // secret: you idled long enough to catch her dancing
  const t=tick;
  ctx.save();
  // dim the menu behind + soft stage vignette
  ctx.fillStyle='rgba(8,4,14,0.86)'; ctx.fillRect(0,0,W,H);
  // spotlight cone
  const g=ctx.createRadialGradient(W/2,150,10,W/2,320,260); g.addColorStop(0,'rgba(255,180,230,0.28)'); g.addColorStop(1,'rgba(255,180,230,0)');
  ctx.fillStyle=g; ctx.beginPath(); ctx.moveTo(W/2-60,110); ctx.lineTo(W/2+60,110); ctx.lineTo(W/2+200,H-40); ctx.lineTo(W/2-200,H-40); ctx.closePath(); ctx.fill();
  // dance-floor shimmer
  ctx.fillStyle='rgba(255,120,190,0.14)'; ctx.beginPath(); ctx.ellipse(W/2,360,130,26,0,0,7); ctx.fill();
  // floating notes + hearts
  ctx.textAlign='center';
  for(let i=0;i<10;i++){ const base=(t*0.7+i*70); const ny=110+(((H-160)-(base%(H-160)))); const nx=W/2+Math.sin(t*0.03+i*1.3)*(90+i*13); ctx.globalAlpha=0.5+0.3*Math.sin(t*0.1+i);
    ctx.fillStyle=['#ff9ecb','#ffd27a','#8fd0ff','#b8f08a'][i%4]; ctx.font='bold '+(18+i%3*4)+'px monospace'; ctx.fillText(['♪','♫','♥','✦','♬'][i%5], nx, ny); }
  ctx.globalAlpha=1;
  // dancing maid Bobina — bounce, sway, tilt + pumping limbs (fake velocity drives the animation)
  const bounce=Math.abs(Math.sin(t*0.15))*11, sway=Math.sin(t*0.11)*16, tilt=Math.sin(t*0.11)*0.13;
  ctx.save(); ctx.translate(W/2+sway, 340-bounce); ctx.rotate(tilt); ctx.scale(4.6,4.6);
  drawBobina({x:0,y:0,iframe:0,focus:false,walk:0,bombFx:0,face:-Math.PI/2, vx:Math.sin(t*0.3)*3.6, vy:Math.cos(t*0.42)*1.6, lean:Math.sin(t*0.11)*0.5, outfit:selectedOutfit, expr:'uwu'});
  ctx.restore();
  // message
  ctx.fillStyle=(Math.floor(t/24)%2)?'#fff':'#ff9ecb'; ctx.font='900 27px "Trebuchet MS"'; ctx.shadowColor='#ff2b6e'; ctx.shadowBlur=14;
  ctx.fillText('♪  Don’t mind me… waiting for you to play!  ♪', W/2, H-34); ctx.shadowBlur=0;
  ctx.fillStyle='#c8b0d0'; ctx.font='13px monospace'; ctx.fillText('— tap / press any key to start —', W/2, 96);
  ctx.textAlign='left'; ctx.restore();
}
