function anyModalOpen(){ const kb=document.getElementById('keybinds'); const disp=document.getElementById('display'); return (setEl&&setEl.classList.contains('on')) || (helpEl&&helpEl.classList.contains('on')) || (kb&&kb.classList.contains('on')) || (disp&&disp.classList.contains('on')) || (typeof shoutEl!=='undefined'&&shoutEl&&shoutEl.classList.contains('on')) || (typeof NE!=='undefined'&&NE&&NE.classList.contains('on')); }
(function(){ const f=document.getElementById('set-follow'), s=document.getElementById('set-speed');
  if(f) f.addEventListener('input',()=>{ MOUSE.follow=parseInt(f.value)/100; document.getElementById('set-follow-v').textContent=f.value+'%'; try{localStorage.setItem('bobina_follow',String(MOUSE.follow));}catch(e){} });
  if(s) s.addEventListener('input',()=>{ MOUSE.speed=parseInt(s.value)/100; document.getElementById('set-speed-v').textContent=MOUSE.speed.toFixed(2)+'×'; try{localStorage.setItem('bobina_mspeed',String(MOUSE.speed));}catch(e){} });
  const mu=document.getElementById('set-music'), sx=document.getElementById('set-sfx'), sr=document.getElementById('set-speedrun');
  if(mu) mu.addEventListener('input',()=>{ musicVol=parseInt(mu.value)/100; document.getElementById('set-music-v').textContent=mu.value+'%'; applyMusicVol(); try{localStorage.setItem('bobina_musicvol',String(musicVol));}catch(e){} });
  if(sx) sx.addEventListener('input',()=>{ sfxVol=parseInt(sx.value)/100; document.getElementById('set-sfx-v').textContent=sx.value+'%'; applySfxVol(); try{localStorage.setItem('bobina_sfxvol',String(sfxVol));}catch(e){} });
  if(sx) sx.addEventListener('change',()=>{ try{ initMaster(); applySfxVol(); sfx('item'); }catch(e){} });   // preview beep at the new level
  if(sr) sr.addEventListener('click',()=>{ speedrun=!speedrun; sr.classList.toggle('on',speedrun); document.getElementById('set-speedrun-v').textContent=speedrun?'ON':'OFF'; try{localStorage.setItem('bobina_speedrun',speedrun?'1':'0');}catch(e){} try{ sfx('item'); }catch(e){} });
  const cb=document.getElementById('set-close'); if(cb){ cb.addEventListener('click',closeSettings); cb.addEventListener('touchstart',e=>{e.preventDefault();closeSettings();},{passive:false}); }
  if(setEl) setEl.addEventListener('click',e=>{ if(e.target===setEl) closeSettings(); }); })();
// ===== Controls + Help (How to Play) — the arsenal list is generated from the game data, so it auto-updates =====
const helpEl=document.getElementById('helpmodal');
