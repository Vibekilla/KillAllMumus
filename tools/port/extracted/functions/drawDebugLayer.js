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
