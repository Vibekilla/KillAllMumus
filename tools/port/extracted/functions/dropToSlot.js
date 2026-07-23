function dropToSlot(type,key,slot){ const arr=arsArr(type), cap=ARS_CAP[type], was=arr.indexOf(key);   // drop an item into a hotbar slot (reorder if already equipped, else equip at that position)
  if(was>=0){ arr.splice(was,1); slot=Math.max(0,Math.min(arr.length,slot)); arr.splice(slot,0,key); }
  else if(arr.length<cap){ slot=Math.max(0,Math.min(arr.length,slot)); arr.splice(slot,0,key); }
  else { const s=Math.max(0,Math.min(arr.length-1,slot)); arr.splice(s,1,key); }   // full → replace the item sitting in that slot
  saveArsenal(); if(run) applyArsenalToRun(); sfx('power'); }
