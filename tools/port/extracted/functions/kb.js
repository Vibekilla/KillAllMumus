function kb(a){ return keyName(binds[a]); }   // live label for an action's current binding — used by every on-screen key prompt so rebinds reflect globally
rebuildKMAP();
let mouse={x:0,y:0,moveT:0}, lastShiftTap=-99;
let nameEntryOpen=false;
addEventListener('keydown',e=>{ if(rebindAction){ e.preventDefault(); e.stopPropagation(); setBind(rebindAction, e.code); rebindAction=null; renderKeybinds(); return; } }, true);   // capture: rebind a key (Esc is bindable too; cancel by clicking the key again)
addEventListener('keydown',e=>{ if(nameEntryOpen||anyModalOpen())return; const k=KMAP[e.code]; if(k){ e.preventDefault(); if(!keys[k]) keyPress(k); keys[k]=true; } });
addEventListener('keyup',e=>{ if(nameEntryOpen)return; const k=KMAP[e.code]; if(k){ e.preventDefault(); keys[k]=false; } });
let pointer={down:false,x:0,y:0};
