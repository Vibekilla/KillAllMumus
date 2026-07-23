function arsPool(type){ if(type==='i') return CONSUMABLES.map(c=>Object.assign({},c,{locked:false}));   // consumables aren't shop-locked (you buy quantities), so all are equippable
  const all = type==='w' ? WEAPON_ORDER.map(k=>Object.assign({key:k},WEAPONS[k])) : type==='s' ? SPECIALS : MELEE; return all.map(it=>Object.assign({},it,{locked:!contentUnlocked(type,it.key)})); }
