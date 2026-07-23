function collectItem(it){
  sfx(it.type==='power'||it.type==='fullpower'?'power':'item');
  if(it.type==='power'){ addPower(0.05); pop(it.x,it.y,'+P','#ff8ad6'); emote('star'); }
  else if(it.type==='fullpower'){ run.power=powerCap(); pop(it.x,it.y,'FULL POWER','#ffd27a'); emote('wow'); }
  else if(it.type==='point'){ const v=Math.floor(500*scoreMult()); sessionScore+=v; pop(it.x,it.y,'+'+v,'#8fd0ff'); if(Math.random()<0.25) emote('happy'); }
  else if(it.type==='life'){ run.lifeFrags++; if(run.lifeFrags>=5){ run.lifeFrags=0; gainLife(); emote('love'); } else { pop(it.x,it.y,'♥ frag','#ff6ec7'); emote('love'); } }
  else if(it.type==='bomb'){ run.bombFrags++; if(run.bombFrags>=3){ run.bombFrags=0; if(run.bombs<MAX_BOMBS){run.bombs++; pop(it.x,it.y,'✸ +BOMB','#ffd27a'); emote('happy'); } } else pop(it.x,it.y,'✸ frag','#ffd27a'); }
  else if(it.type==='weapon'){ const nw=!run.weapons.includes(it.wep); if(nw) run.weapons.push(it.wep); run.weapon=it.wep; sfx('power'); flashMsg={t:120,txt:(nw?'NEW WEAPON: ':'')+WEAPONS[it.wep].name+'!'}; pop(it.x,it.y,WEAPONS[it.wep].name,WEAPONS[it.wep].col); emote('wow'); }
  else if(it.type==='shield'){ player.shieldT=Math.max(player.shieldT,290); sfx('power'); flashMsg={t:80,txt:'BOBO GUARD UP!'}; pop(it.x,it.y,'BOBO GUARD','#e8a860'); }
  else if(it.type==='rapid'){ player.rapidT=Math.max(player.rapidT,270); sfx('power'); flashMsg={t:80,txt:'MONKE FRENZY!'}; pop(it.x,it.y,'MONKE FRENZY','#ffe14a'); }
  else if(it.type==='skull'){ const v=it.val||10; mumuHeads+=v; saveHeads(); pop(it.x,it.y,'💀 +'+v,'#ffe0a0'); if(Math.random()<0.2) emote('happy'); }
}
