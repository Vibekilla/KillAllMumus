function consumeSelected(){
  // Hardened for public HTML — never let item use kill the session
  try{
    if(!run||!player) return false;
    if(!Array.isArray(arsenalI)) arsenalI=[];
    if(typeof consumInv!=='object'||!consumInv||Array.isArray(consumInv)) consumInv={};
    if(!Array.isArray(particles)) particles=[];
    if(!Array.isArray(scoreTexts)) scoreTexts=[];
    if(!Array.isArray(fx)) fx=[];
    const c=selConsumObj(); if(!c){ sfx('hit'); flashMsg={t:70,txt:'No items equipped — set them in the Arsenal'}; return false; }
    const q=consumQty(c.key);
    if(q>0){
      if(typeof c.full==='function' && c.full()){ sfx('hit'); flashMsg={t:80,txt:'Already maxed — '+c.name+' saved'}; pop(player.x,player.y-30,'FULL','#9fe0a4'); return false; }
      consumInv[c.key]=Math.max(0,q-1); if(consumInv[c.key]<=0) delete consumInv[c.key]; saveConsum();
      if(typeof c.apply==='function') c.apply();
      sfx('extend'); flashMsg={t:90,txt:(c.icon||'•')+' '+(c.name||c.key)+' used!'}; pop(player.x,player.y-30,c.icon||'•',c.col||'#ffcf5a');
      for(let i=0;i<14;i++) particles.push({x:player.x,y:player.y,vx:(Math.random()-.5)*6,vy:(Math.random()-.5)*6,life:26,c:c.col||'#ffcf5a'});
      if(c.key==='honeycomb'){ if(!estats||typeof estats!=='object') estats={}; estats.honeycombs=(estats.honeycombs||0)+1; saveEstats(); if(estats.honeycombs>=100) unlockEmblem('honeycomb_100'); }
      return true;
    }
    sfx('hit'); flashMsg={t:70,txt:'No '+(c.name||'item')+' left — buy some at the shop'}; return false;
  }catch(err){ console.error('[consumeSelected]', err); try{ sfx('hit'); flashMsg={t:90,txt:'Item fizzled — try again'}; }catch(_e){} return false; }
}
// ---- Shop catalogue (tabbed like the arsenal): buy weapons / specials / melee to unlock, or stock up on consumables ----
