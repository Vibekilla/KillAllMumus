function drawEmblems(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#1a0e26'); g.addColorStop(1,'#2a1020'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  ctx.textAlign='center';
  ctx.save(); ctx.shadowColor='#ffd27a'; ctx.shadowBlur=18; ctx.fillStyle='#ffe08a'; ctx.font='900 34px "Trebuchet MS"'; ctx.fillText('🏅 EMBLEMS', W/2, 44); ctx.restore();
  ctx.fillStyle='#c8b0d0'; ctx.font='12px monospace'; ctx.fillText('Achievements · '+emblemCount()+' / '+EMBLEMS.length+' unlocked · some grant skins', W/2, 64);
  const pbw=460, pbx=W/2-pbw/2; ctx.fillStyle='#2a1a30'; ctx.beginPath(); ctx.roundRect(pbx,72,pbw,7,3); ctx.fill();
  ctx.fillStyle='#ffd27a'; ctx.beginPath(); ctx.roundRect(pbx,72,pbw*emblemCount()/EMBLEMS.length,7,3); ctx.fill();
  if(emPage>=emPageCount()) emPage=emPageCount()-1;
  // paginated grid — 4×3 roomy cards per page
  const cols=4, rows=3, gap=8, gy=90, botY=H-56, gx=24;
  const cw=(W-2*gx)/cols, ch=Math.min(92,(botY-gy-(rows-1)*gap)/rows);
  const start=emPage*EM_PER_PAGE, pageItems=EMBLEMS.slice(start, start+EM_PER_PAGE);
  for(let i=0;i<pageItems.length;i++){ const e=pageItems[i], got=hasEmblem(e.id), secret=e.secret&&!got;
    const cx=gx+(i%cols)*cw, cy=gy+Math.floor(i/cols)*(ch+gap);
    ctx.fillStyle=got?'rgba(255,210,120,0.12)':'rgba(255,255,255,0.03)'; ctx.beginPath(); ctx.roundRect(cx+3,cy,cw-6,ch,10); ctx.fill();
    ctx.strokeStyle=got?'rgba(255,210,120,0.55)':'rgba(255,255,255,0.08)'; ctx.lineWidth=1.3; ctx.stroke();
    ctx.textAlign='center'; ctx.globalAlpha=got?1:0.35; ctx.font='26px serif'; ctx.fillText(got?(e.icon||'🏅'):'🔒', cx+27, cy+30); ctx.globalAlpha=1;
    ctx.fillStyle=got?'#ffe08a':'#8a7a92'; ctx.font='bold 12px "Trebuchet MS"'; ctx.textAlign='left'; ctx.fillText((secret?'???':e.name).slice(0,20), cx+46, cy+20);
    ctx.fillStyle=got?'#d0c0da':'#6a5a72'; ctx.font='9px monospace'; wrapText(secret?'Hidden — keep playing.':e.desc, cx+46, cy+34, cw-54, 10);
    if(e.outfit && !secret){ const sn=(OUTFITS.find(o=>o.key===e.outfit)||{}).name||e.outfit; ctx.fillStyle=got?'#8fd0a0':'#6a7a6a'; ctx.font='bold 8.5px monospace'; ctx.fillText((got?'👗 ':'👗 ')+sn, cx+46, cy+ch-8); }
  }
  // pager
  const pc=emPageCount();
  if(pc>1){ const ny=H-46, bw=94, bh=28; emPrevBtn={x:W/2-150,y:ny,w:bw,h:bh}; emNextBtn={x:W/2+56,y:ny,w:bw,h:bh};
    const navBtn=(b,label,on)=>{ ctx.fillStyle=on?'rgba(40,20,50,0.9)':'rgba(30,18,38,0.4)'; ctx.beginPath(); ctx.roundRect(b.x,b.y,b.w,b.h,7); ctx.fill(); ctx.strokeStyle=on?'#ff8ac0':'rgba(255,140,200,0.25)'; ctx.lineWidth=1.5; ctx.stroke(); ctx.fillStyle=on?'#ffd6ea':'#6a5a72'; ctx.font='bold 13px monospace'; ctx.textAlign='center'; ctx.fillText(label, b.x+b.w/2, b.y+18); ctx.textAlign='left'; };
    navBtn(emPrevBtn,'◀ PREV', emPage>0); navBtn(emNextBtn,'NEXT ▶', emPage<pc-1);
    ctx.textAlign='center'; ctx.fillStyle='#c8b0d0'; ctx.font='bold 13px monospace'; ctx.fillText('Page '+(emPage+1)+' / '+pc, W/2, H-28); ctx.textAlign='left';
  } else { emPrevBtn=emNextBtn=null; }
  ctx.textAlign='center'; ctx.fillStyle=(Math.floor(tick/30)%2)?'#fff':'#9a7c96'; ctx.font='bold 13px monospace'; ctx.fillText('PRESS '+kb('shoot')+' / TAP EMPTY AREA TO RETURN', W/2, H-8); ctx.textAlign='left';
}
