function cloudPullAndMerge(){
  if(!cloudLinked()) return Promise.resolve(null);
  const sentRev=arsenalRev;
  return fetch('/api/progress',{credentials:'same-origin'})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if(!d || !d.ok) return null;
      // Apply remote unlocks/stats. A bar edit this session (arsenalRev ahead)
      // is kept; otherwise the saved loadout order replaces this device.
      if(d.progress && d.progress.emblems){
        applyProgressSnapshot(d.progress);
      }
      // Push combined (local had been in memory; apply remote already unioned via server on next put)
      // Local vars may still hold local-only unlocks — push full snapshot so server merges max/union
      return fetch('/api/progress',{
        method:'PUT', credentials:'same-origin',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ progress: buildProgressSnapshot() })
      }).then(function(r){ return r.json(); }).then(function(d2){
        if(d2 && d2.ok && d2.progress){
          if(arsenalRev===sentRev) arsenalCloudRev=arsenalRev;
          applyProgressSnapshot(d2.progress);
        }
        _cloudPullDone=true;
        return d2;
      });
    })
    .catch(function(e){ console.warn('cloud pull failed', e); return null; });
}
// Hook all local save paths so linked accounts always persist server-side
(function hookCloudSaves(){
  function wrap(name, fn){
    if(typeof fn!=='function') return fn;
    return function(){
      const r = fn.apply(this, arguments);
      try{ scheduleCloudSave(false); }catch(e){}
      return r;
    };
  }
  if(typeof saveEmblems==='function') saveEmblems = wrap('saveEmblems', saveEmblems);
  if(typeof saveEstats==='function') saveEstats = wrap('saveEstats', saveEstats);
  if(typeof saveArsenal==='function') saveArsenal = wrap('saveArsenal', saveArsenal);
  if(typeof saveHeads==='function') saveHeads = wrap('saveHeads', saveHeads);
  if(typeof saveShopUnlocks==='function') saveShopUnlocks = wrap('saveShopUnlocks', saveShopUnlocks);
  if(typeof saveConsum==='function') saveConsum = wrap('saveConsum', saveConsum);
  if(typeof saveNgPrefs==='function') saveNgPrefs = wrap('saveNgPrefs', saveNgPrefs);
  if(typeof saveBinds==='function') saveBinds = wrap('saveBinds', saveBinds);
  // Patch outfit / pose / face / hell / ng unlock inline stores via proxy on localStorage for bobina_* keys
  try{
    const _set = localStorage.setItem.bind(localStorage);
    localStorage.setItem = function(k,v){
      const r = _set(k,v);
      if(typeof k==='string' && k.indexOf('bobina_')===0){
        // skip pure cloud bookkeeping
        if(k!=='bobina_invmigrated') try{ scheduleCloudSave(false); }catch(e){}
      }
      return r;
    };
  }catch(e){}
  _cloudReady=true;
})();
window.cloudPullAndMerge = cloudPullAndMerge;
window.scheduleCloudSave = scheduleCloudSave;
window.buildProgressSnapshot = buildProgressSnapshot;
