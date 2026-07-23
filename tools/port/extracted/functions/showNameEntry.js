function showNameEntry(){
  // Linked Bobina players skip the X prompt — progress saves under bc_id
  const _me2 = window.bobinaMe || bobinaMe;
  if(_me2 && _me2.authenticated){
    submitScore(_me2.xUsername || localStorage.getItem('bobina_handle') || '');
    justSavedScore=true;
    state = endWon ? 'win' : 'gameover';
    return;
  }
  nameEntryOpen=true; NE.classList.add('on');
  document.getElementById('ne-score').innerHTML = (endWon?'BOBO SAVED! ':'')+'Score '+fmtScore(sessionScore)+' · '+totalKills+' Mumus · Rank '+rankLetter()+((difficulty>0||ngPlus>0)?(' · '+modeTag()):'')+'<br><span style="font-size:12px;color:#c8b0d0">Save your <b>X handle</b> for credit — or <a href="/auth/bobina" style="color:#ff9ecb">Sign in with Bobina</a> to sync forever</span>';
  try{ NEinput.value=localStorage.getItem('bobina_handle')||''; }catch(e){ NEinput.value=''; }
  setTimeout(()=>{ try{ NEinput.focus(); NEinput.select(); }catch(e){} },30);
}
