function manageGifOverlays(){
  // Bobina's talking gif — only while HER dialog line is on screen
  let showTalk=false, cur=null;
  if((state==='play'||state==='intro') && dialog){ cur=dialog.queue[dialog.i]; if(cur && cur.w===1) showTalk=true; }
  if(showTalk){ const y=PF.y+PF.h-96; overlayShow(talkEl, PF.x+8+40, y+44, 56, 56); } else overlayHide(talkEl);
  // leek-spin celebration gif — only on the stage-clear screen
  if(state==='stageclear' && leekRect){ overlayShow(leekEl, leekRect.cx, leekRect.cy, leekRect.w, leekRect.h); } else overlayHide(leekEl);
}
