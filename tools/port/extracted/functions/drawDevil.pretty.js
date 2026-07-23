function drawDevil(b, flash) {
  const R = b.r;
  ctx.fillStyle = flash ? '#fff' : '#7a1420';
  ctx.beginPath();
  ctx.ellipse(0, R * 0.55, R * 0.82, R * 0.6, 0, 0, 7);
  ctx.fill();
  ctx.fillStyle = flash ? '#fff' : '#c0202a';
  ctx.beginPath();
  ctx.arc(0, -R * 0.08, R * 0.62, 0, 7);
  ctx.fill();
  // horns
  ctx.fillStyle = flash ? '#eee' : '#2a0a10';
  ctx.beginPath();
  ctx.moveTo(-R * 0.4, -R * 0.48);
  ctx.quadraticCurveTo(-R * 0.72, -R * 1.02, -R * 0.34, -R * 1.06);
  ctx.quadraticCurveTo(-R * 0.44, -R * 0.7, -R * 0.18, -R * 0.54);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(R * 0.4, -R * 0.48);
  ctx.quadraticCurveTo(R * 0.72, -R * 1.02, R * 0.34, -R * 1.06);
  ctx.quadraticCurveTo(R * 0.44, -R * 0.7, R * 0.18, -R * 0.54);
  ctx.closePath();
  ctx.fill();
  // glowing eyes
  ctx.save();
  ctx.shadowColor = '#ffd000';
  ctx.shadowBlur = 10;
  ctx.fillStyle = '#ffe23a';
  ctx.beginPath();
  ctx.moveTo(-R * 0.34, -R * 0.2);
  ctx.lineTo(-R * 0.08, -R * 0.1);
  ctx.lineTo(-R * 0.34, -R * 0.01);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(R * 0.34, -R * 0.2);
  ctx.lineTo(R * 0.08, -R * 0.1);
  ctx.lineTo(R * 0.34, -R * 0.01);
  ctx.closePath();
  ctx.fill();
  ctx.restore();
  ctx.fillStyle = '#1a0000';
  circle(-R * 0.2, -R * 0.1, R * 0.045, '#1a0000');
  circle(R * 0.2, -R * 0.1, R * 0.045, '#1a0000');
  // fanged grin
  ctx.strokeStyle = '#3a0000';
  ctx.lineWidth = 2.5;
  ctx.beginPath();
  ctx.arc(0, R * 0.04, R * 0.34, 0.18, Math.PI - 0.18);
  ctx.stroke();
  ctx.fillStyle = '#fff';
  for (let i = -2; i <= 2; i++) {
    const fx = i * R * 0.14;
    ctx.beginPath();
    ctx.moveTo(fx - R * 0.05, R * 0.2);
    ctx.lineTo(fx + R * 0.02, R * 0.2);
    ctx.lineTo(fx - R * 0.02, R * 0.32);
    ctx.closePath();
    ctx.fill();
  }
  // goatee
  ctx.fillStyle = '#2a0a10';
  ctx.beginPath();
  ctx.moveTo(-R * 0.1, R * 0.42);
  ctx.lineTo(R * 0.1, R * 0.42);
  ctx.lineTo(0, R * 0.64);
  ctx.closePath();
  ctx.fill();
}
