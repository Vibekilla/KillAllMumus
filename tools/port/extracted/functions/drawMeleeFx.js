function drawMeleeFx(){
  for(const f of meleeFx){ const pr=f.t/f.life;
    if(f.bolt){ const al=1-pr; ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.strokeStyle=f.col; ctx.shadowColor=f.col; ctx.shadowBlur=8; ctx.lineCap='round'; ctx.lineJoin='round'; ctx.globalAlpha=al;
      ctx.lineWidth=2.4; for(let i=1;i<f.pts.length;i++){ const a=f.pts[i-1], b=f.pts[i]; ctx.beginPath(); ctx.moveTo(a.x,a.y); for(let s=1;s<=4;s++){ const tt=s/4; ctx.lineTo(a.x+(b.x-a.x)*tt+(Math.random()-.5)*9, a.y+(b.y-a.y)*tt+(Math.random()-.5)*9); } ctx.stroke(); }
      ctx.shadowBlur=0; ctx.strokeStyle='#fff'; ctx.lineWidth=1; for(let i=1;i<f.pts.length;i++){ const a=f.pts[i-1], b=f.pts[i]; ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y); ctx.stroke(); }
      ctx.restore(); ctx.globalAlpha=1; continue; }
    if(f.ring){ const r=f.r0+(f.r1-f.r0)*pr, al=1-pr; ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.translate(f.x,f.y); ctx.lineWidth=5*(1-pr)+1;
      if(f.rainbow){ const base=(tick*4)%360, segs=24; for(let s=0;s<segs;s++){ const a0=s/segs*6.283, a1=(s+1)/segs*6.283+0.02, hue=(base+s/segs*360)%360; ctx.strokeStyle=`hsla(${hue},100%,64%,${al*0.85})`; ctx.beginPath(); ctx.arc(0,0,r,a0,a1); ctx.stroke(); } }
      else { ctx.strokeStyle=f.col; ctx.shadowColor=f.col; ctx.shadowBlur=16; ctx.globalAlpha=al*0.75; ctx.beginPath(); ctx.arc(0,0,r,0,7); ctx.stroke();
        ctx.globalAlpha=al; ctx.strokeStyle='#fff'; ctx.lineWidth=1.5; ctx.beginPath(); ctx.arc(0,0,r*0.96,0,7); ctx.stroke(); }
      ctx.restore(); ctx.globalAlpha=1; continue; }
    const rad=f.reach*(0.55+pr*0.45), a0=f.dir-f.half, a1=f.dir+f.half, al=1-pr;
    ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.translate(f.x,f.y); ctx.lineCap='round'; ctx.lineJoin='round';
    ctx.globalAlpha=al*0.8; ctx.strokeStyle=f.col; ctx.lineWidth=6+f.charge*9; ctx.shadowColor=f.col; ctx.shadowBlur=16;   // slash crescent
    ctx.beginPath(); ctx.arc(0,0,rad,a0,a1); ctx.stroke();
    ctx.globalAlpha=al; ctx.strokeStyle='#fff'; ctx.lineWidth=2.2; ctx.beginPath(); ctx.arc(0,0,rad*0.98,a0,a1); ctx.stroke();
    const swing=a0 + Math.min(1,pr*1.2)*(a1-a0);   // the weapon sweeps through the arc
    ctx.rotate(swing); ctx.globalAlpha=Math.max(0.22,1-pr*0.62); ctx.shadowBlur=10;
    drawMeleeWeapon(f.key, f.reach*0.92, f.col, f.charge);
    ctx.restore(); ctx.globalAlpha=1; }
  const p=player; if(p && !p.dead && p.meleeHeld && (p.meleeChg||0)>0.04){ const m=MELEE[p.melee||0]||MELEE[0], c=p.meleeChg, _mc=bodyCtr(p);
    ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.translate(_mc.x,_mc.y); ctx.strokeStyle=m.col; ctx.shadowColor=m.col; ctx.shadowBlur=10; ctx.lineCap='round';
    ctx.globalAlpha=0.5+0.4*c; ctx.lineWidth=2.6; ctx.beginPath(); ctx.arc(0,0,15+c*7,-Math.PI/2,-Math.PI/2+c*Math.PI*2); ctx.stroke();
    if(c>=1){ ctx.globalAlpha=0.5+0.4*Math.sin(tick*0.5); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(0,0,24,0,7); ctx.stroke(); }
    ctx.restore(); ctx.globalAlpha=1; }
}
