function loadStage(i){
  run.stageIdx=i;
  SPD = (hardMode?1.0:0.8) * (1 + i*0.13) * threatMul();   // bullets get faster each stage (+ HELL/NG+ scaling)
  enemies=[]; bullets=[]; pshots=[]; items=[]; particles=[]; floaters=[]; scoreTexts=[]; emotes=[];
  boss=null; dialog=null; stageTime=0; stagePhase='waves'; killsThisStage=0; stageEmblemMark=newEmblems.length; fx=[]; meleeFx=[]; burns=[]; slowmoT=0;
  run.cleared=false; clearPortal=null; clearShop=null; clearMsgT=0;   // reset the post-boss portal/shop
  bgSeed=Math.random()*6.283; bgHueSeed=Math.random()*60-30; bgPetals=3+((Math.random()*4)|0)*2;   // RNG the psychedelic backdrop so every run looks different
  run.stageNoDeath=true; run.stageNoBomb=true;   // per-stage emblem flags (Untouchable / Bomb Disposal)
  initPlayer(); run.bombs=Math.max(run.bombs,2);
  if(run.melees && run.melees.length && !run.melees.includes(player.melee)) player.melee=run.melees[0];   // start on the first melee in the loadout
}
