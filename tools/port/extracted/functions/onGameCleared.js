function onGameCleared(){
  winCabalUnlock = hellMode && !hasEmblem('clear_hell');   // did THIS clear just earn the Cabal skin?
  unlockEmblem('clear');
  if(hardMode) unlockEmblem('clear_hard');
  if(hellMode){ unlockEmblem('clear_hell'); if(!hellCleared){ hellCleared=true; try{localStorage.setItem('bobina_hellclear','1');}catch(e){} } }
  if(speedrun) unlockEmblem('speedrun');
  if(speedrun && hellMode) unlockEmblem('speedrun_hell');
  if(ngPlus>0) unlockEmblem('ngplus');
  if(ngPlus>=3) unlockEmblem('ngplus_3');
  if(run && run.runNoDeath) unlockEmblem('no_miss_game');
  if(run && run.runNoBomb) unlockEmblem('no_bomb_game');
  estats.clears++; saveEstats();
  winNgLv = Math.min(MAX_NG, ngPlus+1);
  if(ngPlus+1>ngUnlocked && ngUnlocked<MAX_NG){ ngUnlocked=Math.min(MAX_NG, ngPlus+1); try{localStorage.setItem('bobina_ngunlocked',String(ngUnlocked));}catch(e){} }
  if(ngPlus>=25) unlockEmblem('ng25'); if(ngPlus>=50) unlockEmblem('ng50'); if(ngPlus>=75) unlockEmblem('ng75'); if(ngPlus>=100) unlockEmblem('ng100');   // NG+ victory skins
}
