function spawnWaves(){
  const s=run.stageIdx, st=stageTime, hm=hardMode?0.62:1.2;
  const prog=st/STAGES[s].waveDur;              // within-stage ramp: denser toward the boss
  const iv=Math.max(18, Math.floor((s===0?70:s===1?60:52)*hm*(1-prog*0.32)));
  if(st%iv!==0) return; const roll=(st/iv)|0;
  if(s===0){
    if(roll%4===3){ spawnBig(PF.x+80+Math.random()*(PF.w-160), PF.y-30); }
    else { const cx=PF.x+60+Math.random()*(PF.w-120), n=hardMode?7:5; for(let i=0;i<n;i++) spawnLil(cx+(i-(n-1)/2)*24, PF.y-30-Math.abs(i-(n-1)/2)*14, (Math.random()-.5)*0.4, 1.7+Math.random()*0.5,false); }
  } else if(s===1){
    if(roll%3===2){ spawnBig(PF.x+70+Math.random()*(PF.w-140), PF.y-30, true); }
    else { const fromLeft=roll%2===0; const n=hardMode?6:4; for(let i=0;i<n;i++) spawnLil(fromLeft?PF.x-20:PF.x+PF.w+20, PF.y+40+i*34, fromLeft?1.8:-1.8, 0.7+Math.random()*0.4, true); }
  } else {
    if(roll%5===4){ spawnBig(PF.x+PF.w/2, PF.y-30, roll%2===0); }
    const n=hardMode?9:6, cx=PF.x+60+Math.random()*(PF.w-120);
    for(let i=0;i<n;i++) spawnLil(cx+(i-(n-1)/2)*22, PF.y-30-((i*11)%40), (Math.random()-.5)*1.2, 1.9+Math.random()*0.7, roll%3===0);
  }
  // a themed elite mob for this stage drops in periodically
  if(roll>1 && roll%4===2) spawnElite(PF.x+80+Math.random()*(PF.w-160));
}
