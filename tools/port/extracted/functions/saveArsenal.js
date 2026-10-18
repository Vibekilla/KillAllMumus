function saveArsenal(){
  const cap=ARS_CAP||{w:5,s:5,m:2,i:3};
  if(typeof WEAPONS!=='undefined'){ arsenalW=_dedupeLoadout(arsenalW,k=>!!WEAPONS[k],cap.w); if(!arsenalW.length) arsenalW=['laser']; }
  if(typeof SPECIALS!=='undefined') arsenalS=_dedupeLoadout(arsenalS,k=>SPECIALS.some(s=>s.key===k),cap.s);
  if(typeof MELEE!=='undefined'){ arsenalM=_dedupeLoadout(arsenalM,k=>MELEE.some(m=>m.key===k),cap.m); if(!arsenalM.length) arsenalM=['katana']; }
  if(typeof CONSUMABLES!=='undefined') arsenalI=_dedupeLoadout(arsenalI,k=>CONSUMABLES.some(c=>c.key===k),cap.i);
  try{ localStorage.setItem('bobina_arsenal', JSON.stringify({w:arsenalW,s:arsenalS,m:arsenalM,i:arsenalI})); }catch(e){}
  arsenalRev++;
}
