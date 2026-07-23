function emblemTick(){ if(state!=='play'||!run) return;
  if(sessionScore>=1000000) unlockEmblem('score_1m');
  if(sessionScore>=5000000) unlockEmblem('score_5m');
  if(typeof shotLevel==='function' && shotLevel()>=4) unlockEmblem('full_power');
  if(run.lives>=8) unlockEmblem('life_8');
  if(run.lives>=MAX_LIVES) unlockEmblem('max_lives');
  if(run.weapons && run.weapons.length>=5) unlockEmblem('weapon_all');
  if(emblemCount()>=20) unlockEmblem('bride');   // meta: collecting 20 emblems earns the wedding dress
  if(sessionScore>estats.best) estats.best=sessionScore; }
