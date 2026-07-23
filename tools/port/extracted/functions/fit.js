function fit(){ const vv=window.visualViewport; const vw=vv?vv.width:window.innerWidth, vh=vv?vv.height:window.innerHeight;
  const wantP = false;   // mobile is landscape-only (portrait shows the rotate prompt) — the HUD control panel lives in the landscape layout
  if(wantP!==portrait || cv.width!==(wantP?540:960)){ applyLayout(wantP, vw, vh); }
  const s=Math.min(vw/W, vh/H)*(typeof displayScale==="number"?displayScale:1); const cwv=Math.round(W*s), chv=Math.round(H*s);
  cv.style.width=cwv+'px'; cv.style.height=chv+'px';
  const r=document.documentElement.style; r.setProperty('--mx', Math.max(0,(vw-cwv)/2)+'px'); r.setProperty('--my', Math.max(0,(vh-chv)/2)+'px');
  document.body.classList.toggle('portrait', portrait); }
