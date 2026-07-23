function pauseReturnMenu(e){ if(e){ e.preventDefault(); e.stopPropagation(); } paused=false; state='title'; menuBtn=null; ngPlus=Math.min(ngPlus,ngUnlocked); try{ sfx('item'); }catch(_){} }
