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
