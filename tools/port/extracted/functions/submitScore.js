function submitScore(handle){
  handle=(handle||'').trim().replace(/[<>@\s]/g,'').slice(0,15);
  try{ if(handle) localStorage.setItem('bobina_handle',handle); }catch(e){}
  const _me = window.bobinaMe || bobinaMe; const linked = !!( _me && _me.authenticated);
  lastSubmit={ handle: linked ? (_me.xUsername||handle||'') : handle, score:sessionScore, kills:totalKills, bcId: linked ? _me.bcId : null, bobinaUsername: linked ? _me.username : null };
  const payload={ handle, score:sessionScore, kills:totalKills, rank:rankLetter(), mode:modeTag(), won:endWon?1:0, outfit:selectedOutfit };
  lbState='loading';
  fetch('api/scores',{ method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload) })
    .then(r=>r.json()).then(d=>{ lbCache=(d&&d.scores)||[]; lbState='ok'; })
    .catch(()=>{ lbState='error'; });
}
