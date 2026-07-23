function spawnBubbles(){ const p=player; if(!p) return;   // Bubbles consumable — a ring of bubbles drift out, trap groups of Mumus, then pop for AoE
  for(let i=0;i<6;i++){ const a=(i/6)*6.283+(i*0.7); const sp=1.5+i*0.15;
    fx.push({type:'bubble', t:9999, life:120+i*8, x:p.x, y:p.y-8, vx:Math.cos(a)*sp, vy:Math.sin(a)*sp-0.6, r:9, rmax:32, pop:0, popR:0, caught:0}); }
  sfx('power');
}
