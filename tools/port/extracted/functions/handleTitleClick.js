function handleTitleClick(p){ for(const b of titleBtns){ if(p.x>=b.x&&p.x<=b.x+b.w&&p.y>=b.y&&p.y<=b.y+b.h){
  if(b.id==='mode'){ difficulty=(difficulty+1)%3; applyDiff(); saveNgPrefs(); sfx('graze'); return; }
  if(b.id==='ngplus'){ state='ngselect'; sfx('item'); return; }   // open the dedicated NG+ progression menu
  if(b.id==='lb'){ state='leaderboard'; lastSubmit=null; fetchLB(); sfx('item'); return; }
  if(b.id==='emblems'){ if(emblemCount()>=20) unlockEmblem('bride'); state='emblems'; emPage=0; sfx('item'); return; }
  if(b.id==='arsenal'){ arsenalReturn='title'; state='arsenal'; sfx('item'); return; }
  if(b.id==='outfit'){ state='outfits'; outfitPreview=selectedOutfit; outfitAnimT=0; sfx('item'); return; }   // keep the selected (victory) pose
  if(b.id==='settings'){ openSettings(); sfx('item'); return; }
  if(b.id==='shoutouts'){ openShoutouts(); sfx('item'); return; } } } startRun(); }
