function clearWaveMobs(){ for(const e of enemies){ burst(e.x,e.y,e.icy?'#a0e0ff':'#ffd27a'); sessionScore+=Math.floor(50*scoreMult()); } enemies=[]; bulletCancelAll(); }
