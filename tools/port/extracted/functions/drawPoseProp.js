function drawPoseProp(p, t){
  if(p===5){ // "This Is Fine" — fire all around; the cup sits in her real raised orb hand (the arm itself is drawn by drawBobina)
    const h=coffeeHold(t), sip=h.sip;
    const flame=(fx,fby,fl,i)=>{ const gr=ctx.createLinearGradient(fx,fby,fx,fby-fl); gr.addColorStop(0,'#ff2e00'); gr.addColorStop(0.5,'#ff8a12'); gr.addColorStop(1,'rgba(255,220,90,0)');
      ctx.fillStyle=gr; ctx.beginPath(); ctx.moveTo(fx-fl*0.18-0.6,fby); ctx.quadraticCurveTo(fx-0.8,fby-fl*0.6, fx+Math.sin(t*0.22+i)*1.3,fby-fl); ctx.quadraticCurveTo(fx+0.8,fby-fl*0.6, fx+fl*0.18+0.6,fby); ctx.closePath(); ctx.fill(); };
    for(let i=0;i<12;i++){ const fa=i/12*6.283, ring=(i%2?12:9.5), fx=Math.cos(fa)*ring, fby=17+Math.sin(fa)*4.5;   // ring of fire around her base
      flame(fx,fby,(4.5+(i%3)*2.4)*(0.55+0.45*Math.abs(Math.sin(t*0.3+i*1.7))),i); }
    for(const sx of [-13.5,13.5]) flame(sx,14,13+Math.abs(Math.sin(t*0.25+sx))*6, sx);   // tall flames flanking her
    // the coffee mug, cradled between both orb hands (at h.x, h.y)
    ctx.save(); ctx.translate(h.x, h.y-0.6);
    ctx.fillStyle='#f4efe6'; ctx.beginPath(); ctx.moveTo(-2.4,-2.2); ctx.lineTo(2.4,-2.2); ctx.lineTo(1.9,2.3); ctx.lineTo(-1.9,2.3); ctx.closePath(); ctx.fill(); ctx.strokeStyle='#b89a68'; ctx.lineWidth=0.6; ctx.stroke();
    ctx.fillStyle='#4a2c14'; ctx.beginPath(); ctx.ellipse(0,-2.2,2.3,0.7,0,0,7); ctx.fill();
    ctx.strokeStyle='#f4efe6'; ctx.lineWidth=0.9; ctx.beginPath(); ctx.arc(2.7,0.2,1.3,-1,1.7); ctx.stroke();   // handle
    if(sip<0.5){ ctx.strokeStyle='rgba(255,255,255,0.4)'; ctx.lineWidth=0.5; for(let i=-1;i<=1;i++){ ctx.beginPath(); for(let s=0;s<=1;s+=0.25){ const yy=-2.6-s*4, xx=i*1.1+Math.sin(s*6+t*0.1+i)*0.8; s?ctx.lineTo(xx,yy):ctx.moveTo(xx,yy); } ctx.stroke(); } }
    ctx.restore(); }
}
