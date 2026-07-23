function loop(now){
  if(now===undefined) now=(typeof performance!=='undefined'?performance.now():0);
  if(_lastFrame===null) _lastFrame=now;
  let frameMs=now-_lastFrame; _lastFrame=now;
  if(frameMs>100) frameMs=100;   // clamp big gaps (tab-out / hitch) so we don't spiral catching up
  _simAcc+=frameMs;
  let steps=0;
  while(_simAcc>=simStepMs && steps<6){ simStep(); _simAcc-=simStepMs; steps++; }
  draw();
  if(typeof debugLayer!=='undefined' && debugLayer && typeof drawDebugLayer==='function') drawDebugLayer();
  drawEmblemToasts(); updatePortrait(); manageGifOverlays(); manageTouchUI();
  { const ps=document.getElementById('pausescreen'), want=(state==='play'&&paused); if(ps && ps._on!==want){ ps._on=want; ps.classList.toggle('on',want); if(want) syncPauseUI(); } }
  // Title-only chrome: Bobina login + social strip
  const wantSocial=(state==='title');
  document.body.classList.toggle('on-title', wantSocial);
  if(wantSocial!==socialShown){ socialShown=wantSocial; if(socialEl) socialEl.style.display=wantSocial?'flex':'none'; }
  // On reaching an end screen, prompt once for a leaderboard name
  if((state==='win'||state==='gameover') && !endHandled){ endHandled=true; endWon=(state==='win'); showNameEntry(); }
  requestAnimationFrame(loop);
}
