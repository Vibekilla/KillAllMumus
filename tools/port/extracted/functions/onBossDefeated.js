function onBossDefeated(){
  if(run.stageNoDeath) unlockEmblem('flawless');   // cleared this stage without dying
  if(run.stageNoBomb)  unlockEmblem('no_bomb');    // …and without a bomb
  saveEstats();
  if(run.stageIdx>=STAGES.length-1){ onGameCleared(); computeEmblems(); state='win'; winTimer=0; return; }
  clearInfo={ stage:run.stageIdx, killsThisStage, total:totalKills, emblems:newEmblems.slice(stageEmblemMark).map(id=>emblemDef(id)).filter(Boolean) }; state='stageclear';
}
