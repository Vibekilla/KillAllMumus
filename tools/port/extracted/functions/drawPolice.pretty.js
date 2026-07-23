function drawPolice(b, flash) {
  const R = b.r;
  const khaki = '#b59a4a',
    khakiD = '#8a742e',
    skin = '#7a4a28',
    skinSh = '#5f3820',
    cap = '#2a2a30',
    gold = '#ffd24a',
    saff = '#e08a2a';
  // khaki uniform shoulders
  ctx.fillStyle = flash ? '#fff' : khaki;
  ctx.beginPath();
  ctx.ellipse(0, R * 0.55, R * 0.92, R * 0.6, 0, 0, 7);
  ctx.fill();
  ctx.fillStyle = gold;
  ctx.beginPath();
  ctx.roundRect(-R * 0.86, R * 0.28, R * 0.3, R * 0.12, 2);
  ctx.roundRect(R * 0.56, R * 0.28, R * 0.3, R * 0.12, 2);
  ctx.fill(); // epaulettes
  ctx.fillStyle = khakiD;
  ctx.beginPath();
  ctx.moveTo(-R * 0.25, R * 0.1);
  ctx.lineTo(R * 0.25, R * 0.1);
  ctx.lineTo(0, R * 0.52);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = skinSh;
  ctx.fillRect(-R * 0.16, 0, R * 0.32, R * 0.18); // neck
  // face
  ctx.fillStyle = flash ? '#fff' : skin;
  ctx.beginPath();
  ctx.ellipse(0, -R * 0.12, R * 0.5, R * 0.55, 0, 0, 7);
  ctx.fill();
  ctx.fillStyle = skinSh;
  ctx.beginPath();
  ctx.ellipse(0, R * 0.18, R * 0.28, R * 0.14, 0, 0, Math.PI);
  ctx.fill();
  // angry brows
  ctx.strokeStyle = '#1a1008';
  ctx.lineWidth = R * 0.07;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-R * 0.32, -R * 0.18);
  ctx.lineTo(-R * 0.08, -R * 0.06);
  ctx.moveTo(R * 0.32, -R * 0.18);
  ctx.lineTo(R * 0.08, -R * 0.06);
  ctx.stroke();
  // corrupted glowing saffron eyes
  ctx.save();
  ctx.shadowColor = saff;
  ctx.shadowBlur = 8;
  circle(-R * 0.18, -R * 0.02, R * 0.09, flash ? '#fff' : saff);
  circle(R * 0.18, -R * 0.02, R * 0.09, flash ? '#fff' : saff);
  ctx.restore();
  ctx.fillStyle = '#2a1500';
  circle(-R * 0.18, -R * 0.02, R * 0.04, '#2a1500');
  circle(R * 0.18, -R * 0.02, R * 0.04, '#2a1500');
  // big mustache
  ctx.fillStyle = flash ? '#eee' : '#1a1008';
  ctx.beginPath();
  ctx.moveTo(0, R * 0.12);
  ctx.quadraticCurveTo(-R * 0.28, R * 0.06, -R * 0.34, R * 0.2);
  ctx.quadraticCurveTo(-R * 0.2, R * 0.16, 0, R * 0.18);
  ctx.quadraticCurveTo(R * 0.2, R * 0.16, R * 0.34, R * 0.2);
  ctx.quadraticCurveTo(R * 0.28, R * 0.06, 0, R * 0.12);
  ctx.fill();
  ctx.fillStyle = '#3a1414';
  ctx.beginPath();
  ctx.ellipse(0, R * 0.26, R * 0.12, R * 0.05, 0, 0, 7);
  ctx.fill(); // snarl
  // peaked police cap
  ctx.fillStyle = flash ? '#fff' : cap;
  ctx.beginPath();
  ctx.ellipse(0, -R * 0.5, R * 0.6, R * 0.3, 0, Math.PI, 0);
  ctx.fill();
  ctx.fillStyle = cap;
  ctx.beginPath();
  ctx.ellipse(0, -R * 0.42, R * 0.64, R * 0.16, 0, 0, 7);
  ctx.fill();
  ctx.fillStyle = '#12121a';
  ctx.beginPath();
  ctx.ellipse(0, -R * 0.34, R * 0.66, R * 0.12, 0, 0, Math.PI);
  ctx.fill(); // brim
  ctx.fillStyle = gold;
  ctx.beginPath();
  ctx.arc(0, -R * 0.5, R * 0.11, 0, 7);
  ctx.fill();
  ctx.fillStyle = saff;
  ctx.beginPath();
  ctx.arc(0, -R * 0.5, R * 0.05, 0, 7);
  ctx.fill(); // badge
  // call-center headset
  ctx.strokeStyle = '#20202a';
  ctx.lineWidth = R * 0.05;
  ctx.beginPath();
  ctx.arc(0, -R * 0.5, R * 0.6, Math.PI * 1.12, Math.PI * 1.88);
  ctx.stroke();
  ctx.fillStyle = '#20202a';
  ctx.beginPath();
  ctx.ellipse(R * 0.56, -R * 0.26, R * 0.09, R * 0.13, 0, 0, 7);
  ctx.fill();
  ctx.strokeStyle = '#20202a';
  ctx.lineWidth = R * 0.035;
  ctx.beginPath();
  ctx.moveTo(R * 0.56, -R * 0.16);
  ctx.quadraticCurveTo(R * 0.42, R * 0.12, R * 0.14, R * 0.22);
  ctx.stroke();
  ctx.fillStyle = saff;
  ctx.beginPath();
  ctx.arc(R * 0.14, R * 0.22, R * 0.045, 0, 7);
  ctx.fill();
}
