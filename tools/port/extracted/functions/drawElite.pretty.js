function drawElite(e) {
  const R = e.r,
    fl = e.flash > 0,
    bob = Math.sin(e.t * 0.14) * 1.6,
    ln = '#2a1a12';
  ctx.save();
  ctx.translate(e.x, e.y);
  ctx.fillStyle = 'rgba(0,0,0,0.2)';
  ctx.beginPath();
  ctx.ellipse(0, R * 0.98, R * 0.72, 4, 0, 0, 7);
  ctx.fill();
  ctx.translate(0, bob);
  const K = e.elite;
  if (K === 'cheer') {
    // Mini Mumina — a bear-girl like Bobina in a green cheer kit, waving pom-poms
    const skin = fl ? '#fff' : '#7c4c31',
      hair = fl ? '#fff' : '#181320',
      dress = fl ? '#fff' : '#7ed957',
      trim = fl ? '#fff' : '#eafff0';
    const pw = Math.sin(e.t * 0.3) * R * 0.12; // pom shake
    ctx.strokeStyle = skin;
    ctx.lineWidth = R * 0.15;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-R * 0.3, -R * 0.05);
    ctx.lineTo(-R * 0.7, -R * 0.42);
    ctx.moveTo(R * 0.3, -R * 0.05);
    ctx.lineTo(R * 0.7, -R * 0.42);
    ctx.stroke();
    ctx.fillStyle = fl ? '#fff' : '#c8ff9a';
    for (const sx of [-1, 1]) {
      for (let k = 0; k < 8; k++) {
        const a = (k / 8) * 6.28;
        ctx.beginPath();
        ctx.arc(
          sx * R * 0.72 + pw * sx + Math.cos(a) * R * 0.17,
          -R * 0.5 + Math.sin(a) * R * 0.17,
          R * 0.11,
          0,
          7,
        );
        ctx.fill();
      }
    } // pom-poms
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.moveTo(-R * 0.4, -R * 0.08);
    ctx.lineTo(-R * 0.6, R * 0.62);
    ctx.lineTo(R * 0.6, R * 0.62);
    ctx.lineTo(R * 0.4, -R * 0.08);
    ctx.closePath();
    ctx.fill(); // flared skirt
    ctx.fillStyle = trim;
    for (let i = -R * 0.55; i < R * 0.5; i += R * 0.24) {
      ctx.beginPath();
      ctx.arc(i + R * 0.12, R * 0.62, R * 0.12, 0, Math.PI);
      ctx.fill();
    }
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.roundRect(-R * 0.42, -R * 0.28, R * 0.84, R * 0.42, R * 0.12);
    ctx.fill(); // top
    ctx.fillStyle = trim;
    ctx.fillRect(-R * 0.42, -R * 0.02, R * 0.84, R * 0.09); // midriff trim
    ctx.strokeStyle = skin;
    ctx.lineWidth = R * 0.15;
    ctx.beginPath();
    ctx.moveTo(-R * 0.2, R * 0.58);
    ctx.lineTo(-R * 0.24, R * 0.88);
    ctx.moveTo(R * 0.2, R * 0.58);
    ctx.lineTo(R * 0.24, R * 0.88);
    ctx.stroke(); // legs
    ctx.fillStyle = hair;
    ctx.beginPath();
    ctx.arc(0, -R * 0.5, R * 0.5, Math.PI * 0.9, Math.PI * 2.1);
    ctx.fill(); // hair back
    circle(-R * 0.52, -R * 0.46, R * 0.17, hair);
    circle(R * 0.52, -R * 0.46, R * 0.17, hair); // pigtails
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.arc(0, -R * 0.5, R * 0.42, 0, 7);
    ctx.fill(); // face
    circle(-R * 0.32, -R * 0.86, R * 0.15, hair);
    circle(R * 0.32, -R * 0.86, R * 0.15, hair);
    circle(-R * 0.32, -R * 0.86, R * 0.07, fl ? '#fff' : '#5f3823');
    circle(R * 0.32, -R * 0.86, R * 0.07, fl ? '#fff' : '#5f3823'); // bear ears
    ctx.fillStyle = hair;
    ctx.beginPath();
    ctx.moveTo(-R * 0.42, -R * 0.62);
    ctx.quadraticCurveTo(0, -R * 0.98, R * 0.42, -R * 0.62);
    ctx.lineTo(R * 0.3, -R * 0.5);
    ctx.quadraticCurveTo(0, -R * 0.72, -R * 0.3, -R * 0.5);
    ctx.closePath();
    ctx.fill(); // bangs
    circle(-R * 0.16, -R * 0.46, R * 0.1, '#fff');
    circle(R * 0.16, -R * 0.46, R * 0.1, '#fff');
    ctx.fillStyle = '#3a2018';
    circle(-R * 0.16, -R * 0.44, R * 0.05, '#3a2018');
    circle(R * 0.16, -R * 0.44, R * 0.05, '#3a2018');
    ctx.fillStyle = 'rgba(255,120,150,0.5)';
    circle(-R * 0.29, -R * 0.33, R * 0.07, 'rgba(255,120,150,0.5)');
    circle(R * 0.29, -R * 0.33, R * 0.07, 'rgba(255,120,150,0.5)');
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.arc(0, -R * 0.37, R * 0.1, 0.15 * Math.PI, 0.85 * Math.PI);
    ctx.stroke(); // smile
  } else if (K === 'ape') {
    const fur = fl ? '#fff' : '#a9743e',
      face = fl ? '#fff' : '#e8c9a0';
    ctx.fillStyle = fur;
    circle(-R * 0.7, -R * 0.15, R * 0.28, fur);
    circle(R * 0.7, -R * 0.15, R * 0.28, fur); // ears
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.arc(0, 0, R * 0.8, 0, 7);
    ctx.fill();
    ctx.fillStyle = face;
    ctx.beginPath();
    ctx.ellipse(0, R * 0.14, R * 0.5, R * 0.56, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#3a2410';
    ctx.fillRect(-R * 0.4, -R * 0.16, R * 0.8, R * 0.13); // heavy brow (bored ape)
    circle(-R * 0.2, 0.02 * R, R * 0.09, '#fff');
    circle(R * 0.2, 0.02 * R, R * 0.09, '#fff');
    ctx.fillStyle = '#150a0a';
    circle(-R * 0.2, R * 0.03, R * 0.045, '#150a0a');
    circle(R * 0.2, R * 0.03, R * 0.045, '#150a0a');
    ctx.fillStyle = '#7a2c2c';
    ctx.beginPath();
    ctx.ellipse(0, R * 0.36, R * 0.24, R * 0.13, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#ffd24a';
    ctx.fillRect(-R * 0.14, R * 0.31, R * 0.28, R * 0.06); // gold grill
    ctx.strokeStyle = '#ffd24a';
    ctx.lineWidth = 2.2;
    ctx.beginPath();
    ctx.arc(0, R * 0.72, R * 0.42, 0.16 * Math.PI, 0.84 * Math.PI);
    ctx.stroke(); // jeet chain
  } else if (K === 'badnik') {
    const metal = fl ? '#fff' : '#c2c8ce',
      sh = '#8a929a',
      pink = fl ? '#fff' : '#e05a86';
    ctx.fillStyle = metal;
    ctx.beginPath();
    ctx.ellipse(0, 0, R * 0.62, R * 0.82, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = sh;
    ctx.beginPath();
    ctx.ellipse(R * 0.22, R * 0.05, R * 0.2, R * 0.7, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = pink;
    ctx.beginPath();
    ctx.arc(0, -R * 0.12, R * 0.26, 0, 7);
    ctx.fill();
    circle(0, -R * 0.12, R * 0.16, '#fff');
    ctx.fillStyle = '#150a0a';
    circle(0, -R * 0.1, R * 0.08, '#150a0a');
    ctx.strokeStyle = sh;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(0, -R * 0.8);
    ctx.lineTo(0, -R * 1.06);
    ctx.stroke();
    circle(0, -R * 1.12, R * 0.1, pink);
    ctx.fillStyle = sh;
    for (const a of [0.4, 1.2, 2.0, 2.7]) {
      circle(Math.cos(a) * R * 0.5, Math.sin(a) * R * 0.5 + R * 0.25, R * 0.05, sh);
    } // rivets
  } else if (K === 'pup') {
    const fur = fl ? '#fff' : '#d8b48a',
      sh = fl ? '#fff' : '#b48a5e',
      purp = fl ? '#fff' : '#9945ff';
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.ellipse(0, R * 0.12, R * 0.6, R * 0.55, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = sh;
    ctx.beginPath();
    ctx.moveTo(-R * 0.4, -R * 0.5);
    ctx.lineTo(-R * 0.56, -R * 0.95);
    ctx.lineTo(-R * 0.12, -R * 0.55);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(R * 0.4, -R * 0.5);
    ctx.lineTo(R * 0.56, -R * 0.95);
    ctx.lineTo(R * 0.12, -R * 0.55);
    ctx.fill(); // pointy ears
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.arc(0, -R * 0.32, R * 0.44, 0, 7);
    ctx.fill();
    ctx.fillStyle = fl ? '#fff' : '#f0dcc4';
    ctx.beginPath();
    ctx.ellipse(0, -R * 0.16, R * 0.22, R * 0.18, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#150a0a';
    circle(0, -R * 0.26, R * 0.08, '#150a0a');
    circle(-R * 0.16, -R * 0.4, R * 0.06, '#150a0a');
    circle(R * 0.16, -R * 0.4, R * 0.06, '#150a0a');
    ctx.fillStyle = '#ff7a9c';
    ctx.beginPath();
    ctx.ellipse(0, -R * 0.04, R * 0.07, R * 0.14, 0, 0, 7);
    ctx.fill(); // tongue
    ctx.fillStyle = purp;
    ctx.fillRect(-R * 0.4, R * 0.02, R * 0.8, R * 0.13);
    circle(0, R * 0.09, R * 0.09, '#14f195'); // SOL collar + tag
  } else if (K === 'scammer') {
    const skin = fl ? '#fff' : '#c9a06a',
      shirt = fl ? '#fff' : '#e08a2a',
      hs = '#222';
    ctx.fillStyle = shirt;
    ctx.beginPath();
    ctx.roundRect(-R * 0.5, 0, R * 1.0, R * 0.72, R * 0.14);
    ctx.fill();
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.arc(0, -R * 0.4, R * 0.4, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#241810';
    ctx.beginPath();
    ctx.arc(0, -R * 0.52, R * 0.4, Math.PI, 0);
    ctx.fill();
    ctx.strokeStyle = hs;
    ctx.lineWidth = R * 0.08;
    ctx.beginPath();
    ctx.arc(0, -R * 0.42, R * 0.44, Math.PI * 1.12, Math.PI * 1.88);
    ctx.stroke();
    circle(-R * 0.44, -R * 0.4, R * 0.1, hs);
    ctx.strokeStyle = hs;
    ctx.lineWidth = R * 0.05;
    ctx.beginPath();
    ctx.moveTo(-R * 0.44, -R * 0.34);
    ctx.quadraticCurveTo(-R * 0.24, -R * 0.16, -R * 0.1, -R * 0.22);
    ctx.stroke(); // mic boom
    circle(-R * 0.14, -R * 0.42, R * 0.05, '#150a0a');
    circle(R * 0.14, -R * 0.42, R * 0.05, '#150a0a');
    ctx.strokeStyle = '#7a2c2c';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-R * 0.12, -R * 0.24);
    ctx.lineTo(R * 0.12, -R * 0.24);
    ctx.stroke();
    ctx.fillStyle = '#111';
    ctx.beginPath();
    ctx.roundRect(R * 0.42, R * 0.12, R * 0.15, R * 0.3, R * 0.04);
    ctx.fill(); // phone
  } else if (K === 'voideye') {
    // AKASHIC EYE — an ornate all-seeing GOLD eye in a rune frame; reads the Records
    // (deliberately distinct from Call of the Void's purple, tentacle-spoked servitors — no confusion)
    const gold = fl ? '#fff' : '#e0b84a',
      goldD = '#9a7a2a',
      vio = fl ? '#fff' : '#b48ce0',
      dark = '#140e22';
    const rot = e.t * 0.02;
    ctx.save();
    ctx.rotate(rot); // rotating gold rune ring + tick marks (a cosmic ledger, not tentacles)
    ctx.strokeStyle = _hexA(gold, 0.7);
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(0, 0, R * 0.92, 0, 7);
    ctx.stroke();
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * 6.283;
      ctx.beginPath();
      ctx.moveTo(Math.cos(a) * R * 0.92, Math.sin(a) * R * 0.92);
      ctx.lineTo(Math.cos(a) * R * 1.04, Math.sin(a) * R * 1.04);
      ctx.stroke();
    }
    ctx.restore();
    ctx.save();
    ctx.rotate(-rot * 0.6);
    ctx.strokeStyle = _hexA(vio, 0.5);
    ctx.lineWidth = 1.6; // counter-rotating violet triangle
    ctx.beginPath();
    for (let i = 0; i <= 3; i++) {
      const a = (i / 3) * 6.283;
      const x = Math.cos(a) * R * 0.78,
        y = Math.sin(a) * R * 0.78;
      i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
    }
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.moveTo(-R * 0.72, 0);
    ctx.quadraticCurveTo(0, -R * 0.5, R * 0.72, 0);
    ctx.quadraticCurveTo(0, R * 0.5, -R * 0.72, 0);
    ctx.closePath();
    ctx.fill(); // gold almond eye
    ctx.strokeStyle = goldD;
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = dark;
    ctx.beginPath();
    ctx.arc(0, 0, R * 0.34, 0, 7);
    ctx.fill(); // dark cosmic iris
    ctx.save();
    ctx.shadowColor = vio;
    ctx.shadowBlur = 8;
    ctx.fillStyle = vio;
    ctx.beginPath();
    ctx.ellipse(0, 0, R * 0.12, R * 0.28, 0, 0, 7);
    ctx.fill();
    ctx.restore(); // vertical violet slit pupil
    ctx.fillStyle = '#f4ecff';
    ctx.beginPath();
    ctx.ellipse(-R * 0.06, -R * 0.08, R * 0.04, R * 0.09, 0, 0, 7);
    ctx.fill(); // glint
    for (let i = 0; i < 3; i++) {
      const a = rot * 2 + i * 2.1,
        rr = R * 0.2;
      circle(Math.cos(a) * rr, Math.sin(a) * rr, R * 0.02, _hexA('#fff', 0.8));
    } // record-sparkles
  } else {
    // goon — cabal suit
    const suit = fl ? '#fff' : '#2a2f3a',
      skin = fl ? '#fff' : '#c9a06a',
      tie = fl ? '#fff' : '#ff5b3c';
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.moveTo(-R * 0.55, R * 0.62);
    ctx.lineTo(-R * 0.5, -R * 0.06);
    ctx.lineTo(R * 0.5, -R * 0.06);
    ctx.lineTo(R * 0.55, R * 0.62);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#f2f4f8';
    ctx.beginPath();
    ctx.moveTo(-R * 0.14, -R * 0.06);
    ctx.lineTo(0, R * 0.5);
    ctx.lineTo(R * 0.14, -R * 0.06);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = tie;
    ctx.beginPath();
    ctx.moveTo(-R * 0.06, 0);
    ctx.lineTo(R * 0.06, 0);
    ctx.lineTo(R * 0.09, R * 0.4);
    ctx.lineTo(0, R * 0.5);
    ctx.lineTo(-R * 0.09, R * 0.4);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.arc(0, -R * 0.4, R * 0.38, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#161616';
    ctx.beginPath();
    ctx.arc(0, -R * 0.54, R * 0.38, Math.PI, 0);
    ctx.fill();
    ctx.fillStyle = '#111';
    ctx.beginPath();
    ctx.roundRect(-R * 0.28, -R * 0.46, R * 0.56, R * 0.16, R * 0.05);
    ctx.fill();
    ctx.fillStyle = tie;
    ctx.fillRect(-R * 0.02, -R * 0.44, R * 0.04, R * 0.1); // shades
  }
  ctx.restore();
}
