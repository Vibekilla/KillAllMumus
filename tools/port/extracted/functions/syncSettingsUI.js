function syncSettingsUI(){ const f=document.getElementById('set-follow'), s=document.getElementById('set-speed'); if(!f||!s)return;
  f.value=Math.round(MOUSE.follow*100); document.getElementById('set-follow-v').textContent=Math.round(MOUSE.follow*100)+'%';
  s.value=Math.round(MOUSE.speed*100); document.getElementById('set-speed-v').textContent=MOUSE.speed.toFixed(2)+'×';
  const mu=document.getElementById('set-music'), sx=document.getElementById('set-sfx'), sr=document.getElementById('set-speedrun');
  if(mu){ mu.value=Math.round(musicVol*100); document.getElementById('set-music-v').textContent=Math.round(musicVol*100)+'%'; }
  if(sx){ sx.value=Math.round(sfxVol*100); document.getElementById('set-sfx-v').textContent=Math.round(sfxVol*100)+'%'; }
  if(sr){ sr.classList.toggle('on',speedrun); document.getElementById('set-speedrun-v').textContent=speedrun?'ON':'OFF'; } }
