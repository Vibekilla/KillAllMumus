function contentUnlocked(type, key){ if(FREE_CONTENT[type+':'+key]) return true;   // free from the start
  if(shopUnlocks[type+':'+key]) return true;                                        // bought at the shop
  const arr = type==='w'?arsenalW : type==='s'?arsenalS : arsenalM; return !!(arr && arr.includes(key)); }
