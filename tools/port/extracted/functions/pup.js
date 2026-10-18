function pup(){ pointer.down=false;
  if(state==='arsenal' && arsDrag){ const d=arsDrag; arsDrag=null;
    if(d.empty){ if(!d.moved) exitArsenal(); return; }   // tapped empty area → leave
    if(!d.moved){                                         // tap
      if(d.from==='pool'){ toggleArsenal(d.type,d.key); }           // tap pool tile → equip / unequip
      else if(d.from==='hotbar' && d.key){ unequipArsenal(d.type,d.key); }   // tap filled slot → remove
      return;
    }
    if(d.key){ let dropped=false;                         // drag → drop into a hotbar slot
      for(const t of arsenalTiles){ if(t.hotbarSlot!==undefined && inBtn({x:d.x,y:d.y},t)){ dropToSlot(d.type,d.key,t.hotbarSlot); dropped=true; break; } }
      if(!dropped && d.from==='hotbar'){ unequipArsenal(d.type,d.key); }   // dragged a slot item out → remove
    }
  } }
cv.addEventListener('mousedown',e=>{e.preventDefault();pdown(e);});
// track the mouse on the whole window so a click-drag keeps steering her even when the cursor leaves the canvas/window
addEventListener('mousemove',pmove); addEventListener('mouseup',pup);
cv.addEventListener('touchstart',e=>{e.preventDefault();pdown(e);},{passive:false});
cv.addEventListener('touchmove',e=>{e.preventDefault();pmove(e);},{passive:false});
addEventListener('touchend',pup);
// Touch-PRIMARY detection: a mouse/trackpad (even on touchscreen laptops) reports hover:hover / pointer:fine,
// so this stays false on desktop. Only true phones/tablets match — fixes desktops wrongly getting the mobile UI.
// explicit UI override (escape hatch for mis-detected devices + lets us verify the mobile UI):
//   ?touch=1 forces mobile controls, ?touch=0 forces desktop; the choice persists in localStorage.
