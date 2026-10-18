function closeShoutouts(){ if(shoutEl) shoutEl.classList.remove('on'); }
(function(){ const cb=document.getElementById('so-close'); if(cb){ cb.addEventListener('click',closeShoutouts); cb.addEventListener('touchstart',e=>{e.preventDefault();closeShoutouts();},{passive:false}); }
  if(shoutEl) shoutEl.addEventListener('click',e=>{ if(e.target===shoutEl) closeShoutouts(); }); })();
// ===== virtual joystick: FIXED base seated in the lower-left; the knob deflects toward your thumb (base never moves) =====
const joyzone=document.getElementById('joyzone'), joybase=document.getElementById('joybase'), joyknob=document.getElementById('joyknob');
let joy={active:false, id:null, cx:0, cy:0, vx:0, vy:0}, joyHome={x:60,y:200};
const JOY_R=54;
