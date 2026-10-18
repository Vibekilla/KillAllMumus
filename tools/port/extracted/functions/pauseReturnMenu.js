function pauseReturnMenu(e){ if(e){ e.preventDefault(); e.stopPropagation(); } paused=false; state='title'; menuBtn=null; ngPlus=Math.min(ngPlus,ngUnlocked); try{ sfx('item'); }catch(_){} }
// keep the pause-menu sliders in sync with the live values every time the menu opens
