function hitPlayer(dmg){ dmg=Math.max(1, dmg||1);
  const p=player; if(p.iframe>0||p.dead||p.phaseT>0)return;   // phased into the alt reality — untouchable
  if(p.vialHits>0 && p.vialT>0){ p.vialHits--; p.iframe=Math.max(p.iframe,26); sfx('hit'); for(let i=0;i<12;i++) particles.push({x:p.x,y:p.y,vx:(Math.random()-.5)*6,vy:(Math.random()-.5)*6,life:18,c:i%2?'#9d6bff':'#4a1e7a'}); if(p.vialHits<=0) p.vialT=0; return; }  // Unholy Vial — void energy soaks the bullet
  if(p.shieldT>0){ p.shieldT=Math.max(0,p.shieldT-120); p.iframe=Math.max(p.iframe,40); sfx('hit'); for(let i=0;i<10;i++) particles.push({x:p.x,y:p.y,vx:(Math.random()-.5)*6,vy:(Math.random()-.5)*6,life:16,c:'#e8a860'}); return; }  // shield absorbs the whole hit
  run.lives-=dmg; if(run){run.stageNoDeath=false; run.runNoDeath=false;} sfx('hurt'); p.dead=true; p.respawn=70; hurtPortrait=60;
  if(dmg>1){ flashMsg={t:80,txt:'✖ ELITE HIT — '+dmg+' HEARTS!'}; screenShake=Math.max(screenShake,7); }
  bobinaSay(run.lives<0 ? 'I won’t give up on Bobo!' : HURT_LINES[(Math.random()*HURT_LINES.length)|0], run.lives<0?90:55, true);
  // drop power on death (scatter items)
  const lost=Math.max(0, run.power-1); run.power=Math.max(1, run.power-1.0);
  for(let i=0;i<Math.min(8,Math.round(lost*10)+3);i++) dropItem(p.x+(Math.random()-.5)*40, p.y-10, 'power');
  for(let i=0;i<40;i++) particles.push({x:p.x,y:p.y,vx:(Math.random()-.5)*9,vy:(Math.random()-.5)*9,life:36,c:'#ff9ecb'});
  bullets=bullets.filter(b=>{ const dx=b.x-p.x,dy=b.y-p.y; return dx*dx+dy*dy>100*100; });
  if(run.lives<0){ computeEmblems(); saveEstats(); state='gameover'; }
}
