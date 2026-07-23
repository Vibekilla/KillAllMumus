function spawnStardust(){ const p=player; if(!p) return;   // Stardust consumable — twinkling stars orbit her and sap HP from nearby Mumus
  fx.push({type:'stardust', t:9999, life:270, x:p.x, y:p.y-14, stars:[] }); sfx('power');
}
