function closeGate(goFs){ if(soundGate) soundGate.classList.add('hidden'); if(goFs) goFullscreenMobile(); }
document.getElementById('sg-enable').addEventListener('click', ()=>{ lofiOn=true; try{ initMaster(); }catch(e){} musicPlay(); closeGate(true); });
document.getElementById('sg-mute').addEventListener('click', ()=>{ lofiOn=false; closeGate(true); });

/* ---------- draw helpers ---------- */
