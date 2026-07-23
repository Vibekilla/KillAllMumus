function shopList(tab){
  if(tab==='i') return CONSUMABLES.map(c=>({ kind:'consumable', key:c.key, icon:c.icon, name:c.name, desc:c.desc, col:c.col, cost:c.cost, qty:consumQty(c.key), draw:c.draw }));
  const arr = tab==='w'?WEAPON_ORDER.map(k=>Object.assign({key:k},WEAPONS[k])) : tab==='s'?SPECIALS : MELEE;
  return arr.map(it=>{ const owned=contentUnlocked(tab,it.key), cost=lockCost(tab,it.key); return { kind:'gear', type:tab, key:it.key, icon:it.icon, name:it.name, desc:it.desc||it.tag||'', col:it.col, owned, cost }; });
}
