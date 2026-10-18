function angDiff(a,b){ let d=(a-b)%(Math.PI*2); if(d>Math.PI)d-=Math.PI*2; if(d<-Math.PI)d+=Math.PI*2; return Math.abs(d); }

/* ---------- State ---------- */
let state='title', paused=false, tick=0, hardMode=false;
let titleIdleT=0; function bumpIdle(){ titleIdleT=0; }   // AFK timer for the title-screen easter egg
// ---- difficulty tiers + New Game+ + persistent unlocks ----
let hellMode=false, difficulty=0, ngPlus=0, ngUnlocked=0, hellCleared=false, winCabalUnlock=false, winNgLv=0;
try{ ngUnlocked=Math.min(100, parseInt(localStorage.getItem('bobina_ngunlocked'))||0); hellCleared=localStorage.getItem('bobina_hellclear')==='1'; }catch(e){}   // NG+ hard-capped at 100
// remember the player's last difficulty + NG+ level across sessions (outfit + settings already persist)
try{ difficulty=Math.max(0,Math.min(2,parseInt(localStorage.getItem('bobina_difficulty'))||0)); }catch(e){}
try{ ngPlus=Math.max(0,Math.min(ngUnlocked,parseInt(localStorage.getItem('bobina_nglevel'))||0)); }catch(e){}
