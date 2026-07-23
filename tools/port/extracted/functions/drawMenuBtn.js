function drawMenuBtn(cx,y){ const w=150,h=28,x=cx-w/2; menuBtn={x,y,w,h};
  ctx.fillStyle='rgba(30,16,40,0.85)'; ctx.beginPath(); ctx.roundRect(x,y,w,h,8); ctx.fill(); ctx.strokeStyle='#8fd0ff'; ctx.lineWidth=1.5; ctx.stroke();
  ctx.fillStyle='#8fd0ff'; ctx.font='bold 13px "Trebuchet MS"'; ctx.textAlign='center'; ctx.fillText('⌂ MAIN MENU  [M]', cx, y+19); ctx.textAlign='left'; }
