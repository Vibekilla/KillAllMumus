function drawMumu(e) {
  if (e.kind === 'elite') {
    drawElite(e);
    return;
  }
  const flash = e.flash > 0,
    R = e.r;
  ctx.save();
  ctx.translate(e.x, e.y);
  const body = flash ? '#fff' : e.icy ? '#bfe6ff' : '#d9a487',
    bodySh = e.icy ? '#8fc4ee' : '#b07a5e',
    belly = flash ? '#fff' : e.icy ? '#eaf6ff' : '#f4e0d2',
    horn = '#efe6d2',
    ln = '#3a2018';
  const bob = Math.sin(e.t * 0.14) * 1.5;
  ctx.fillStyle = 'rgba(0,0,0,0.18)';
  ctx.beginPath();
  ctx.ellipse(0, R * 0.9, R * 0.7, 4, 0, 0, 7);
  ctx.fill();
  ctx.beginPath();
  ctx.ellipse(0, bob, R * 0.8, R * 0.78, 0, 0, 7);
  ctx.strokeStyle = ln;
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.fillStyle = body;
  ctx.fill();
  ctx.fillStyle = belly;
  ctx.beginPath();
  ctx.ellipse(0, bob + R * 0.28, R * 0.4, R * 0.42, 0, 0, 7);
  ctx.fill();
  ctx.fillStyle = flash ? '#fff' : bodySh;
  circle(-R * 0.7, bob + R * 0.3, R * 0.2, flash ? '#fff' : bodySh);
  circle(R * 0.7, bob + R * 0.3, R * 0.2, flash ? '#fff' : bodySh);
  ctx.beginPath();
  ctx.ellipse(-R * 0.72, bob - R * 0.5, R * 0.22, R * 0.15, -0.6, 0, 7);
  ctx.fill();
  ctx.beginPath();
  ctx.ellipse(R * 0.72, bob - R * 0.5, R * 0.22, R * 0.15, 0.6, 0, 7);
  ctx.fill();
  ctx.fillStyle = flash ? '#fff' : horn;
  ctx.beginPath();
  ctx.moveTo(-R * 0.5, bob - R * 0.55);
  ctx.quadraticCurveTo(-R * 0.95, bob - R * 0.95, -R * 0.5, bob - R * 1.05);
  ctx.quadraticCurveTo(-R * 0.4, bob - R * 0.75, -R * 0.3, bob - R * 0.6);
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(R * 0.5, bob - R * 0.55);
  ctx.quadraticCurveTo(R * 0.95, bob - R * 0.95, R * 0.5, bob - R * 1.05);
  ctx.quadraticCurveTo(R * 0.4, bob - R * 0.75, R * 0.3, bob - R * 0.6);
  ctx.fill();
  ctx.fillStyle = flash ? '#fff' : belly;
  ctx.beginPath();
  ctx.ellipse(0, bob + R * 0.18, R * 0.34, R * 0.26, 0, 0, 7);
  ctx.fill();
  ctx.strokeStyle = ln;
  ctx.lineWidth = 1;
  ctx.stroke();
  ctx.fillStyle = bodySh;
  circle(-R * 0.14, bob + R * 0.14, R * 0.06, bodySh);
  circle(R * 0.14, bob + R * 0.14, R * 0.06, bodySh);
  ctx.fillStyle = '#fff';
  circle(-R * 0.28, bob - R * 0.08, R * 0.18, '#fff');
  circle(R * 0.28, bob - R * 0.08, R * 0.18, '#fff');
  ctx.fillStyle = '#c0202a';
  circle(-R * 0.28, bob - R * 0.05, R * 0.09, '#c0202a');
  circle(R * 0.28, bob - R * 0.05, R * 0.09, '#c0202a');
  ctx.fillStyle = '#150a0a';
  circle(-R * 0.28, bob - R * 0.05, R * 0.04, '#150a0a');
  circle(R * 0.28, bob - R * 0.05, R * 0.04, '#150a0a');
  ctx.strokeStyle = ln;
  ctx.lineWidth = 1.6;
  ctx.beginPath();
  ctx.moveTo(-R * 0.45, bob - R * 0.3);
  ctx.lineTo(-R * 0.14, bob - R * 0.16);
  ctx.moveTo(R * 0.45, bob - R * 0.3);
  ctx.lineTo(R * 0.14, bob - R * 0.16);
  ctx.stroke();
  if (e.icy) {
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-R * 0.5, -R * 0.2);
    ctx.lineTo(R * 0.5, R * 0.2);
    ctx.moveTo(R * 0.4, -R * 0.4);
    ctx.lineTo(-R * 0.3, R * 0.4);
    ctx.stroke();
  }
  ctx.restore();
}
