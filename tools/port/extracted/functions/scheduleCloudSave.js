function scheduleCloudSave(immediate){
  if(!cloudLinked()) return;
  if(_cloudTimer) clearTimeout(_cloudTimer);
  const run=function(){
    if(!cloudLinked() || _cloudBusy) return;
    _cloudBusy=true;
    const sentRev=arsenalRev;
    const snap=buildProgressSnapshot();
    fetch('/api/progress',{
      method:'PUT', credentials:'same-origin',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ progress: snap })
    }).then(function(r){ return r.json(); }).then(function(d){
      if(d && d.ok && d.progress){
        // Bar order is the client's loadout. Only accept the echo when nothing
        // newer was equipped while this request was in flight.
        if(arsenalRev===sentRev) arsenalCloudRev=arsenalRev;
        applyProgressSnapshot(d.progress);
      }
    }).catch(function(e){ console.warn('cloud save failed', e); })
     .finally(function(){ _cloudBusy=false; });
  };
  if(immediate) run(); else _cloudTimer=setTimeout(run, 1200);
}
