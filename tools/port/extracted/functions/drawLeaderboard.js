function drawLeaderboard(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#1a0e26'); g.addColorStop(1,'#2a1020'); ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  ctx.textAlign='center';
  const P=portrait;   // portrait: compress the 584px-wide table + shrink the title so nothing clips off a phone screen
  ctx.save(); ctx.shadowColor='#ffd27a'; ctx.shadowBlur=20; ctx.fillStyle='#ffe08a'; ctx.font='900 '+(P?24:40)+'px "Trebuchet MS"'; ctx.fillText('🏆 GLOBAL LEADERBOARD', W/2, P?42:60); ctx.restore();
  ctx.fillStyle='#c8b0d0'; ctx.font=(P?10:12)+'px monospace'; ctx.fillText(P?'Top Mumu Slayers · Powered by Emblem Vault':'Top Mumu Slayers worldwide · Powered by Emblem Vault', W/2, P?60:82);
  const list=lbCache, x0=P?14:W/2-292; let y=P?90:116; lbRows=[];
  const oFit=P?20:26, oHandle=P?50:58, oIcon=P?28:34, oScore=P?300:330, oMumus=P?388:430, oRank=P?446:500, oMode=P?512:584, rowH=P?23:25, rf=P?12:14;
  ctx.textAlign='left'; ctx.fillStyle='#8fd0ff'; ctx.font='bold '+(P?10:12)+'px monospace';
  ctx.fillText('#', x0, y); ctx.fillText('FIT', x0+oFit, y); ctx.fillText(P?'PLAYER':'PLAYER (tap profile)', x0+oHandle, y);
  ctx.textAlign='right'; ctx.fillText('SCORE', x0+oScore, y); ctx.fillText('MUMUS', x0+oMumus, y); ctx.fillText('RANK', x0+oRank, y); ctx.fillText('MODE', x0+oMode, y);
  ctx.textAlign='left'; ctx.strokeStyle='rgba(255,255,255,0.15)'; ctx.beginPath(); ctx.moveTo(x0,y+7); ctx.lineTo(x0+oMode,y+7); ctx.stroke(); y+=26;
  if(lbState==='loading' && !list.length){ ctx.textAlign='center'; ctx.fillStyle='#9a7c96'; ctx.font='16px "Trebuchet MS"'; ctx.fillText('Loading global scores'+'.'.repeat(1+Math.floor(tick/20)%3), W/2, y+50); }
  else if(lbState==='error'){ ctx.textAlign='center'; ctx.fillStyle='#ff8a8a'; ctx.font='15px "Trebuchet MS"'; ctx.fillText('Couldn’t reach the leaderboard server. Try again.', W/2, y+50); }
  else if(!list.length){ ctx.textAlign='center'; ctx.fillStyle='#9a7c96'; ctx.font='16px "Trebuchet MS"'; ctx.fillText('No scores yet — be the first to exterminate some Mumus!', W/2, y+50); }
  else { if(lbPage>=lbPageCount()) lbPage=lbPageCount()-1;
    const start=lbPage*LB_PER_PAGE, pageItems=list.slice(start, start+LB_PER_PAGE);
    for(let i=0;i<pageItems.length;i++){ const e=pageItems[i], rank=start+i, hot=lbIsMine(e);
      if(hot){ ctx.fillStyle='rgba(255,90,140,0.2)'; ctx.fillRect(x0-6,y-15,(P?W-16:616),23); }
      ctx.font=(hot?'bold ':'')+rf+'px monospace';
      ctx.fillStyle=hot?'#fff':(rank<3?['#ffd700','#c8ccd4','#cd7f32'][rank]:'#c8b0c4');
      ctx.textAlign='left'; ctx.fillText(String(rank+1), x0, y);
      const _fit=OUTFITS.some(o=>o.key===e.outfit)?e.outfit:'og';   // data-driven: any outfit in OUTFITS renders (incl. new ones); unknown → og
      ctx.save(); ctx.translate(x0+oIcon, y-3.5); ctx.scale(P?0.42:0.46,P?0.42:0.46); try{ drawBobina({x:0,y:0,iframe:0,focus:false,walk:0,bombFx:0,face:-Math.PI/2,vx:0,vy:0,outfit:_fit}); }catch(_e){} ctx.restore();   // actual Bobina in the outfit she wore this run
      ctx.textAlign='left'; ctx.font=(hot?'bold ':'')+rf+'px monospace';   // drawBobina left ctx state dirty — reset for the row text
      const linked=!!e.bcId || !!e.linked;
      const disp=(linked ? (e.name || (e.bobinaUsername?('@'+e.bobinaUsername):'Bobina')) : (e.handle?('@'+e.handle):(e.name||'Anon'))).slice(0,P?13:16);
      const purl=e.profileUrl || (e.bobinaUsername?('https://bobina.moe/'+e.bobinaUsername):null) || (e.handle?('https://x.com/'+e.handle):null);
      if(purl){ ctx.fillStyle=linked?'#ff9ecb':'#7ec8ff'; ctx.fillText(disp, x0+oHandle, y); const tw=ctx.measureText(disp).width; ctx.strokeStyle=linked?'rgba(255,158,203,0.55)':'rgba(126,200,255,0.5)'; ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(x0+oHandle,y+2); ctx.lineTo(x0+oHandle+tw,y+2); ctx.stroke(); lbRows.push({x:x0+oHandle-6,y:y-13,w:tw+12,h:19,handle:e.handle,profileUrl:purl,bobinaUsername:e.bobinaUsername}); }
      else ctx.fillText(disp, x0+oHandle, y);
      ctx.textAlign='right'; ctx.fillStyle=hot?'#fff':'#c8b0c4'; ctx.fillText(fmtScore(e.score), x0+oScore, y); ctx.fillText(fmtScore(e.kills), x0+oMumus, y); ctx.fillText(e.rank||'-', x0+oRank, y);
      const _md=e.mode||'NORMAL'; ctx.fillStyle=_md.indexOf('HELL')===0?'#ff2a2a':(_md.indexOf('HARD')===0?'#ff5b6e':(hot?'#fff':'#8fd0a0')); ctx.font=(hot?'bold ':'')+(P?11:13)+'px monospace'; ctx.fillText(_md, x0+oMode, y); ctx.font=(hot?'bold ':'')+rf+'px monospace';
      ctx.textAlign='left'; y+=rowH;
    }
    // pagination controls
    const pc=lbPageCount();
    if(pc>1){ const ny=H-58, bw=94, bh=28;
      lbPrevBtn={x:W/2-150,y:ny,w:bw,h:bh}; lbNextBtn={x:W/2+56,y:ny,w:bw,h:bh};
      const navBtn=(b,label,on)=>{ ctx.fillStyle=on?'rgba(40,20,50,0.9)':'rgba(30,18,38,0.4)'; ctx.beginPath(); ctx.roundRect(b.x,b.y,b.w,b.h,7); ctx.fill(); ctx.strokeStyle=on?'#ff8ac0':'rgba(255,140,200,0.25)'; ctx.lineWidth=1.5; ctx.stroke(); ctx.fillStyle=on?'#ffd6ea':'#6a5a72'; ctx.font='bold 13px monospace'; ctx.textAlign='center'; ctx.fillText(label, b.x+b.w/2, b.y+18); ctx.textAlign='left'; };
      navBtn(lbPrevBtn,'◀ PREV', lbPage>0); navBtn(lbNextBtn,'NEXT ▶', lbPage<pc-1);
      ctx.textAlign='center'; ctx.fillStyle='#c8b0d0'; ctx.font='bold 13px monospace'; ctx.fillText('Page '+(lbPage+1)+' / '+pc, W/2, H-40); ctx.textAlign='left';
    } else { lbPrevBtn=lbNextBtn=null; }
  }
  if(lbState==='ok' && lastSubmit){ ctx.textAlign='center'; ctx.fillStyle='#ff9ecb'; ctx.font='italic 12px "Trebuchet MS"'; ctx.fillText('★ your run is highlighted — flex it on X!', W/2, H-72); }
  ctx.textAlign='center'; ctx.fillStyle=(Math.floor(tick/30)%2)?'#fff':'#9a7c96'; ctx.font='bold 15px monospace'; ctx.fillText('PRESS '+kb('shoot')+' / TAP EMPTY AREA TO RETURN', W/2, H-16); ctx.textAlign='left';
}
