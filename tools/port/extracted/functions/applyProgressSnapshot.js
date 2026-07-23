function applyProgressSnapshot(p){
  if(!p || typeof p!=='object') return;
  // emblems / stats
  if(p.emblems && typeof p.emblems==='object'){
    emblemsGot = Object.assign({}, emblemsGot||{}, p.emblems);
    try{ localStorage.setItem('bobina_emblems', JSON.stringify(emblemsGot)); }catch(e){}
  }
  if(p.estats && typeof p.estats==='object'){
    const e0 = estats||{};
    for(const k of Object.keys(p.estats)){ e0[k] = Math.max(Number(e0[k])||0, Number(p.estats[k])||0); }
    estats = e0;
    try{ localStorage.setItem('bobina_estats', JSON.stringify(estats)); }catch(e){}
  }
  if(p.arsenal && typeof p.arsenal==='object'){
    if(Array.isArray(p.arsenal.w) && p.arsenal.w.length) arsenalW = p.arsenal.w.filter(k=>WEAPONS[k]);
    if(Array.isArray(p.arsenal.s)) arsenalS = p.arsenal.s.filter(k=>SPECIALS.some(s=>s.key===k));
    if(Array.isArray(p.arsenal.m) && typeof MELEE!=='undefined') arsenalM = p.arsenal.m.filter(k=>MELEE.some(m=>m.key===k));
    if(Array.isArray(p.arsenal.i) && typeof CONSUMABLES!=='undefined') arsenalI = p.arsenal.i.filter(k=>CONSUMABLES.some(c=>c.key===k));
    if(!arsenalW.length) arsenalW=['laser'];
    try{ localStorage.setItem('bobina_arsenal', JSON.stringify({w:arsenalW,s:arsenalS,m:arsenalM,i:arsenalI})); }catch(e){}
  }
  if(p.heads!=null){ mumuHeads = Math.max(mumuHeads|0, Number(p.heads)||0); try{ localStorage.setItem('bobina_heads', String(mumuHeads)); }catch(e){} }
  if(p.shopUnlocks && typeof p.shopUnlocks==='object'){
    shopUnlocks = Object.assign({}, shopUnlocks||{}, p.shopUnlocks);
    try{ localStorage.setItem('bobina_shopunlocks', JSON.stringify(shopUnlocks)); }catch(e){}
  }
  if(p.consum && typeof p.consum==='object'){
    const c0 = consumInv||{};
    for(const k of Object.keys(p.consum)){ c0[k] = Math.max(Number(c0[k])||0, Number(p.consum[k])||0); }
    consumInv = c0;
    try{ localStorage.setItem('bobina_consum', JSON.stringify(consumInv)); }catch(e){}
  }
  if(p.ngUnlocked!=null){ ngUnlocked = Math.min(100, Math.max(ngUnlocked|0, Number(p.ngUnlocked)||0)); try{ localStorage.setItem('bobina_ngunlocked', String(ngUnlocked)); }catch(e){} }
  if(p.hellCleared){ hellCleared = true; try{ localStorage.setItem('bobina_hellclear','1'); }catch(e){} }
  if(p.difficulty!=null){ difficulty = Math.max(0, Math.min(2, Number(p.difficulty)||0)); }
  if(p.ngPlus!=null){ ngPlus = Math.max(0, Math.min(ngUnlocked, Number(p.ngPlus)||0)); }
  try{ localStorage.setItem('bobina_difficulty', String(difficulty)); localStorage.setItem('bobina_nglevel', String(ngPlus)); }catch(e){}
  if(typeof applyDiff==='function') applyDiff();
  if(p.outfit){ selectedOutfit = p.outfit; try{ localStorage.setItem('bobina_outfit', selectedOutfit); }catch(e){} }
  if(p.pose!=null && typeof outfitPose!=='undefined'){ outfitPose = Number(p.pose)||0; try{ localStorage.setItem('bobina_pose', String(outfitPose)); }catch(e){} }
  if(p.face!=null && typeof victoryFace!=='undefined'){ victoryFace = Number(p.face)||0; try{ localStorage.setItem('bobina_face', String(victoryFace)); }catch(e){} }
  if(p.handle){ try{ localStorage.setItem('bobina_handle', String(p.handle).replace(/^@+/,'')); }catch(e){} }
  if(p.binds && typeof p.binds==='object' && typeof binds!=='undefined'){
    binds = Object.assign({}, binds, p.binds);
    try{ localStorage.setItem('bobina_binds', JSON.stringify(binds)); }catch(e){}
    if(typeof rebuildKMAP==='function') try{ rebuildKMAP(); }catch(e){}
  }
  if(p.settings && typeof p.settings==='object'){
    const st=p.settings;
    if(st.musicVol!=null && typeof musicVol!=='undefined'){ musicVol=Number(st.musicVol); try{ localStorage.setItem('bobina_musicvol',String(musicVol)); }catch(e){} if(typeof applyMusicVol==='function') applyMusicVol(); }
    if(st.sfxVol!=null && typeof sfxVol!=='undefined'){ sfxVol=Number(st.sfxVol); try{ localStorage.setItem('bobina_sfxvol',String(sfxVol)); }catch(e){} if(typeof applySfxVol==='function') applySfxVol(); }
    if(st.follow!=null && typeof MOUSE!=='undefined'){ MOUSE.follow=Number(st.follow); try{ localStorage.setItem('bobina_follow',String(MOUSE.follow)); }catch(e){} }
    if(st.mspeed!=null && typeof MOUSE!=='undefined'){ MOUSE.speed=Number(st.mspeed); try{ localStorage.setItem('bobina_mspeed',String(MOUSE.speed)); }catch(e){} }
    if(st.speedrun!=null && typeof speedrun!=='undefined'){ speedrun=!!st.speedrun; try{ localStorage.setItem('bobina_speedrun', speedrun?'1':'0'); }catch(e){} }
    if(st.autofire!=null && typeof autoFire!=='undefined'){ autoFire=!!st.autofire; try{ localStorage.setItem('bobina_autofire', autoFire?'1':'0'); }catch(e){} }
    if(st.ui){ try{ localStorage.setItem('bobina_ui', st.ui); }catch(e){} }
    if(st.displayScale!=null && typeof setDisplayScale==='function') setDisplayScale(Math.round(Number(st.displayScale)*100));
    else if(p.displayScale!=null && typeof setDisplayScale==='function') setDisplayScale(Math.round(Number(p.displayScale)*100));
    if(st.refreshRate!=null && typeof setRefreshRate==='function') setRefreshRate(st.refreshRate);
    if(st.debugLayer!=null && typeof setDebugLayer==='function') setDebugLayer(!!st.debugLayer);
  }
  // top-level display fields
  if(p.displayScale!=null && typeof setDisplayScale==='function' && !p.settings) setDisplayScale(Math.round(Number(p.displayScale)*100));
  if(p.refreshRate!=null && typeof setRefreshRate==='function') setRefreshRate(p.refreshRate);
  if(p.debugLayer!=null && typeof setDebugLayer==='function') setDebugLayer(!!p.debugLayer);
  emblemsGot['start']=true;
  if(typeof saveEmblems==='function'){ /* already written */ }
}
