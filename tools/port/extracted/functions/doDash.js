function doDash(){ const p=player; if(!p||p.dead||p.dash>0||p.dashCd>0) return;
  estats.dashes=(estats.dashes||0)+1; if(estats.dashes>=50) unlockEmblem('dash_50'); saveEstats();
  let ang=(p.face!==undefined?p.face:-Math.PI/2);
  if(!isTouch && (mouse.x||mouse.y)){ const dx=mouse.x-p.x, dy=mouse.y-p.y; if(Math.hypot(dx,dy)>8) ang=Math.atan2(dy,dx); }   // dash where the pointer is
  const slash=(p.meleeHeld && (p.meleeChg||0)>=0.99);   // hold SPACE to full charge, then double-tap SHIFT → SLASH DASH
  p.dash=slash?16:12; p.dashAng=ang; p.dashCd=slash?52:40; p.iframe=Math.max(p.iframe, slash?22:15); p.trail=[]; p.slashDash=slash;
  const oc=outfitColors();
  if(slash){ p.meleeHeld=false; p.meleeChg=0; p.meleeCd=Math.max(p.meleeCd,24); flashMsg={t:42,txt:'✦ SLASH DASH!'}; unlockEmblem('slash_dash');
    doMeleeSwipe(1.0, ang); screenShake=Math.max(screenShake,6); sfx('card'); sfx(MELEE[p.melee||0].snd||'slash'); }
  else { sfx('graze'); sfx('power'); }
  for(let i=0;i<(slash?24:14);i++) particles.push({x:p.x,y:p.y,vx:-Math.cos(ang)*4+(Math.random()-.5)*(slash?3.6:2.5),vy:-Math.sin(ang)*4+(Math.random()-.5)*(slash?3.6:2.5),life:18,c:i%2?oc[0]:oc[1]}); }
