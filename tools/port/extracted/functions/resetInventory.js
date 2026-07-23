function resetInventory(){   // wipe bought gear + carried items + skulls back to the starter kit; KEEP emblems, outfits & NG+
  for(const k in shopUnlocks) delete shopUnlocks[k]; saveShopUnlocks();
  for(const k in consumInv) delete consumInv[k]; saveConsum();
  mumuHeads=0; saveHeads();
  arsenalW=['laser']; arsenalS=['mech','bearzooka']; arsenalM=['katana']; arsenalI=['honeycomb','bulltears','bullsouls']; selConsum=0; saveArsenal();
  try{ localStorage.setItem('bobina_invmigrated','1'); }catch(e){}   // stay "migrated" so the wipe sticks (no auto-regrant)
  if(run) applyArsenalToRun();
}
