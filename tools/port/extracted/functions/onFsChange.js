function onFsChange(){ const on=!!(document.fullscreenElement||document.webkitFullscreenElement); if(fsBtn) fsBtn.textContent=on?'🗕':'⛶'; setTimeout(fit,60); }
document.addEventListener('fullscreenchange', onFsChange); document.addEventListener('webkitfullscreenchange', onFsChange);
addEventListener('keydown', e=>{ if((e.key==='f'||e.key==='F') && !nameEntryOpen){ toggleFullscreen(); } });
</script>
<script src="https://www.youtube.com/iframe_api"></script>

<script>
(function(){
  const el = document.getElementById('bobinaAuth');
  if(!el) return;

  function loginHref(){
    let h='';
    try{ h=(localStorage.getItem('bobina_handle')||'').replace(/[^A-Za-z0-9_]/g,''); }catch(e){}
    return h ? ('/auth/bobina?claim_handle='+encodeURIComponent(h)) : '/auth/bobina';
  }

  function applyMe(me){
    window.bobinaMe = (me && me.authenticated) ? me : null;
    if(typeof window.__setBobinaMe === 'function'){
      try{ window.__setBobinaMe(me); }catch(e){}
    }
  }

  function paint(me){
    applyMe(me);
    if(!me || !me.authenticated){
      el.innerHTML = '<a href="'+loginHref()+'">Sign in with Bobina</a>';
      return;
    }
    const name = me.username ? '@'+me.username : 'Bobina player';
    const img = me.avatar ? '<img src="'+String(me.avatar).replace(/"/g,'')+'" alt="">' : '🐻';
    const link = me.profileUrl || 'https://bobina.moe';
    const linkedN = me.linkedScores|0;
    const linked = linkedN > 0
      ? (' · '+linkedN+' run'+(linkedN===1?'':'s')+' on board')
      : ' · account linked';
    el.innerHTML = '<span class="who">'+img+' <a href="'+link+'" target="_blank" rel="noopener" style="background:none;box-shadow:none;padding:0;color:#ffd0e4">'+name+'</a><span style="opacity:.7;font-size:11px">'+linked+'</span></span>'
      + '<button type="button" class="ghost" id="bobinaLogout">Sign out</button>';
    const b = document.getElementById('bobinaLogout');
    if(b) b.onclick = function(){
      fetch('/auth/logout',{method:'POST',credentials:'same-origin'}).then(function(){ location.href='/'; });
    };
  }

  function loadMe(){
    return fetch('/api/me',{credentials:'same-origin'})
      .then(function(r){ return r.json(); })
      .then(paint)
      .catch(function(){ paint({authenticated:false,bobinaConfigured:false}); });
  }

  function syncAccount(){
    return fetch('/api/sync',{method:'POST',credentials:'same-origin'})
      .then(function(r){ return r.json(); })
      .then(function(d){
        return loadMe().then(function(){
          // Pull emblems/arsenal/stats/shop into this device, then push merged snapshot
          const pull = (typeof window.cloudPullAndMerge==='function')
            ? window.cloudPullAndMerge()
            : Promise.resolve(null);
          return pull.then(function(){
            if(typeof fetchLB === 'function'){ try{ fetchLB(); }catch(e){} }
            return d;
          });
        });
      })
      .catch(function(e){ console.warn('sync failed', e); return loadMe(); });
  }

  try{
    const sp = new URLSearchParams(location.search);
    if(sp.get('bobina') === '1'){
      // OAuth just finished — force DB claim + profile resolve
      syncAccount().finally(function(){
        try{ history.replaceState(null,'',location.pathname); }catch(e){}
      });
    } else {
      loadMe().then(function(){
        if(window.bobinaMe && window.bobinaMe.authenticated){
          syncAccount(); // includes full game-progress merge
        }
      });
    }
  }catch(e){ loadMe(); }
})();
