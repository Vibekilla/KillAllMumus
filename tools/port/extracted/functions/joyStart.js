function joyStart(e){ const t=e.changedTouches?e.changedTouches[0]:e; joy.active=true; joy.id=(t.identifier!==undefined?t.identifier:'m');
  joy.cx=joyHome.x; joy.cy=joyHome.y;   // fixed centre — the base stays seated in one place
  joybase.classList.remove('idle'); joyApply(t); if(e.cancelable)e.preventDefault(); }
