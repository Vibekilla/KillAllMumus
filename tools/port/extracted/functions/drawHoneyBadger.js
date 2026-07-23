function drawHoneyBadger(cx, cy, s){ ctx.save(); ctx.translate(cx,cy); ctx.scale(s,s);
  const fur='#2a2721', furD='#16140e', furM='#3a352c', cheek='#3d362b';
  const hc={x:0,y:-22};   // head centre
  const rnd=(i,seed)=>{ const j=Math.sin(i*12.9898+seed*78.233)*43758.5453; return j-Math.floor(j); };   // deterministic per-strand jitter (no per-frame flicker)
  // ground shadow
  ctx.fillStyle='rgba(0,0,0,0.22)'; ctx.beginPath(); ctx.ellipse(0,44,29,7,0,0,7); ctx.fill();
  // --- small body tucked below (keeps him a standing shopkeeper; head dominates like the ref) ---
  ctx.fillStyle=furD; ctx.beginPath(); ctx.ellipse(0,26,26,20,0,0,7); ctx.fill();
  ctx.beginPath(); ctx.ellipse(-13,40,8,6,0,0,7); ctx.ellipse(13,40,8,6,0,0,7); ctx.fill();   // paws
  ctx.strokeStyle='rgba(0,0,0,0.4)'; ctx.lineWidth=0.9; ctx.lineCap='round'; ctx.beginPath(); for(const px of [-16,-13,-10,10,13,16]){ ctx.moveTo(px,42); ctx.lineTo(px,38); } ctx.stroke();
  // --- ears (dark, mostly buried in the crest) ---
  ctx.fillStyle=furD; ctx.beginPath(); ctx.arc(-31,-38,9,0,7); ctx.arc(31,-38,9,0,7); ctx.fill();
  // --- wide furry head + drooping jowls/cheeks ---
  ctx.fillStyle=fur;
  ctx.beginPath(); ctx.ellipse(hc.x,hc.y,37,33,0,0,7); ctx.fill();                                   // head
  ctx.beginPath(); ctx.ellipse(-27,3,15,19,0.22,0,7); ctx.ellipse(27,3,15,19,-0.22,0,7); ctx.fill(); // drooping jowls
  ctx.beginPath(); ctx.ellipse(0,7,31,24,0,0,7); ctx.fill();                                         // lower-face fill blends jowls
  ctx.fillStyle=cheek; ctx.beginPath(); ctx.ellipse(-21,3,11,12,0,0,7); ctx.ellipse(21,3,11,12,0,0,7); ctx.fill();   // faint lighter cheeks
  // --- fuzzy fur tufts around the lower silhouette ---
  ctx.fillStyle=fur;
  const tufts=[[-38,-6],[-40,6],[-36,17],[-28,25],[-18,29],[-6,31],[6,31],[18,29],[28,25],[36,17],[40,6],[38,-6]];
  for(let i=0;i<tufts.length-1;i++){ const p=tufts[i], nx=tufts[i+1], mx=(p[0]+nx[0])/2, my=(p[1]+nx[1])/2; ctx.beginPath(); ctx.moveTo(p[0],p[1]); ctx.lineTo(mx+mx*0.12,my+my*0.12); ctx.lineTo(nx[0],nx[1]); ctx.closePath(); ctx.fill(); }
  // short fur strokes for texture on the face
  ctx.strokeStyle=furD; ctx.lineWidth=0.8; ctx.beginPath();
  for(let i=0;i<11;i++){ const a=(-160+i*15)*Math.PI/180, bx=hc.x+Math.cos(a)*30, by=hc.y+Math.sin(a)*27; ctx.moveTo(bx,by); ctx.lineTo(bx+Math.cos(a)*5, by+Math.sin(a)*5); } ctx.stroke();

  // --- soft, fluffy white fur crest: a DENSE fluffy cap; the "wild" look is fine short texture, not spikes ---
  const cc={x:0,y:-44};
  const puffs=[[-31,-30,9],[-33,-24,7],[-26,-38,11],[-18,-45,12],[-9,-50,13],[0,-52,13],[9,-50,13],[18,-45,12],[26,-38,11],[31,-30,9],[33,-24,7],[-13,-42,11],[13,-42,11],[0,-43,13]];
  ctx.fillStyle='#c3c7d3'; for(const m of puffs){ ctx.beginPath(); ctx.arc(m[0],m[1]+3,m[2],0,7); ctx.fill(); }              // depth shadow under the fluff
  ctx.fillStyle='#e9ebf1'; for(const m of puffs){ ctx.beginPath(); ctx.arc(m[0],m[1],m[2],0,7); ctx.fill(); }                // main white fluff
  ctx.fillStyle='#f6f8fc'; for(const m of puffs){ ctx.beginPath(); ctx.arc(m[0]-1.5,m[1]-1.8,m[2]*0.6,0,7); ctx.fill(); }    // soft top highlight on each puff → dimensional fluff
  // fine short brushed strokes for a wild, hairy texture (kept SHORT so the cap stays soft, never spiky)
  ctx.lineCap='round';
  for(let i=0;i<52;i++){ const jr=rnd(i,1), jr2=rnd(i,3), ang=(-180+(i/51)*180)*Math.PI/180;
    const rr=6+jr*19, bx=cc.x+Math.cos(ang)*rr, by=cc.y+Math.sin(ang)*rr*0.6, ln=2.5+jr2*3;
    ctx.strokeStyle = jr<0.32?'rgba(150,156,172,0.5)':'rgba(255,255,255,0.72)';
    ctx.lineWidth=0.7; ctx.beginPath(); ctx.moveTo(bx,by); ctx.lineTo(bx+Math.cos(ang)*ln, by+Math.sin(ang)*ln-1); ctx.stroke();
  }
  // just a few soft fuzzy tufts barely breaking the top edge (short + thin)
  for(let i=0;i<8;i++){ const f=i/7, ang=(-152+f*124)*Math.PI/180, jr=rnd(i,7);
    const bx=cc.x+Math.cos(ang)*16, by=cc.y+Math.sin(ang)*11-1, len=2+jr*4;
    ctx.strokeStyle='rgba(236,238,244,0.85)'; ctx.lineWidth=1.1; ctx.beginPath(); ctx.moveTo(bx,by); ctx.lineTo(bx+Math.cos(ang)*len, by+Math.sin(ang)*len-1.5); ctx.stroke();
  }

  // --- face ---
  const ex=10.5, ey=-19, erx=8.2, ery=9.6;
  // soft reddish glow under the eyes
  ctx.fillStyle='rgba(180,70,80,0.38)'; ctx.beginPath(); ctx.ellipse(-ex,ey+6,7,5,0,0,7); ctx.ellipse(ex,ey+6,7,5,0,0,7); ctx.fill();
  // eye sockets seat the big glossy eyes
  ctx.fillStyle=furD; ctx.beginPath(); ctx.ellipse(-ex,ey,erx+1.4,ery+1.4,0,0,7); ctx.ellipse(ex,ey,erx+1.4,ery+1.4,0,0,7); ctx.fill();
  ctx.fillStyle='#0c0b10'; ctx.beginPath(); ctx.ellipse(-ex,ey,erx,ery,0,0,7); ctx.ellipse(ex,ey,erx,ery,0,0,7); ctx.fill();
  // reddish inner-lower reflection
  ctx.fillStyle='rgba(150,50,60,0.5)'; ctx.beginPath(); ctx.ellipse(-ex,ey+3.6,erx*0.6,ery*0.42,0,0,7); ctx.ellipse(ex,ey+3.6,erx*0.6,ery*0.42,0,0,7); ctx.fill();
  // big catchlight + small sparkle + tiny top glint
  ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(-ex-2.6,ey-3.6,3.0,0,7); ctx.arc(ex-2.6,ey-3.6,3.0,0,7); ctx.fill();
  ctx.fillStyle='rgba(255,255,255,0.9)'; ctx.beginPath(); ctx.arc(-ex+3.4,ey+3.8,1.5,0,7); ctx.arc(ex+3.4,ey+3.8,1.5,0,7); ctx.fill();
  ctx.beginPath(); ctx.arc(-ex+1.7,ey-4.8,0.9,0,7); ctx.arc(ex+1.7,ey-4.8,0.9,0,7); ctx.fill();
  // blush (stronger on the right cheek, like the ref)
  ctx.fillStyle='rgba(210,90,110,0.4)'; ctx.beginPath(); ctx.ellipse(-19,-8,6,3.8,0,0,7); ctx.fill();
  ctx.fillStyle='rgba(216,78,98,0.6)'; ctx.beginPath(); ctx.ellipse(19,-7,7.5,4.6,0,0,7); ctx.fill();
  // little glossy pink nose, low between the eyes
  ctx.fillStyle='#e56b86'; ctx.beginPath(); ctx.moveTo(-4.4,-12); ctx.quadraticCurveTo(0,-9.5,4.4,-12); ctx.quadraticCurveTo(4.4,-7,0,-5); ctx.quadraticCurveTo(-4.4,-7,-4.4,-12); ctx.closePath(); ctx.fill();
  ctx.fillStyle='rgba(255,200,215,0.9)'; ctx.beginPath(); ctx.ellipse(-1.4,-10.6,1.5,1.1,0,0,7); ctx.fill();
  // tiny dark mouth
  ctx.strokeStyle='#1c1418'; ctx.lineWidth=1.4; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(0,-5); ctx.lineTo(0,-3); ctx.moveTo(-3,-2.4); ctx.quadraticCurveTo(0,-1,3,-2.4); ctx.stroke();
  ctx.restore();
}
