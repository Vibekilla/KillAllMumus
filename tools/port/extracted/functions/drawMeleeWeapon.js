function drawMeleeWeapon(key, len, col, charge){ ctx.lineCap='round'; ctx.lineJoin='round'; ctx.globalCompositeOperation='source-over';
  if(key==='katana'){
    // handle (tsuka) behind the hand, with diamond ito wrap + pommel
    ctx.fillStyle='#241820'; ctx.beginPath(); ctx.roundRect(-17,-3.1,27,6.2,2.6); ctx.fill();
    ctx.strokeStyle='#0d0910'; ctx.lineWidth=1; for(let wx=-14;wx<7;wx+=4){ ctx.beginPath(); ctx.moveTo(wx,-3); ctx.lineTo(wx+2.6,3); ctx.moveTo(wx+2.6,-3); ctx.lineTo(wx,3); ctx.stroke(); }
    ctx.fillStyle='#3a2a30'; ctx.beginPath(); ctx.roundRect(-20,-3.7,4,7.4,1.5); ctx.fill();
    // tsuba guard
    ctx.fillStyle='#e0b040'; ctx.beginPath(); ctx.ellipse(10,0,2.7,6.6,0,0,7); ctx.fill(); ctx.strokeStyle='#8a6a1e'; ctx.lineWidth=0.9; ctx.stroke();
    // blade — filled, curved, tapering to a kissaki, red plasma glow
    const b0=13, bl=len-b0;
    ctx.save(); ctx.shadowColor=col; ctx.shadowBlur=12+charge*8; ctx.fillStyle=col;
    ctx.beginPath(); ctx.moveTo(b0,-3.1);
    ctx.quadraticCurveTo(b0+bl*0.55,-4.8, b0+bl,-1.5);
    ctx.quadraticCurveTo(b0+bl+5,0, b0+bl,1.5);
    ctx.quadraticCurveTo(b0+bl*0.55,3.1, b0,3.1); ctx.closePath(); ctx.fill(); ctx.restore();
    ctx.strokeStyle='rgba(150,18,38,0.85)'; ctx.lineWidth=0.9; ctx.stroke();
    ctx.strokeStyle='#fff'; ctx.lineWidth=1.5; ctx.beginPath(); ctx.moveTo(b0+2,-1.4); ctx.quadraticCurveTo(b0+bl*0.55,-2.6,b0+bl-2,-0.2); ctx.stroke();   // energy core
    ctx.strokeStyle='rgba(255,190,200,0.7)'; ctx.lineWidth=0.8; ctx.beginPath(); ctx.moveTo(b0+2,2); ctx.quadraticCurveTo(b0+bl*0.55,1.7,b0+bl-2,0.6); ctx.stroke();
  } else if(key==='lash'){
    // tapered wavy tentacle built as a filled polygon, with suckers underneath
    const N=18, pts=[]; for(let i=0;i<=N;i++){ const s=len*i/N, wob=Math.sin(s*0.085+tick*0.3)*(s/len)*11, w=Math.max(1.4,7*(1-s/len*0.82)); pts.push({x:s,y:wob,w}); }
    ctx.save(); ctx.shadowColor=col; ctx.shadowBlur=9; ctx.fillStyle=col;
    ctx.beginPath(); ctx.moveTo(pts[0].x,pts[0].y-pts[0].w); for(const q of pts) ctx.lineTo(q.x,q.y-q.w); for(let i=N;i>=0;i--) ctx.lineTo(pts[i].x,pts[i].y+pts[i].w); ctx.closePath(); ctx.fill(); ctx.restore();
    ctx.strokeStyle='#4a1f7a'; ctx.lineWidth=1; ctx.stroke();
    ctx.fillStyle='#efe0ff'; for(let i=2;i<N;i+=2){ const q=pts[i], r=Math.max(0.9,q.w*0.34); ctx.beginPath(); ctx.arc(q.x,q.y+q.w*0.35,r,0,7); ctx.fill(); }
    ctx.fillStyle='#c9a0f0'; for(let i=2;i<N;i+=2){ const q=pts[i]; ctx.beginPath(); ctx.arc(q.x,q.y+q.w*0.35,Math.max(0.4,q.w*0.15),0,7); ctx.fill(); }
    ctx.strokeStyle='rgba(255,255,255,0.45)'; ctx.lineWidth=1.4; ctx.beginPath(); for(let i=0;i<=N;i++){ const q=pts[i]; if(i===0)ctx.moveTo(q.x,q.y-q.w*0.45); else ctx.lineTo(q.x,q.y-q.w*0.45); } ctx.stroke();
  } else if(key==='scythe'){
    // Ourbie's Scythe — a long dark snath with a big glowing green curved blade at the end
    const wood='#3a2c22';
    ctx.strokeStyle=wood; ctx.lineWidth=3.4; ctx.beginPath(); ctx.moveTo(-len*0.2,0); ctx.lineTo(len*0.9,0); ctx.stroke();   // snath (handle)
    ctx.fillStyle='#5a4636'; ctx.beginPath(); ctx.arc(-len*0.2,0,2,0,7); ctx.arc(len*0.42,0,1.8,0,7); ctx.fill();   // grips
    // curved reaping blade sweeping up from the tip
    ctx.save(); ctx.shadowColor=col; ctx.shadowBlur=12; ctx.fillStyle=col;
    ctx.beginPath(); ctx.moveTo(len*0.86,3);
    ctx.quadraticCurveTo(len*1.02,-4, len*0.78,-len*0.34);      // outer edge of blade
    ctx.quadraticCurveTo(len*0.7,-len*0.16, len*0.86,-1);        // inner curve back to snath
    ctx.closePath(); ctx.fill(); ctx.restore();
    ctx.strokeStyle='#1f7a3a'; ctx.lineWidth=1; ctx.stroke();
    ctx.strokeStyle='#fff'; ctx.lineWidth=1.1; ctx.beginPath(); ctx.moveTo(len*0.88,1); ctx.quadraticCurveTo(len*1.0,-4,len*0.79,-len*0.31); ctx.stroke();   // bright edge
    ctx.fillStyle='#eafff0'; ctx.beginPath(); ctx.arc(len*0.79,-len*0.32,1.6,0,7); ctx.fill();   // blade tip glint
    ctx.fillStyle='#1f7a3a'; ctx.beginPath(); ctx.arc(len*0.86,0,2.4,0,7); ctx.fill();   // blade mount
  } else if(key==='hammer'){
    const hlen=len*0.64;
    // wooden handle + grip wrap
    ctx.fillStyle='#7a5326'; ctx.beginPath(); ctx.roundRect(-17,-3,hlen+17,6,2.6); ctx.fill(); ctx.strokeStyle='#4a3214'; ctx.lineWidth=0.9; ctx.stroke();
    ctx.fillStyle='#5a3a1a'; ctx.beginPath(); ctx.roundRect(-17,-3,14,6,2.6); ctx.fill();
    ctx.strokeStyle='#2a1c0e'; ctx.lineWidth=1; for(let gx=-15;gx<-3;gx+=3){ ctx.beginPath(); ctx.moveTo(gx,-3); ctx.lineTo(gx+1.6,3); ctx.stroke(); }
    // gold head with highlight/shade, banding, ◈ gem, rivets
    ctx.save(); ctx.translate(hlen+8,0); ctx.shadowColor=col; ctx.shadowBlur=11;
    ctx.fillStyle=col; ctx.beginPath(); ctx.roundRect(-5,-15,22,30,4); ctx.fill(); ctx.shadowBlur=0;
    ctx.fillStyle='rgba(255,248,210,0.5)'; ctx.beginPath(); ctx.roundRect(-5,-15,22,7,4); ctx.fill();
    ctx.fillStyle='rgba(120,86,20,0.45)'; ctx.beginPath(); ctx.roundRect(-5,9,22,6,4); ctx.fill();
    ctx.strokeStyle='#a9791e'; ctx.lineWidth=1.4; ctx.beginPath(); ctx.roundRect(-5,-15,22,30,4); ctx.stroke();
    ctx.fillStyle='#fff8e0'; ctx.beginPath(); ctx.moveTo(9,-8); ctx.lineTo(15,0); ctx.lineTo(9,8); ctx.lineTo(3,0); ctx.closePath(); ctx.fill(); ctx.strokeStyle='#c9992e'; ctx.lineWidth=1; ctx.stroke();
    ctx.fillStyle='#8a6a1e'; for(const ry of [-11,11]){ ctx.beginPath(); ctx.arc(-1,ry,1.4,0,7); ctx.fill(); }
    ctx.restore();
  } else if(key==='claws'){
    // gauntlet cuff + knuckle plate + three tapered hooked claws
    ctx.fillStyle='#2c2620'; ctx.beginPath(); ctx.roundRect(-10,-9,20,18,4); ctx.fill(); ctx.strokeStyle='#4a3a28'; ctx.lineWidth=1; ctx.stroke();
    ctx.fillStyle='#3c3228'; ctx.beginPath(); ctx.roundRect(3,-8,9,16,3); ctx.fill();
    ctx.fillStyle='#5a4a34'; for(const ky of [-4,0,4]){ ctx.beginPath(); ctx.arc(7,ky,1.3,0,7); ctx.fill(); }
    ctx.save(); ctx.shadowColor=col; ctx.shadowBlur=8;
    for(let c=-1;c<=1;c++){ const y0=c*5.5, cl=len-10, tipx=10+cl, tipy=y0+c*9;
      ctx.fillStyle=col; ctx.beginPath(); ctx.moveTo(10,y0-2.8); ctx.quadraticCurveTo(10+cl*0.6,y0+c*5,tipx,tipy); ctx.quadraticCurveTo(10+cl*0.45,y0+c*4,10,y0+2.8); ctx.closePath(); ctx.fill();
      ctx.strokeStyle='#c9992e'; ctx.lineWidth=0.8; ctx.stroke();
      ctx.strokeStyle='rgba(255,255,255,0.7)'; ctx.lineWidth=0.9; ctx.beginPath(); ctx.moveTo(12,y0-1.9); ctx.quadraticCurveTo(10+cl*0.6,y0+c*5,tipx,tipy); ctx.stroke(); }
    ctx.restore();
  } else { ctx.fillStyle=col; ctx.shadowColor=col; ctx.shadowBlur=10; ctx.beginPath(); ctx.roundRect(8,-2.5,len-8,5,2); ctx.fill(); ctx.shadowBlur=0; }
}
