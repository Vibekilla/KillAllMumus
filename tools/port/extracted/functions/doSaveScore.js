function doSaveScore(){ submitScore(NEinput.value); hideNameEntry(); justSavedScore=true; state = endWon ? 'win' : 'gameover'; }  // return to the result screen so they can still share
document.getElementById('ne-save').onclick=doSaveScore;
document.getElementById('ne-skip').onclick=()=>{ hideNameEntry(); };
NEinput.addEventListener('keydown',e=>{ e.stopPropagation(); if(e.key==='Enter'){ doSaveScore(); } });
