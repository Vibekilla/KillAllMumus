function syncPauseUI(){ const el=id=>document.getElementById(id);
  const m=el('pz-music'), s=el('pz-sfx'), f=el('pz-follow'), sp=el('pz-speed'); if(!m) return;
  m.value=Math.round(musicVol*100); el('pz-music-v').textContent=Math.round(musicVol*100)+'%';
  s.value=Math.round(sfxVol*100);   el('pz-sfx-v').textContent=Math.round(sfxVol*100)+'%';
  f.value=Math.round(MOUSE.follow*100); el('pz-follow-v').textContent=Math.round(MOUSE.follow*100)+'%';
  sp.value=Math.round(MOUSE.speed*100); el('pz-speed-v').textContent=MOUSE.speed.toFixed(2)+'×'; }
