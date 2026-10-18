function drawDebugLayer(){
  try{
    const fps = (typeof _lastFrame==='number' && typeof performance!=='undefined')
      ? Math.round(1000/Math.max(1, (performance.now()-(_dbgLast||_lastFrame)))) : 0;
    _dbgLast = typeof performance!=='undefined'?performance.now():0;
    ctx.save();
    ctx.setTransform(1,0,0,1,0,0);
    ctx.fillStyle='rgba(0,0,0,0.55)'; ctx.fillRect(8,8,210,92);
    ctx.strokeStyle='#7ed957'; ctx.strokeRect(8,8,210,92);
    ctx.fillStyle='#7ed957'; ctx.font='bold 12px monospace'; ctx.textAlign='left';
    ctx.fillText('DEBUG', 16, 26);
    ctx.fillStyle='#c8f0c8'; ctx.font='11px monospace';
    ctx.fillText('state: '+state+(paused?' (paused)':''), 16, 44);
    ctx.fillText('scale: '+Math.round(displayScale*100)+'%  sim: '+refreshRate+'Hz', 16, 60);
    ctx.fillText('canvas: '+W+'×'+H, 16, 76);
    if(typeof player!=='undefined' && player) ctx.fillText('player: '+Math.round(player.x)+','+Math.round(player.y), 16, 92);
    ctx.restore();
  }catch(e){}
}
(function(){
  const scale=document.getElementById('disp-scale');
  if(scale) scale.addEventListener('input',()=>setDisplayScale(scale.value));
  document.querySelectorAll('.disp-preset').forEach(b=>b.addEventListener('click',()=>setDisplayScale(b.dataset.scale)));
  document.querySelectorAll('.disp-hz').forEach(b=>b.addEventListener('click',()=>setRefreshRate(b.dataset.hz)));
  const dbg=document.getElementById('disp-debug'); if(dbg) dbg.addEventListener('click',()=>setDebugLayer(!debugLayer));
  const fs=document.getElementById('disp-fs'); if(fs) fs.addEventListener('click',()=>{ if(typeof toggleFullscreen==='function') toggleFullscreen(); setTimeout(syncDisplayUI,80); });
  const cl=document.getElementById('disp-close'); if(cl) cl.addEventListener('click', closeDisplay);
  const d=document.getElementById('display'); if(d) d.addEventListener('click',e=>{ if(e.target===d) closeDisplay(); });
  const sd=document.getElementById('set-display'); if(sd) sd.addEventListener('click', openDisplay);
  const pd=document.getElementById('ps-display'); if(pd) pd.addEventListener('click', openDisplay);
})();

// ---- Fullscreen ----
