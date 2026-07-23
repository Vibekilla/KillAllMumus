function applyLayout(p, vw, vh){
  if(p){   // PORTRAIT: canvas matches the phone aspect so it fills the screen; the square playfield is pinned near the top
    const aspect=Math.max(1.15, Math.min(2.35, (vh||852)/(vw||393)));
    cv.width=540; cv.height=Math.round(540*aspect);
    PF={x:14, y:84, w:512, h:516};
    PANEL={x:8, y:PF.y+PF.h+10, w:524, h:cv.height-(PF.y+PF.h+10)-8};   // compact bottom HUD strip
  } else {  // LANDSCAPE / desktop: original layout, byte-for-byte the same
    cv.width=960; cv.height=540;
    PF={x:48, y:14, w:512, h:516};
    PANEL={x:PF.x+PF.w+16, y:14, w:960-(PF.x+PF.w+16)-14, h:516};
  }
  portrait=!!p; W=cv.width; H=cv.height; COLLECT_LINE=PF.y+96;
  ctx.lineJoin='round'; ctx.lineCap='round';
}
