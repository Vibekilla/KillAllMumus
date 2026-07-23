function doBomb(){
  if(run.bombs<=0 || player.dead) return;
  run.bombs--; run.stageNoBomb=false; run.runNoBomb=false; player.iframe=Math.max(player.iframe,140); player.bombFx=46; sfx('bomb'); flashMsg={t:50,txt:'BOBINA BLAST!'};
  estats.bombs=(estats.bombs||0)+1; if(estats.bombs>=50) unlockEmblem('bomb_50'); saveEstats();
  bulletCancelAll();
  for(const e of enemies){ e.hp-=8; e.flash=6; if(e.hp<=0){ killEnemy(e,true);} } enemies=enemies.filter(e=>e.hp>0);
  if(boss && !boss.dead && boss.intro<=0){ boss.hp-=Math.floor(boss.maxhp*0.09); boss.flash=6; if(boss.hp<=0){boss.dead=true;boss.hp=0;bullets=[];sfx('win');} }
  for(let i=0;i<60;i++) particles.push({x:player.x,y:player.y,vx:(Math.random()-.5)*14,vy:(Math.random()-.5)*14,life:40,c:['#ff6ec7','#ffd27a','#fff'][i%3]});
}
