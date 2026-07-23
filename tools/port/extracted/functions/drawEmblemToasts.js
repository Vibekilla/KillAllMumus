function drawEmblemToasts(){ if(!emblemToasts.length) return;
  const e=emblemToasts[0], d=emblemDef(e.id); if(!d){ emblemToasts.shift(); return; }
  e.t++; const T=e.t, dur=210; let a=1;
  if(T<16) a=T/16; else if(T>dur-22) a=Math.max(0,(dur-T)/22);
  const w=308,h=54,x=W/2-w/2,y=14;
  ctx.save(); ctx.globalAlpha=a;
  ctx.fillStyle='rgba(18,10,26,0.96)'; ctx.beginPath(); ctx.roundRect(x,y,w,h,12); ctx.fill();
  ctx.strokeStyle='#ffd27a'; ctx.lineWidth=2; ctx.shadowColor='#ffd27a'; ctx.shadowBlur=14; ctx.stroke(); ctx.shadowBlur=0;
  ctx.textAlign='left'; ctx.font='26px serif'; ctx.fillText(d.icon||'🏅', x+14, y+36);
  ctx.fillStyle='#ffe08a'; ctx.font='bold 10px monospace'; ctx.fillText('★  EMBLEM UNLOCKED', x+52, y+19);
  ctx.fillStyle='#fff'; ctx.font='bold 15px "Trebuchet MS"'; ctx.fillText(d.name, x+52, y+38);
  if(d.outfit){ ctx.fillStyle='#8fd0a0'; ctx.font='bold 9px monospace'; ctx.textAlign='right'; ctx.fillText('👗 SKIN', x+w-12, y+19); ctx.textAlign='left'; }
  ctx.restore();
  if(T>=dur) emblemToasts.shift();
}
