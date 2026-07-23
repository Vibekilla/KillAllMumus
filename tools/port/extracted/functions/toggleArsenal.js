function toggleArsenal(type,key){
  const arr=arsArr(type), cap=ARS_CAP[type], minKeep=(type==='s'||type==='i'?0:1);   // weapons & melee need ≥1; specials & items optional
  const i=arr.indexOf(key);
  if(i>=0){ if(arr.length>minKeep){ arr.splice(i,1); sfx('item'); } else { sfx('hit'); return; } }
  else { if(arr.length<cap){ arr.push(key); sfx('power'); } else { sfx('hit'); return; } }
  saveArsenal(); if(run) applyArsenalToRun();
}
