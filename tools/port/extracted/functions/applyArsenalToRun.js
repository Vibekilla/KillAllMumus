function applyArsenalToRun(){ if(!run) return; run.weapons=arsenalW.slice(); if(!run.weapons.includes(run.weapon)) run.weapon=run.weapons[0]||'spread'; run.specials=arsenalS.slice(); if(run.armed>=run.specials.length) run.armed=0;
  run.melees=meleeIdxList(); if(run.melees.length && player && !run.melees.includes(player.melee)) player.melee=run.melees[0]; }
