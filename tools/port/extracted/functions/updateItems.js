function updateItems(){
  const p=player, autoAll = p && !p.dead && p.y<COLLECT_LINE;
  const magnet = p&&p.focus?150:70;
  for(const it of items){ it.t++;
    if(p && !p.dead){ const dx=p.x-it.x, dy=p.y-it.y, d=Math.hypot(dx,dy);
      if(autoAll || d<magnet){ it.homing=true; }
      if(it.homing){ const sp=Math.min(9, 3+it.t*0.1); it.vx+=dx/d*1.2; it.vy+=dy/d*1.2; const s=Math.hypot(it.vx,it.vy); if(s>sp){ it.vx*=sp/s; it.vy*=sp/s; } }
      if(d<14){ collectItem(it); it._got=true; continue; }
    }
    if(!it.homing){ it.vy+=0.12; if(it.vy>3)it.vy=3; it.vx*=0.96; }
    it.x+=it.vx; it.y+=it.vy;
    if(it.y>PF.y+PF.h+30) it._got=true;
  }
  items=items.filter(i=>!i._got);
}
