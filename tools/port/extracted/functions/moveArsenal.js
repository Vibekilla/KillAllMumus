function moveArsenal(type,key,dir){   // shift an item's position in the cycle order (customize loadout order)
  const arr=arsArr(type), i=arr.indexOf(key), j=i+dir;
  if(i<0||j<0||j>=arr.length){ sfx('hit'); return; }
  const t=arr[i]; arr[i]=arr[j]; arr[j]=t; sfx('item'); saveArsenal(); if(run) applyArsenalToRun();
}
