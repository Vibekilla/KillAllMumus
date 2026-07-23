function pdown(e){ bumpIdle(); const p=canvasPos(e); pointer.down=true; pointer.x=p.x; pointer.y=p.y;
  if(state==='title'){ handleTitleClick(p); return; }
  if(state==='shop'){ for(const b of shopBtns){ if(inBtn(p,b)){ if(b.tab!==undefined){ shopTab=b.tab; shopSel=0; sfx('item'); } else if(shopSel===b.i){ shopBuySelected(); } else { shopSel=b.i; sfx('item'); } return; } } leaveShop(); return; }   // tab, or card (tap-again = buy); tap elsewhere = leave
  if(state==='play' && run && run.cleared && clearShop && Math.hypot(p.x-clearShop.x,p.y-clearShop.y)<38){ enterShop(); return; }   // tap the shop to enter (touch)
  if(state==='play' && run && run.cleared && clearPortal && Math.hypot(p.x-clearPortal.x,p.y-clearPortal.y)<44){ enterPortal(); return; }   // tap the portal to leave (touch)
  if(state==='emblems'){
    if(emPrevBtn && inBtn(p,emPrevBtn)){ if(emPage>0){ emPage--; sfx('item'); } return; }
    if(emNextBtn && inBtn(p,emNextBtn)){ if(emPage<emPageCount()-1){ emPage++; sfx('item'); } return; }
    state='title'; sfx('item'); return; }
  if(state==='outfits'){
    if(outfitPoseBtn && inBtn(p,outfitPoseBtn)){ outfitPose=(outfitPose+1)%OUTFIT_POSES.length; outfitAnimT=0; try{localStorage.setItem('bobina_pose',outfitPose);}catch(e){} sfx('graze'); return; }   // save — this is her victory pose
    if(faceBtn && inBtn(p,faceBtn)){ victoryFace=(victoryFace+1)%VICTORY_FACES.length; try{localStorage.setItem('bobina_face',victoryFace);}catch(e){} sfx('graze'); return; }   // pick the victory-pose face
    if(outfitBackBtn && inBtn(p,outfitBackBtn)){ state='title'; sfx('item'); return; }
    for(const t of outfitTiles){ if(inBtn(p,t)){
      outfitPreview=t.key;                                   // always preview the tapped skin
      if(t.unlocked){ selectedOutfit=t.key; try{localStorage.setItem('bobina_outfit',selectedOutfit);}catch(e){} sfx('item'); }
      else sfx('hit');
      return; } }
    return; }
  if(state==='ngselect'){
    if(ngBackBtn && inBtn(p,ngBackBtn)){ state='title'; sfx('item'); return; }
    for(const t of ngTiles){ if(inBtn(p,t)){ if(t.unlocked){ ngPlus=t.lvl; saveNgPrefs(); sfx('graze'); } else { sfx('hit'); } return; } }
    return; }
  if(state==='arsenal'){ for(const t of arsenalTiles){ if(inBtn(p,t)){
    if(t.tab){ arsTab=t.tab; arsDrag=null; sfx('item'); return; }   // switch category tab
    if(t.itemIdx!==undefined){ selConsum=t.itemIdx; sfx('item'); return; }   // select a consumable (Items tab)
    if(t.emptySlot){ arsDrag={empty:true}; return; }                 // empty slot isn't a drag source
    if(t.locked){ sfx('hit'); arsMsg={t:120, txt:'🔒 Locked — buy it at Honey Badger’s shop'}; arsDrag=null; return; }   // can't equip locked gear
    arsDrag={type:t.type,key:t.key,from:t.fromHot?'hotbar':'pool',slot:t.hotbarSlot,sx:p.x,sy:p.y,x:p.x,y:p.y,moved:false}; return; } }
    arsDrag={empty:true}; return; }   // start a potential tap/drag; decided on release
  if(inBtn(p,menuBtn) && (state==='win'||state==='gameover'||state==='leaderboard'||state==='stageclear')){ state='title'; menuBtn=null; ngPlus=Math.min(ngPlus,ngUnlocked); sfx('item'); return; }   // keep the player's NG+ level (remembered)
  if(state==='win'||state==='gameover'){ if(inBtn(p,shareBtn)){ tweetResult(shareBtn.won); return; } advanceScreen(); return; }
  if(state==='leaderboard'){
    if(lbPrevBtn && inBtn(p,lbPrevBtn)){ if(lbPage>0){ lbSetPage(lbPage-1); sfx('item'); } return; }
    if(lbNextBtn && inBtn(p,lbNextBtn)){ if(lbPage<lbPageCount()-1){ lbSetPage(lbPage+1); sfx('item'); } return; }
    for(const r of lbRows){ if(inBtn(p,r)){ try{ const u=r.profileUrl||(r.bobinaUsername?('https://bobina.moe/'+r.bobinaUsername):null)||(r.handle?('https://x.com/'+r.handle):null); if(u) window.open(u,'_blank','noopener'); }catch(e2){} return; } } advanceScreen(); return; }
  if(state==='stageclear' && scArsenalBtn && inBtn(p,scArsenalBtn)){ arsenalReturn='stageclear'; state='arsenal'; sfx('item'); return; }
  if(state==='intro'||state==='stageclear'){ advanceScreen(); }
}
