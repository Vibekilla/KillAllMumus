function updateTouchButtons(){ if(!run) return;
  const sb=btnEls.special; if(sb){ const ready=run.special>=100; const l=ready?'★<br>USE!':('★<br><small>'+Math.floor(run.special)+'%</small>');
    if(sb._l!==l){ sb._l=l; sb.innerHTML=l; } if(sb._r!==ready){ sb._r=ready; sb.classList.toggle('ready',ready); } }
  const bb=btnEls.bomb; if(bb){ const l='✸<br><small>×'+run.bombs+'</small>'; if(bb._l!==l){ bb._l=l; bb.innerHTML=l; } }
  const wb=btnEls.swap; if(wb){ const wp=WEAPONS[run.weapon], l=(wp?wp.icon:'⇄')+'<br>SWAP'; if(wb._l!==l){ wb._l=l; wb.innerHTML=l; } }
  const fb=btnEls.fire; if(fb){ const l=autoFire?'🔥<br>FIRE':'🔥<br><small>OFF</small>'; if(fb._l!==l){ fb._l=l; fb.innerHTML=l; } if(fb._o!==autoFire){ fb._o=autoFire; fb.classList.toggle('off',!autoFire); } }
  const mb=btnEls.melee; if(mb && player){ const m=MELEE[player.melee||0]||MELEE[0], chg=(player.meleeHeld?(player.meleeChg||0):0); const l=(m.icon||'⚔')+'<br>'+(chg>0?('<small>'+Math.round(chg*100)+'%</small>'):'MELEE'); if(mb._l!==l){ mb._l=l; mb.innerHTML=l; } }
  const cs=btnEls.meleeswap; if(cs && player){ const nm=MELEE[((player.melee||0)+1)%MELEE.length]; const l=(nm.icon||'🗡')+'<br><small>MEL⇄</small>'; if(cs._l!==l){ cs._l=l; cs.innerHTML=l; } } }
