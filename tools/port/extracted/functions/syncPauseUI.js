function syncPauseUI(){ const el=id=>document.getElementById(id);
  const m=el('pz-music'), s=el('pz-sfx'), f=el('pz-follow'), sp=el('pz-speed'); if(!m) return;
  m.value=Math.round(musicVol*100); el('pz-music-v').textContent=Math.round(musicVol*100)+'%';
  s.value=Math.round(sfxVol*100);   el('pz-sfx-v').textContent=Math.round(sfxVol*100)+'%';
  f.value=Math.round(MOUSE.follow*100); el('pz-follow-v').textContent=Math.round(MOUSE.follow*100)+'%';
  sp.value=Math.round(MOUSE.speed*100); el('pz-speed-v').textContent=MOUSE.speed.toFixed(2)+'×'; }
(function(){ const ps=document.getElementById('pausescreen'), rb=document.getElementById('ps-resume'), mb=document.getElementById('ps-menu');
  const backdropResume=e=>{ if(e.target===ps) resumeGame(e); };   // only tapping the dimmed area (not the card/controls) resumes
  if(ps){ ps.addEventListener('touchstart',backdropResume,{passive:false}); ps.addEventListener('mousedown',backdropResume); }
  if(rb){ rb.addEventListener('touchstart',resumeGame,{passive:false}); rb.addEventListener('click',resumeGame); }
  if(mb){ mb.addEventListener('touchstart',pauseReturnMenu,{passive:false}); mb.addEventListener('click',pauseReturnMenu); }
  const el=id=>document.getElementById(id);
  const m=el('pz-music'), s=el('pz-sfx'), f=el('pz-follow'), sp=el('pz-speed');
  if(m) m.addEventListener('input',()=>{ musicVol=parseInt(m.value)/100; el('pz-music-v').textContent=m.value+'%'; applyMusicVol(); try{localStorage.setItem('bobina_musicvol',String(musicVol));}catch(e){} });
  if(s) s.addEventListener('input',()=>{ sfxVol=parseInt(s.value)/100; el('pz-sfx-v').textContent=s.value+'%'; applySfxVol(); try{localStorage.setItem('bobina_sfxvol',String(sfxVol));}catch(e){} });
  if(f) f.addEventListener('input',()=>{ MOUSE.follow=parseInt(f.value)/100; el('pz-follow-v').textContent=f.value+'%'; try{localStorage.setItem('bobina_follow',String(MOUSE.follow));}catch(e){} });
  if(sp) sp.addEventListener('input',()=>{ MOUSE.speed=parseInt(sp.value)/100; el('pz-speed-v').textContent=MOUSE.speed.toFixed(2)+'×'; try{localStorage.setItem('bobina_mspeed',String(MOUSE.speed));}catch(e){} });
})();
// SHOUTOUTS modal
const shoutEl=document.getElementById('shoutouts');
