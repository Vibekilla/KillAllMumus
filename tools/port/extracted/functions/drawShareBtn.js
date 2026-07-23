function drawShareBtn(cx,y,won){ const w=272,h=34,x=cx-w/2; shareBtn={x,y,w,h,won};
  if(justSavedScore){ ctx.fillStyle='#7ed957'; ctx.font='bold 12px monospace'; ctx.textAlign='center'; ctx.fillText('✓ Saved to the global leaderboard — flex it below!', cx, y-9); ctx.textAlign='left'; }
  ctx.fillStyle='#000'; ctx.beginPath(); ctx.roundRect(x,y,w,h,8); ctx.fill(); ctx.strokeStyle='#3a3a3a'; ctx.lineWidth=1.5; ctx.stroke();
  // X / Twitter glyph
  ctx.fillStyle='#fff'; ctx.font='bold 17px Georgia,serif'; ctx.textAlign='center'; ctx.fillText('X', x+24, y+23);
  ctx.font='bold 15px "Trebuchet MS"'; ctx.fillText('Share your result', cx+12, y+22); ctx.textAlign='left';
}
