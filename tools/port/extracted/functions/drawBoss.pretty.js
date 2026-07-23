function drawBoss(b) {
  const d = b.data,
    flash = b.flash > 0;
  if (b.hell) drawHellPortal(b); // fiery portal opens beneath James Wynn
  ctx.save();
  ctx.translate(b.x + (b.hell ? b.hellShake || 0 : 0), b.y);
  if (b.hell) {
    ctx.rotate(b.hellSpin || 0);
    const s = b.hellScale !== undefined ? b.hellScale : 1;
    ctx.scale(s, s);
  } else {
    ctx.save();
    ctx.shadowColor = d.color;
    ctx.shadowBlur = 30;
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = d.color;
    ctx.beginPath();
    ctx.arc(0, 0, b.r * 1.2, 0, 7);
    ctx.fill();
    ctx.restore();
    ctx.rotate((b.face !== undefined ? b.face : Math.PI / 2) - Math.PI / 2);
  } // face travel direction (360)
  if (d.portrait === 'ape') {
    drawApe(b, flash);
  }
  else if (d.portrait === 'robotnik') drawRobotnik(b, flash);
  else if (d.portrait === 'mumina') drawMumina(b, flash);
  else if (d.portrait === 'lily') drawLily(b, flash);
  else if (d.portrait === 'police') drawPolice(b, flash);
  else if (d.portrait === 'bogdanoff') drawBogdanoff(b, flash);
  else drawWynn(b, flash);
  ctx.restore();
  if (b.dead && !b.hell) {
    ctx.save();
    ctx.globalAlpha = 0.5 + 0.5 * Math.sin(tick * 0.3);
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(b.x, b.y, b.r * (1 + b.deadT * 0.02), 0, 7);
    ctx.fill();
    ctx.restore();
  }
}
