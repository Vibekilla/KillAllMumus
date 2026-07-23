function consumeSelected(){ const c=selConsumObj(); if(!c||!run||!player) return false;
  if(consumQty(c.key)>0){
    if(c.full && c.full()){ sfx('hit'); flashMsg={t:80,txt:'Already maxed — '+c.name+' saved'}; pop(player.x,player.y-30,'FULL','#9fe0a4'); return false; }   // no waste (no cooldown): skip if hearts/power/special are already full
    consumInv[c.key]--; saveConsum(); c.apply(); sfx('extend'); flashMsg={t:90,txt:c.icon+' '+c.name+' used!'}; pop(player.x,player.y-30,c.icon,c.col); for(let i=0;i<14;i++) particles.push({x:player.x,y:player.y,vx:(Math.random()-.5)*6,vy:(Math.random()-.5)*6,life:26,c:c.col});
    if(c.key==='honeycomb'){ estats.honeycombs=(estats.honeycombs||0)+1; saveEstats(); if(estats.honeycombs>=100) unlockEmblem('honeycomb_100'); } return true; }
  else { sfx('hit'); flashMsg={t:70,txt:'No '+c.name+' left — buy some at the shop'}; return false; } }
