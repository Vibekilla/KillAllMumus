function cloudPullAndMerge(){
  if(!cloudLinked()) return Promise.resolve(null);
  return fetch('/api/progress',{credentials:'same-origin'})
    .then(function(r){ return r.json(); })
    .then(function(d){
      if(!d || !d.ok) return null;
      const local = buildProgressSnapshot();
      // Server already merges on PUT; first apply remote, then push local merge
      if(d.progress && d.progress.emblems){
        // merge local onto remote by applying remote first then local-over-max via apply+put
        applyProgressSnapshot(d.progress);
      }
      // Push combined (local had been in memory; apply remote already unioned via server on next put)
      // Local vars may still hold local-only unlocks — push full snapshot so server merges max/union
      return fetch('/api/progress',{
        method:'PUT', credentials:'same-origin',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ progress: buildProgressSnapshot() })
      }).then(function(r){ return r.json(); }).then(function(d2){
        if(d2 && d2.ok && d2.progress) applyProgressSnapshot(d2.progress);
        _cloudPullDone=true;
        return d2;
      });
    })
    .catch(function(e){ console.warn('cloud pull failed', e); return null; });
}
