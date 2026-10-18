function spawnBig(x,y,icy){ const d=run?run.stageIdx:0; enemies.push({kind:'big',x,y,vx:0,vy:0.55+d*0.08,r:30,hp:Math.round((icy?26:16)*(1+d*0.45)),icy:!!icy,t:0,flash:0,hover:PF.y+90+Math.random()*60}); }
// ---- themed ELITE mobs — one flavour per stage, matched to that stage's boss ----
const ELITE_KIND=['ape','badnik','cheer','pup','scammer','voideye','goon'];   // Jeet Ape · Egg Badnik · Mini-Mumina Cheerleader · Solana Pup · Scam Caller · Akashic Eye · Cabal Goon
const ELITE_NAME=['Jeet Ape','Egg Badnik','Mini Mumina','Solana Pup','Scam Caller','Akashic Eye','Cabal Goon'];
const ELITE_BCOL=['#ffd24a','#ff9ecb','#a6f06a','#c79bff','#ffb347','#e0b84a','#ff7a6a'];
const ELITE_HP=[9,11,15,17,20,22,24];
