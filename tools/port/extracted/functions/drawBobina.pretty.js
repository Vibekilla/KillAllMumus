function drawBobina(p) {
  const lean = p.lean || 0;
  ctx.save();
  ctx.translate(p.x, p.y);
  if (p.iframe > 0 && Math.floor(p.iframe / 4) % 2) {
    ctx.globalAlpha = 0.5;
  }
  const breath = Math.sin(tick * 0.1) * 0.6; // gentle up/down
  const idle = Math.sin(tick * 0.12) * 0.7; // head bob
  const sway = Math.sin(tick * 0.09) * 1.3 + lean * 7; // skirt hem drift (+ trails when leaning)
  const sBob = Math.sin(tick * 0.13) * 0.9; // sleeve bob
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  // rotate the whole body to face her travel direction (full 360), about her centre
  const rot = (p.face !== undefined ? p.face : -Math.PI / 2) + Math.PI / 2;
  ctx.translate(0, -16);
  ctx.rotate(rot);
  ctx.translate(0, 16 + breath);
  // ground shadow + soft glow — drawn INSIDE the rotated frame at her feet, so it flips with her orientation
  ctx.save();
  const _ga = ctx.globalAlpha;
  ctx.globalAlpha = _ga * 0.5;
  ctx.fillStyle = '#08040c';
  ctx.beginPath();
  ctx.ellipse(0, 20, 13, 4.6, 0, 0, 7);
  ctx.fill(); // drop shadow at her feet
  ctx.globalAlpha = _ga * 0.34;
  ctx.fillStyle = '#ff8ad6';
  ctx.beginPath();
  ctx.ellipse(0, 19, 11, 4, 0, 0, 7);
  ctx.fill(); // pink glow
  ctx.restore();
  const _grh = (p.outfit || selectedOutfit || 'og') === 'ourbit'; // Ourbit mascot has green hair
  const skin = '#7c4c31',
    skinSh = '#5f3823',
    hair = _grh ? '#4a9e3a' : '#181320',
    hairHi = _grh ? '#7cc255' : '#3a3048',
    ln = '#241019';
  // movement-driven animation: legs pump + arms swing when she flies fast
  const mspd = Math.hypot(p.vx || 0, p.vy || 0),
    amt = Math.min(1, mspd / 3.2),
    aph = tick * 0.4;
  const kickL = Math.sin(aph) * amt * 3.2,
    kickR = Math.sin(aph + Math.PI) * amt * 3.2,
    armSw = Math.sin(aph + 0.6) * amt * 2.2;
  // shared, consistent arm geometry for EVERY outfit (arms tuck at her sides, shoulders covered) — fixes wonky/mismatched limbs
  // BOTH arms are drawn here (behind the torso) so they poke out the back symmetrically — anchored up at the shoulder joints so they read as in-socket, hanging down to the hands
  const hold = p.hold; // {x,y}: raise her RIGHT arm + orb to this point (e.g. lifting a coffee) — drawn in front, after the head, so it stays visible
  let _armCol = skinSh,
    _armW = 3.8,
    _handCols = null;
  const backArm = (col, lw) => {
    _armCol = col;
    _armW = lw || 3.8;
    if (hold) return; // when holding, BOTH arms are drawn in front of the chest (below) {
      ctx.strokeStyle = col;
    }
    ctx.lineWidth = _armW;
    ctx.beginPath();
    ctx.moveTo(-7.5, -4);
    ctx.lineTo(-10.5 - armSw * 0.7, 7 + sBob);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(7.5, -4);
    ctx.lineTo(10.5 + armSw * 0.7, 7 - sBob);
    ctx.stroke();
  };
  const frontArm = (col, lw) => {}; // arms now both drawn by backArm (behind the body); kept as a no-op so every outfit's call site still works
  const hands = (g, c1, c2) => {
    _handCols = [g, c1, c2];
    if (hold) {
      return;
    }
    pOrb(-10.5 - armSw * 0.7, 7.6 + sBob, g, c1, c2);
    pOrb(10.5 + armSw * 0.7, 7.6 - sBob, g, c1, c2);
  };
  const outfit = p.outfit || selectedOutfit || 'og';
  const uwu = p.expr === 'uwu'; // cute ^w^ easter-egg face (closed :3 eyes)
  const smile = !p.expr || p.expr === 'smile'; // her updated open-eye model — now the DEFAULT face (in-game player, main menu, win screen, etc.)
  const annoyed = p.expr === 'annoyed'; // mildly annoyed: half-lidded droopy eyes + flat mouth (Twirl)
  const squee = p.expr === 'squee'; // >v< : squeezed chevron eyes + v mouth + big blush (victory pose, no blink)
  const giggle = p.expr === 'giggle'; // giggling: happy closed ^^ eyes + open laugh mouth (Coffee pose)
  const custom = uwu || smile || annoyed || squee || giggle; // any of her stylised preview expressions
  // ===== BODY (outfit-specific) =====
  if (outfit === 'maid') {
    const dress = '#201b2e',
      white = '#f4efe6',
      whiteSh = '#d6cdbf',
      ribbon = '#d23a44',
      sway2 = Math.sin(tick * 0.09) * 1.2;
    ctx.strokeStyle = white;
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 18);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 18);
    ctx.stroke();
    ctx.fillStyle = '#26222e';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 19, 3.6, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR, 19, 3.6, 2.3, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.moveTo(-8, 2);
    ctx.quadraticCurveTo(-13 + sway2, 9, -11 + sway2, 13);
    ctx.lineTo(11 + sway2, 13);
    ctx.quadraticCurveTo(13 + sway2, 9, 8, 2);
    ctx.closePath();
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = white;
    for (let i = -11; i < 11; i += 4) {
      ctx.beginPath();
      ctx.arc(i + 2 + sway2, 13, 2.2, 0, Math.PI);
      ctx.fill();
    }
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.moveTo(-5, 3);
    ctx.lineTo(5, 3);
    ctx.lineTo(4, 12);
    ctx.lineTo(-4, 12);
    ctx.closePath();
    ctx.fill();
    backArm(skinSh);
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.roundRect(-8, -6, 16, 10, 4);
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.roundRect(-4.5, -6, 9, 10, 2);
    ctx.fill();
    ctx.fillStyle = ribbon;
    ctx.beginPath();
    ctx.moveTo(0, -6);
    ctx.lineTo(-4, -3);
    ctx.lineTo(0, -1.5);
    ctx.lineTo(4, -3);
    ctx.closePath();
    ctx.fill();
    circle(0, -3.6, 1.4, ribbon);
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.ellipse(-8.5, -3.3, 4.3, 4.7, 0, 0, 7);
    ctx.ellipse(8.5, -3.3, 4.3, 4.7, 0, 0, 7);
    ctx.fill(); // puff sleeves cover the shoulders
    frontArm(skin);
    hands('#ff8ad6', '#ffd6f2', '#ff5bb0');
  } else if (outfit === 'bride') {
    // flowing white wedding gown with a pink sash + bouquet
    const gown = '#f7f2ec',
      gownSh = '#dcd2c6',
      sash = '#ffcfe0',
      lace = '#ffffff',
      sway2 = Math.sin(tick * 0.09) * 1.3;
    ctx.strokeStyle = '#efe7dc';
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 18);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 18);
    ctx.stroke();
    ctx.fillStyle = '#e8dccb';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 19, 3.4, 2.2, 0, 0, 7);
    ctx.ellipse(4 + kickR, 19, 3.4, 2.2, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = gown;
    ctx.beginPath();
    ctx.moveTo(-8, 1);
    ctx.quadraticCurveTo(-15 + sway2, 10, -13 + sway2, 16);
    ctx.quadraticCurveTo(0, 19, 13 + sway2, 16);
    ctx.quadraticCurveTo(15 + sway2, 10, 8, 1);
    ctx.closePath();
    ctx.strokeStyle = gownSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = lace;
    for (let i = -12; i < 12; i += 3.4) {
      ctx.beginPath();
      ctx.arc(i + 2 + sway2, 16, 1.8, 0, Math.PI);
      ctx.fill();
    }
    ctx.strokeStyle = gownSh;
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.moveTo(0, 3);
    ctx.lineTo(0, 16);
    ctx.stroke();
    backArm(gownSh);
    ctx.fillStyle = gown;
    ctx.beginPath();
    ctx.roundRect(-8, -6, 16, 9, 4);
    ctx.strokeStyle = gownSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = gownSh;
    ctx.beginPath();
    ctx.moveTo(-5, -6);
    ctx.quadraticCurveTo(0, -3.4, 5, -6);
    ctx.quadraticCurveTo(0, -4.6, -5, -6);
    ctx.fill();
    ctx.fillStyle = sash;
    ctx.fillRect(-8, 1.4, 16, 2.2);
    ctx.beginPath();
    ctx.moveTo(0, 2.5);
    ctx.lineTo(-4, 0.3);
    ctx.lineTo(-4, 4.9);
    ctx.closePath();
    ctx.moveTo(0, 2.5);
    ctx.lineTo(4, 0.3);
    ctx.lineTo(4, 4.9);
    ctx.closePath();
    ctx.fill();
    circle(0, 2.5, 1.3, '#ff9ec4');
    ctx.fillStyle = lace;
    ctx.beginPath();
    ctx.ellipse(-8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.ellipse(8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.fill();
    frontArm('#efe7dc');
    hands('#ffd6e6', '#ffffff', '#ffb0d0');
  } else if (outfit === 'angel') {
    // white-and-gold robe with feathered wings + gold cord
    const robe = '#fbf6e8',
      robeSh = '#e6dcc0',
      gold = '#ffd76a',
      sway2 = Math.sin(tick * 0.09) * 1.2,
      wf = Math.sin(tick * 0.13) * 1.4;
    ctx.fillStyle = 'rgba(255,255,255,0.94)';
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.moveTo(s * 5, -3);
      ctx.quadraticCurveTo(s * (16 + wf), -10, s * (19 + wf), 0);
      ctx.quadraticCurveTo(s * (16 + wf), 3, s * (13 + wf), 4);
      ctx.quadraticCurveTo(s * (16 + wf), 7, s * (11 + wf), 10);
      ctx.quadraticCurveTo(s * 9, 7, s * 5, 4);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = 'rgba(214,206,180,0.6)';
      ctx.lineWidth = 0.6;
      ctx.stroke();
    }
    ctx.strokeStyle = robe;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 18);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 18);
    ctx.stroke();
    ctx.fillStyle = '#e8dcc0';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 19, 3.3, 2.1, 0, 0, 7);
    ctx.ellipse(4 + kickR, 19, 3.3, 2.1, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.moveTo(-8, 1);
    ctx.quadraticCurveTo(-13 + sway2, 10, -11 + sway2, 15);
    ctx.quadraticCurveTo(0, 17, 11 + sway2, 15);
    ctx.quadraticCurveTo(13 + sway2, 10, 8, 1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-11 + sway2, 15);
    ctx.quadraticCurveTo(0, 17, 11 + sway2, 15);
    ctx.stroke();
    backArm(robeSh);
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.roundRect(-8, -6, 16, 9, 4);
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(-6, -5);
    ctx.lineTo(4, 3);
    ctx.stroke();
    ctx.fillStyle = gold;
    ctx.fillRect(-8, 2, 16, 1.6);
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.ellipse(-8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.ellipse(8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.fill();
    frontArm(robe);
    hands('#fff4c2', '#ffffff', '#ffe08a');
  } else if (outfit === 'golden') {
    // shimmering gold gown with a chest gem + crown (headwear)
    const gold = '#ffcf3a',
      goldHi = '#fff1a8',
      goldSh = '#c8901a',
      sway2 = Math.sin(tick * 0.09) * 1.2;
    ctx.strokeStyle = goldSh;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 18);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 18);
    ctx.stroke();
    ctx.fillStyle = '#a8760f';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 19, 3.4, 2.2, 0, 0, 7);
    ctx.ellipse(4 + kickR, 19, 3.4, 2.2, 0, 0, 7);
    ctx.fill();
    const gg = ctx.createLinearGradient(-12, 0, 12, 0);
    gg.addColorStop(0, goldSh);
    gg.addColorStop(0.5, goldHi);
    gg.addColorStop(1, gold);
    ctx.fillStyle = gg;
    ctx.beginPath();
    ctx.moveTo(-8, 2);
    ctx.quadraticCurveTo(-13 + sway2, 9, -11 + sway2, 14);
    ctx.lineTo(11 + sway2, 14);
    ctx.quadraticCurveTo(13 + sway2, 9, 8, 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = goldSh;
    ctx.lineWidth = 0.8;
    for (let i = -2; i <= 2; i++) {
      ctx.beginPath();
      ctx.moveTo(i * 2.4, 3);
      ctx.lineTo(i * 3.4 + sway2, 14);
      ctx.stroke();
    }
    backArm(goldSh);
    ctx.fillStyle = gg;
    ctx.beginPath();
    ctx.roundRect(-8, -6, 16, 10, 4);
    ctx.strokeStyle = goldSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fill();
    circle(0, -2, 1.9, '#fff1a8');
    circle(0, -2, 1, '#ff5b8d');
    ctx.fillStyle = goldHi;
    ctx.beginPath();
    ctx.ellipse(-8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.ellipse(8.5, -3.3, 4.2, 4.6, 0, 0, 7);
    ctx.fill();
    frontArm(gold);
    hands('#fff1a8', '#ffffff', '#ffcf3a');
  } else if (outfit === 'succubus') {
    // dark crimson bodice + jagged skirt, bat wings, a spade-tipped tail (horns in headwear)
    const dress = '#8a1030',
      dressSh = '#5a0a20',
      trim = '#2a1030',
      sway2 = Math.sin(tick * 0.09) * 1.3,
      wf = Math.sin(tick * 0.13) * 1.5;
    // bat wings BEHIND
    ctx.fillStyle = 'rgba(58,12,44,0.94)';
    ctx.strokeStyle = 'rgba(150,24,64,0.6)';
    ctx.lineWidth = 0.7;
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.moveTo(s * 5, -4);
      ctx.quadraticCurveTo(s * (15 + wf), -12, s * (20 + wf), -3);
      ctx.lineTo(s * (15.5 + wf), -0.5);
      ctx.lineTo(s * (19 + wf), 3.5);
      ctx.lineTo(s * (13.5 + wf), 3.5);
      ctx.lineTo(s * (16 + wf), 8);
      ctx.lineTo(s * (10.5 + wf), 6.5);
      ctx.quadraticCurveTo(s * 8, 3, s * 5, 1);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(s * 6, -2);
      ctx.lineTo(s * (17 + wf), -3);
      ctx.moveTo(s * 6, 0);
      ctx.lineTo(s * (14.5 + wf), 2);
      ctx.stroke();
    } // wing struts
    // spade-tipped tail
    const tw2 = Math.sin(tick * 0.11) * 2.2;
    ctx.strokeStyle = dress;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(5, 10);
    ctx.quadraticCurveTo(14 + tw2, 13, 12.5 + tw2, 20);
    ctx.stroke();
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.moveTo(12.5 + tw2, 17.5);
    ctx.lineTo(15.2 + tw2, 22);
    ctx.lineTo(12.5 + tw2, 21);
    ctx.lineTo(9.8 + tw2, 22);
    ctx.closePath();
    ctx.fill();
    // legs (thigh-high stockings)
    ctx.strokeStyle = trim;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 18);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 18);
    ctx.stroke();
    ctx.fillStyle = '#1a0a14';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 19, 3.4, 2.2, 0, 0, 7);
    ctx.ellipse(4 + kickR, 19, 3.4, 2.2, 0, 0, 7);
    ctx.fill();
    // jagged short skirt
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.moveTo(-8, 2);
    ctx.lineTo(-9 + sway2, 11);
    ctx.lineTo(-5.5, 8.5);
    ctx.lineTo(-2.5, 12);
    ctx.lineTo(0, 8.5);
    ctx.lineTo(2.5, 12);
    ctx.lineTo(5.5, 8.5);
    ctx.lineTo(9 + sway2, 11);
    ctx.lineTo(8, 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = dressSh;
    ctx.lineWidth = 0.8;
    ctx.stroke();
    backArm(dressSh);
    // strapless bodice + heart cutout
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.roundRect(-8, -5, 16, 8, 4);
    ctx.strokeStyle = dressSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = trim;
    ctx.beginPath();
    ctx.moveTo(0, -0.6);
    ctx.bezierCurveTo(-3, -3, -2.4, -5.4, 0, -3.6);
    ctx.bezierCurveTo(2.4, -5.4, 3, -3, 0, -0.6);
    ctx.fill();
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.ellipse(-8.5, -3, 3.4, 3.9, 0, 0, 7);
    ctx.ellipse(8.5, -3, 3.4, 3.9, 0, 0, 7);
    ctx.fill(); // shoulder bands
    frontArm(skin);
    hands('#ff3b6e', '#ffd6e6', '#c81e4a');
  } else if (outfit === 'nanosuit') {
    // Eva-style red plugsuit: red bodysuit, black accent stripes, orange chest plates, green core gem
    const red = '#d0202a',
      redD = '#9c1420',
      black = '#16121c',
      orange = '#ff7a2a',
      orangeL = '#ffb060',
      green = '#3ad84a',
      steel = '#cdd2da';
    // legs (red with black stripe) + boots
    ctx.strokeStyle = red;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.strokeStyle = black;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-4, 9.5);
    ctx.lineTo(-4 + kickL * 0.7, 14.5);
    ctx.moveTo(4, 9.5);
    ctx.lineTo(4 + kickR * 0.7, 14.5);
    ctx.stroke();
    ctx.fillStyle = black;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4, 2.6, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4, 2.6, 0, 0, 7);
    ctx.fill();
    // hips (red) with black seam
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = redD;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fill();
    ctx.strokeStyle = black;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-9, 6);
    ctx.lineTo(9, 6);
    ctx.moveTo(0, 2);
    ctx.lineTo(0, 10);
    ctx.stroke();
    backArm(redD, 4);
    // torso (red suit)
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.strokeStyle = redD;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fillStyle = red;
    ctx.fill();
    // black accent stripes down the torso
    ctx.strokeStyle = black;
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(-7.5, -9);
    ctx.lineTo(-8.5, 3);
    ctx.moveTo(7.5, -9);
    ctx.lineTo(8.5, 3);
    ctx.stroke();
    // orange chest plates (two) with highlights
    ctx.fillStyle = orange;
    ctx.beginPath();
    ctx.ellipse(-3.6, -5, 3.4, 3.9, 0.25, 0, 7);
    ctx.ellipse(3.6, -5, 3.4, 3.9, -0.25, 0, 7);
    ctx.fill();
    ctx.fillStyle = orangeL;
    ctx.beginPath();
    ctx.ellipse(-4.2, -6.2, 1.3, 1.6, 0.2, 0, 7);
    ctx.ellipse(3, -6.2, 1.3, 1.6, -0.2, 0, 7);
    ctx.fill();
    ctx.strokeStyle = redD;
    ctx.lineWidth = 0.9;
    ctx.beginPath();
    ctx.ellipse(-3.6, -5, 3.4, 3.9, 0.25, 0, 7);
    ctx.ellipse(3.6, -5, 3.4, 3.9, -0.25, 0, 7);
    ctx.stroke();
    // green core gem at sternum
    ctx.fillStyle = green;
    ctx.shadowColor = green;
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.arc(0, -1, 2.2, 0, 7);
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.fillStyle = '#d8ffd0';
    ctx.beginPath();
    ctx.arc(-0.6, -1.7, 0.85, 0, 7);
    ctx.fill();
    // black plugsuit collar with steel nubs
    ctx.fillStyle = black;
    ctx.beginPath();
    ctx.roundRect(-6, -11, 12, 3, 1.5);
    ctx.fill();
    ctx.fillStyle = steel;
    ctx.beginPath();
    ctx.arc(-4, -9.5, 0.8, 0, 7);
    ctx.arc(4, -9.5, 0.8, 0, 7);
    ctx.fill();
    // shoulder pads (dark red) cover the joints
    ctx.fillStyle = redD;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    frontArm(redD, 4);
    hands('#ff9a4a', '#ffe0b0', '#ff7a2a');
  } else if (outfit === 'badger') {
    // cute honey-badger onesie: charcoal fur, white dorsal stripe, honey-amber trim
    const furc = '#2a2620',
      furD = '#1a1712',
      white = '#ece7da',
      honey = '#f0b030',
      cream = '#f6efe0';
    // legs (charcoal) + cream paw feet with tiny claws
    ctx.strokeStyle = furc;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = cream;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.5, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.5, 0, 0, 7);
    ctx.fill();
    ctx.strokeStyle = '#c9b48a';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-6 + kickL, 19.4);
    ctx.lineTo(-6 + kickL, 20.4);
    ctx.moveTo(-2.4 + kickL, 19.4);
    ctx.lineTo(-2.4 + kickL, 20.4); // left foot claws
    ctx.moveTo(2.4 + kickR, 19.4);
    ctx.lineTo(2.4 + kickR, 20.4);
    ctx.moveTo(6 + kickR, 19.4);
    ctx.lineTo(6 + kickR, 20.4); // right foot claws (was missing)
    ctx.stroke();
    // hips
    ctx.fillStyle = furc;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fill();
    backArm(furD, 4);
    // torso (charcoal onesie)
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fillStyle = furc;
    ctx.fill();
    // white dorsal/front stripe (badger signature)
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.moveTo(-4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.lineTo(3, 3);
    ctx.lineTo(-3, 3);
    ctx.closePath();
    ctx.fill();
    // honey-amber collar + belly emblem
    ctx.fillStyle = honey;
    ctx.beginPath();
    ctx.roundRect(-6, -11, 12, 2.6, 1.3);
    ctx.fill();
    ctx.fillStyle = honey;
    ctx.beginPath();
    ctx.arc(0, -2, 1.9, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#fff2c8';
    ctx.beginPath();
    ctx.arc(-0.5, -2.6, 0.7, 0, 7);
    ctx.fill();
    // shoulder tufts (dark, white flecks) cover the joints
    ctx.fillStyle = furc;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.arc(-8.7, -5, 1.5, 0, 7);
    ctx.arc(8.7, -5, 1.5, 0, 7);
    ctx.fill();
    frontArm(furD, 4);
    hands('#f0b030', '#fff2c8', '#e0902a');
  } else if (outfit === 'honeybee') {
    // black-and-yellow striped bee suit with buzzing translucent wings + fuzzy shoulders
    const yel = '#ffd23a',
      blk = '#1a1712',
      wing = 'rgba(210,235,255,0.5)',
      wingE = 'rgba(180,215,255,0.8)';
    ctx.strokeStyle = blk;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke(); // black legs
    ctx.fillStyle = yel;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.6, 2.4, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.6, 2.4, 0, 0, 7);
    ctx.fill(); // yellow boots
    const wf = Math.sin(tick * 0.6) * 0.18;
    ctx.fillStyle = wing;
    ctx.strokeStyle = wingE;
    ctx.lineWidth = 0.8; // buzzing wings (behind)
    for (const s of [-1, 1]) {
      ctx.save();
      ctx.translate(s * 7, -7);
      ctx.rotate(s * (0.6 + wf));
      ctx.beginPath();
      ctx.ellipse(s * 5, 0, 6.5, 3.4, 0, 0, 7);
      ctx.fill();
      ctx.stroke();
      ctx.restore();
    }
    ctx.fillStyle = yel;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.fill(); // striped abdomen
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.clip();
    ctx.fillStyle = blk;
    ctx.fillRect(-9, 3.6, 18, 1.8);
    ctx.fillRect(-9, 7, 18, 1.8);
    ctx.restore();
    backArm(blk, 4);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = yel;
    ctx.fill(); // striped torso
    ctx.save();
    ctx.clip();
    ctx.fillStyle = blk;
    ctx.fillRect(-9, -8, 18, 2);
    ctx.fillRect(-9, -3.5, 18, 2);
    ctx.fillRect(-9, 1, 18, 2);
    ctx.restore();
    ctx.fillStyle = blk;
    ctx.beginPath();
    ctx.roundRect(-6, -11, 12, 2.6, 1.3);
    ctx.fill(); // black collar
    ctx.fillStyle = yel;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill(); // fuzzy shoulders
    ctx.fillStyle = blk;
    ctx.beginPath();
    ctx.arc(-8.7, -2.2, 1.4, 0, 7);
    ctx.arc(8.7, -2.2, 1.4, 0, 7);
    ctx.fill();
    frontArm(blk, 4);
    hands('#ffd23a', '#fff3b0', '#e0a91e');
  } else if (outfit === 'voidling') {
    // eldritch void robe: deep violet, glowing rune trim, a void-eye sigil, wispy tentacle hem
    const voidc = '#241238',
      voidD = '#160a24',
      glow = '#9d6bff',
      glowL = '#c9a0ff',
      rune = '#b98cff';
    ctx.strokeStyle = voidc;
    ctx.lineWidth = 6;
    ctx.lineCap = 'round'; // tentacle legs
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.quadraticCurveTo(-5 + kickL, 13, -4 + kickL, 17);
    ctx.moveTo(4, 7);
    ctx.quadraticCurveTo(5 + kickR, 13, 4 + kickR, 17);
    ctx.stroke();
    ctx.save();
    ctx.shadowColor = glow;
    ctx.shadowBlur = 6;
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(-4 + kickL, 18, 1.9, 0, 7);
    ctx.arc(4 + kickR, 18, 1.9, 0, 7);
    ctx.fill();
    ctx.restore(); // glowing tips
    ctx.strokeStyle = voidD;
    ctx.lineWidth = 2.6;
    for (let i = -2; i <= 2; i++) {
      const tx = i * 4,
        wob = Math.sin(tick * 0.12 + i) * 2;
      ctx.beginPath();
      ctx.moveTo(tx, 5);
      ctx.quadraticCurveTo(tx + wob, 11, tx + wob * 1.4, 16);
      ctx.stroke();
    } // wispy hem tentacles
    ctx.fillStyle = voidc;
    ctx.beginPath();
    ctx.moveTo(-8, 2);
    ctx.quadraticCurveTo(-12, 10, -9, 14);
    ctx.lineTo(9, 14);
    ctx.quadraticCurveTo(12, 10, 8, 2);
    ctx.closePath();
    ctx.fill(); // robe skirt
    backArm(voidD, 4);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = voidc;
    ctx.fill(); // torso robe
    ctx.save();
    ctx.shadowColor = glow;
    ctx.shadowBlur = 6;
    ctx.fillStyle = glowL;
    ctx.beginPath();
    ctx.ellipse(0, -3, 3, 2, 0, 0, 7);
    ctx.fill();
    ctx.restore(); // glowing void-eye sigil
    ctx.fillStyle = voidD;
    ctx.beginPath();
    ctx.ellipse(0, -3, 1.1, 1.6, 0, 0, 7);
    ctx.fill(); // slit pupil
    ctx.save();
    ctx.shadowColor = glow;
    ctx.shadowBlur = 4;
    ctx.strokeStyle = rune;
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(-6, -10.6);
    ctx.lineTo(6, -10.6);
    ctx.stroke();
    ctx.restore(); // glowing rune collar
    ctx.lineCap = 'butt';
    ctx.fillStyle = voidD;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill(); // shadow shoulder tufts
    frontArm(voidD, 4);
    hands('#9d6bff', '#e0d0ff', '#6a3aa0');
  } else if (outfit === 'banana') {
    // a plump banana costume — curved yellow peel body with ridge lines, ripe spots + a lighter belly
    const ban = '#ffcf3a',
      banD = '#e0a800',
      banL = '#ffe89a',
      spot = '#a5732a',
      tip = '#6a4a24';
    ctx.strokeStyle = ban;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke(); // legs
    ctx.fillStyle = banD;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.6, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.6, 2.3, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = ban;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.fill(); // hips
    backArm(banD, 4);
    ctx.fillStyle = ban;
    ctx.beginPath();
    ctx.moveTo(-8, -9);
    ctx.quadraticCurveTo(-12, 0, -8, 9);
    ctx.quadraticCurveTo(0, 12, 8, 9);
    ctx.quadraticCurveTo(12, 0, 8, -9);
    ctx.quadraticCurveTo(0, -11, -8, -9);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = banD;
    ctx.lineWidth = 1.3;
    ctx.stroke(); // banana body
    ctx.strokeStyle = banD;
    ctx.lineWidth = 0.9;
    for (const rx of [-4, 0, 4]) {
      ctx.beginPath();
      ctx.moveTo(rx, -8);
      ctx.quadraticCurveTo(rx * 1.3, 0, rx, 9);
      ctx.stroke();
    } // ridge lines
    ctx.fillStyle = banL;
    ctx.beginPath();
    ctx.ellipse(-2, 0, 2.2, 5, 0, 0, 7);
    ctx.fill(); // belly highlight
    ctx.fillStyle = spot;
    for (const sp of [
      [5, -4],
      [-6, 3],
      [3, 6],
    ]) {
      ctx.beginPath();
      ctx.arc(sp[0], sp[1], 0.9, 0, 7);
      ctx.fill();
    } // ripe spots
    ctx.fillStyle = tip;
    ctx.beginPath();
    ctx.ellipse(0, 10, 2, 1.6, 0, 0, 7);
    ctx.fill(); // brown tip
    ctx.fillStyle = ban;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill(); // shoulders
    frontArm(banD, 4);
    hands('#ffcf3a', '#ffe89a', '#e0a800');
  } else if (outfit === 'squirrely') {
    // squirrel onesie: warm brown fur, cream belly, a big bushy tail curling up behind (like Monke)
    const fur = '#a5642e',
      furD = '#7a441c',
      cream = '#e6cfa0',
      furL = '#c07d3e';
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.moveTo(8, 9);
    ctx.quadraticCurveTo(21, 7, 21, -6);
    ctx.quadraticCurveTo(21, -19, 7, -16);
    ctx.quadraticCurveTo(15, -8, 12, -1);
    ctx.quadraticCurveTo(15, 5, 8, 9);
    ctx.closePath();
    ctx.fill(); // big bushy tail
    ctx.strokeStyle = furL;
    ctx.lineWidth = 1;
    for (let i = 0; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(11, 6 - i * 4.5);
      ctx.quadraticCurveTo(18, 2 - i * 4.5, 16.5, -4 - i * 3.5);
      ctx.stroke();
    }
    ctx.strokeStyle = fur;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = cream;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.5, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.5, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    backArm(furD, 4);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = fur;
    ctx.fill();
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fillStyle = cream;
    ctx.beginPath();
    ctx.ellipse(0, -2, 4, 5.4, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    frontArm(furD, 4);
    hands('#c07d3e', '#e6cfa0', '#7a441c');
  } else if (outfit === 'honeypot') {
    // she's wearing a round honeypot — clean amber pot body with honey drips, little legs poking out
    const pot = '#e0972a',
      potD = '#b0731a',
      honey = '#ffcf5a';
    ctx.strokeStyle = '#7c4c31';
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4, 10);
    ctx.lineTo(-4 + kickL, 17);
    ctx.moveTo(4, 10);
    ctx.lineTo(4 + kickR, 17);
    ctx.stroke();
    ctx.fillStyle = '#5f3823';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18.5, 3.4, 2.2, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18.5, 3.4, 2.2, 0, 0, 7);
    ctx.fill();
    backArm('#7c4c31', 3.8);
    ctx.fillStyle = pot;
    ctx.beginPath();
    ctx.moveTo(-9, -6);
    ctx.quadraticCurveTo(-13, 0, -10, 9);
    ctx.quadraticCurveTo(0, 13, 10, 9);
    ctx.quadraticCurveTo(13, 0, 9, -6);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = potD;
    ctx.lineWidth = 1.4;
    ctx.stroke(); // pot body
    ctx.fillStyle = potD;
    ctx.beginPath();
    ctx.ellipse(0, -6, 9.5, 3, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = honey;
    ctx.beginPath();
    ctx.ellipse(0, -6, 7.5, 2.2, 0, 0, 7);
    ctx.fill(); // honey-filled rim
    ctx.fillStyle = honey;
    ctx.beginPath();
    ctx.moveTo(-8, -5);
    ctx.quadraticCurveTo(-9, 0, -7.5, 2);
    ctx.quadraticCurveTo(-6, 0, -6, -5);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.arc(-7.5, 2.4, 1.4, 0, 7);
    ctx.fill(); // drip L
    ctx.beginPath();
    ctx.moveTo(6, -5);
    ctx.quadraticCurveTo(5.5, 2, 7, 4);
    ctx.quadraticCurveTo(8.5, 2, 8, -5);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.arc(7, 4.4, 1.3, 0, 7);
    ctx.fill(); // drip R
    ctx.fillStyle = potD;
    ctx.beginPath();
    ctx.roundRect(-9, 1.5, 18, 1.8, 1);
    ctx.fill(); // simple decorative band
    ctx.strokeStyle = 'rgba(255,255,255,0.4)';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.arc(0, 1, 7, Math.PI * 0.72, Math.PI * 0.96);
    ctx.stroke(); // pot sheen
    frontArm('#7c4c31', 3.8);
    hands('#e0972a', '#ffcf5a', '#b0731a');
  } else if (outfit === 'empress') {
    // cosmic empress robe: deep indigo-violet studded with stars, gold trim, wide sleeves, a glowing planet
    const robe = '#241344',
      robeD = '#160a2c',
      robeL = '#3a2464',
      gold = '#e8c063',
      star = '#e8e0ff',
      skin = '#7c4c31';
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.moveTo(-8, 1);
    ctx.quadraticCurveTo(-15, 11, -12, 17);
    ctx.quadraticCurveTo(0, 20, 12, 17);
    ctx.quadraticCurveTo(15, 11, 8, 1);
    ctx.closePath();
    ctx.fill(); // robe skirt
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(-12, 17);
    ctx.quadraticCurveTo(0, 20, 12, 17);
    ctx.stroke();
    ctx.fillStyle = robeL;
    ctx.beginPath();
    ctx.moveTo(-7, -6);
    ctx.quadraticCurveTo(-16, -2, -15, 8);
    ctx.quadraticCurveTo(-10, 4, -6, 3);
    ctx.closePath();
    ctx.fill(); // wide sleeves
    ctx.beginPath();
    ctx.moveTo(7, -6);
    ctx.quadraticCurveTo(16, -2, 15, 8);
    ctx.quadraticCurveTo(10, 4, 6, 3);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-15, 8);
    ctx.quadraticCurveTo(-10, 4, -6, 3);
    ctx.moveTo(15, 8);
    ctx.quadraticCurveTo(10, 4, 6, 3);
    ctx.stroke();
    backArm(robeD, 4);
    ctx.beginPath();
    ctx.moveTo(-8, 3);
    ctx.lineTo(-8, -4);
    ctx.quadraticCurveTo(-8, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(8, -9, 8, -4);
    ctx.lineTo(8, 3);
    ctx.closePath();
    ctx.fillStyle = robe;
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.moveTo(-6, -10);
    ctx.lineTo(0, -2);
    ctx.lineTo(6, -10);
    ctx.lineTo(4.5, -10.5);
    ctx.lineTo(0, -4.5);
    ctx.lineTo(-4.5, -10.5);
    ctx.closePath();
    ctx.fill(); // gold lapels
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.moveTo(-3, -9.5);
    ctx.lineTo(0, -4);
    ctx.lineTo(3, -9.5);
    ctx.closePath();
    ctx.fill(); // decolletage
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.4, 0, 7);
    ctx.arc(8.5, -3.5, 4.4, 0, 7);
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(-8.5, -6, 1, 0, 7);
    ctx.arc(8.5, -6, 1, 0, 7);
    ctx.fill();
    frontArm(robeD, 4);
    hands('#3a2464', '#6a4a9a', '#160a2c');
    // rippling constellations across the robe — connect-the-dots stars that shimmer over time
    const CONS = [
      [
        [-6, 7],
        [-2, 10],
        [2, 8],
        [5, 12],
      ],
      [
        [-9, 13],
        [-5, 15],
        [-1, 16],
      ],
      [
        [3, 5],
        [6, 8],
        [8, 13],
      ],
      [
        [-5, -6],
        [-2, -2],
        [2, -4],
        [5, -6],
        [3, -9],
      ],
    ];
    for (let ci = 0; ci < CONS.length; ci++) {
      const pts = CONS[ci],
        sh = 0.5 + 0.5 * Math.sin(tick * 0.06 + ci * 1.3);
      ctx.strokeStyle = `rgba(180,200,255,${0.16 + 0.2 * sh})`;
      ctx.lineWidth = 0.5;
      ctx.beginPath();
      for (let i = 0; i < pts.length; i++) {
        i ? ctx.lineTo(pts[i][0], pts[i][1]) : ctx.moveTo(pts[i][0], pts[i][1]);
      }
      ctx.stroke();
      for (let i = 0; i < pts.length; i++) {
        const tw = 0.4 + 0.6 * Math.sin(tick * 0.09 + ci * 2 + i * 1.1);
        if (tw < 0.15) {
          continue;
        }
        ctx.fillStyle = `rgba(232,224,255,${0.45 + 0.5 * tw})`;
        ctx.beginPath();
        ctx.arc(pts[i][0], pts[i][1], 0.5 + 0.35 * tw, 0, 7);
        ctx.fill();
      }
    }
  } else if (outfit === 'viking') {
    // Viking Bobina: horned helmet, steel chestplate, fur collar, leather + eyepatch (callback to Vibe)
    const steel = '#b3bcc8',
      steelD = '#79828f',
      fur = '#6a4a2e',
      furL = '#9a7648',
      leather = '#4a3320',
      gold = '#ffd24a';
    // fur boots
    ctx.strokeStyle = fur;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.fillStyle = leather;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4, 2.6, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4, 2.6, 0, 0, 7);
    ctx.fill();
    // leather belt + gold buckle
    ctx.fillStyle = leather;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = '#2a1c10';
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.roundRect(-2.6, 4, 5.2, 4, 1);
    ctx.fill();
    // back arm
    backArm(skinSh);
    // steel chestplate
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fillStyle = steel;
    ctx.fill();
    ctx.fillStyle = steelD;
    ctx.beginPath();
    ctx.moveTo(3, -9);
    ctx.quadraticCurveTo(9, -6, 9, 3);
    ctx.lineTo(4, 3);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 0.9;
    ctx.beginPath();
    ctx.moveTo(0, -8);
    ctx.lineTo(0, 3);
    ctx.stroke();
    ctx.fillStyle = '#8a94a2';
    circle(-4, -7, 0.8, '#8a94a2');
    circle(4, -7, 0.8, '#8a94a2');
    // fur collar over the top of the chest
    ctx.fillStyle = fur;
    ctx.beginPath();
    for (let i = -7; i <= 7; i += 2.2) {
      ctx.arc(i, -9, 2.1, Math.PI, 0);
    }
    ctx.fill();
    ctx.fillStyle = furL;
    for (let i = -7; i <= 7; i += 2.2) {
      ctx.beginPath();
      ctx.arc(i, -9.4, 0.95, Math.PI, 0);
      ctx.fill();
    }
    // steel pauldrons cover the shoulders
    ctx.fillStyle = steel;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.4, 0, 7);
    ctx.arc(8.5, -3.5, 4.4, 0, 7);
    ctx.fill();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.4, 0, 7);
    ctx.arc(8.5, -3.5, 4.4, 0, 7);
    ctx.stroke();
    ctx.fillStyle = '#d8dee6';
    ctx.beginPath();
    ctx.arc(-9, -4.8, 1.5, 0, 7);
    ctx.arc(9, -4.8, 1.5, 0, 7);
    ctx.fill();
    // front arm + steel hands
    frontArm(skin);
    hands('#cdd6e0', '#ffffff', '#9aa4b2');
  } else if (outfit === 'ourbit') {
    // Ourbit mascot look: white ribbed tank top + dark shorts, bare arms, green "O"
    const white = '#f2efe8',
      whiteSh = '#d2cdc2',
      shorts = '#23252d',
      shortsSh = '#14161e',
      grn = '#4a9e3a',
      grnL = '#7cc255';
    // bare legs (skin) → dark ankle shoes
    ctx.strokeStyle = skin;
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 13);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 13);
    ctx.stroke();
    ctx.strokeStyle = skin;
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(-4 + kickL, 13);
    ctx.lineTo(-4 + kickL * 1.5, 18);
    ctx.moveTo(4 + kickR, 13);
    ctx.lineTo(4 + kickR * 1.5, 18);
    ctx.stroke();
    ctx.fillStyle = '#20222a';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL * 1.5, 19, 3.6, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR * 1.5, 19, 3.6, 2.3, 0, 0, 7);
    ctx.fill();
    // dark shorts
    ctx.fillStyle = shorts;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = shortsSh;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    ctx.strokeStyle = shortsSh;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(0, 2.6);
    ctx.lineTo(0, 9);
    ctx.stroke();
    backArm(skinSh);
    // bare skin shoulders (sleeveless), then the tank on top
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.arc(-7.6, -2.6, 3.1, 0, 7);
    ctx.arc(7.6, -2.6, 3.1, 0, 7);
    ctx.fill();
    // white ribbed tank top (narrower than the torso)
    ctx.beginPath();
    ctx.moveTo(-7.5, 3);
    ctx.lineTo(-7.5, -3.5);
    ctx.quadraticCurveTo(-7, -9.5, -3.2, -9.6);
    ctx.quadraticCurveTo(0, -6.8, 3.2, -9.6);
    ctx.quadraticCurveTo(7, -9.5, 7.5, -3.5);
    ctx.lineTo(7.5, 3);
    ctx.closePath();
    ctx.fillStyle = white;
    ctx.fill();
    ctx.strokeStyle = whiteSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.strokeStyle = whiteSh;
    ctx.lineWidth = 0.6;
    ctx.beginPath();
    for (let vx = -5; vx <= 5; vx += 2.5) {
      ctx.moveTo(vx, -8.5);
      ctx.lineTo(vx, 2.5);
    }
    ctx.stroke();
    // thin straps
    ctx.strokeStyle = white;
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.moveTo(-4.4, -10);
    ctx.lineTo(-3, -4);
    ctx.moveTo(4.4, -10);
    ctx.lineTo(3, -4);
    ctx.stroke();
    // green Ourbit "O"
    ctx.strokeStyle = grn;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.arc(0, -3.5, 2.3, 0, 7);
    ctx.stroke();
    ctx.strokeStyle = grnL;
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.arc(0, -3.5, 2.3, 0, 7);
    ctx.stroke();
    frontArm(skin);
    hands('#7cc255', '#e0ffc8', '#4a9e3a');
  } else if (outfit === 'monke') {
    // Monke: brown monkey onesie, tan belly, banana-yellow paws + tail
    const fur = '#7a4a24',
      furD = '#573118',
      belly = '#c9a56a',
      tan = '#d8b47a';
    ctx.strokeStyle = fur;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = tan;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.5, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.5, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    // curly tail
    ctx.strokeStyle = fur;
    ctx.lineWidth = 2.4;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(8, 7);
    ctx.quadraticCurveTo(15, 8, 15, 3);
    ctx.quadraticCurveTo(15, -0.5, 11.5, 0.5);
    ctx.stroke();
    backArm(furD, 4);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = fur;
    ctx.fill();
    ctx.strokeStyle = furD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fillStyle = belly;
    ctx.beginPath();
    ctx.ellipse(0, -2, 4.2, 5.2, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = fur;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    frontArm(furD, 4);
    hands('#ffd23a', '#fff2a8', '#e0a800');
  } else if (outfit === 'pickle') {
    // Pickle: bumpy green pickle onesie
    const pk = '#6aa832',
      pkD = '#4a7e22',
      pkL = '#8ac850',
      bump = '#5a9228';
    ctx.strokeStyle = pk;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = pkD;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.5, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.5, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = pk;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = pkD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    backArm(pkD, 4);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9.5, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9.5, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = pk;
    ctx.fill();
    ctx.strokeStyle = pkD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fillStyle = bump;
    for (const bp of [
      [-4, -7],
      [3, -8],
      [-2, -3],
      [5, -3],
      [0, 1],
      [-6, -1],
      [4, 2],
    ]) {
      ctx.beginPath();
      ctx.arc(bp[0], bp[1], 0.9, 0, 7);
      ctx.fill();
    }
    ctx.fillStyle = pkL;
    for (const bp of [
      [-4.4, -7.4],
      [2.6, -8.4],
      [-2.4, -3.4],
    ]) {
      ctx.beginPath();
      ctx.arc(bp[0], bp[1], 0.4, 0, 7);
      ctx.fill();
    }
    ctx.fillStyle = pk;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    ctx.fillStyle = bump;
    circle(-8.7, -4.5, 0.8, bump);
    circle(8.7, -4.5, 0.8, bump);
    frontArm(pkD, 4);
    hands('#8ac850', '#e0ffb0', '#4a7e22');
  } else if (outfit === 'bullbina') {
    // Bullbina: emerald bull-market bodysuit, cream chest blaze, golden cowbell
    const grn = '#1fae5a',
      grnD = '#127a3e',
      grnL = '#3fd97a',
      cream = '#f0ead6',
      gold = '#ffd24a',
      hoof = '#241c14';
    // legs → cloven hooves
    ctx.strokeStyle = grn;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.fillStyle = hoof;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.6, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.6, 0, 0, 7);
    ctx.fill();
    ctx.strokeStyle = '#0e0c08';
    ctx.lineWidth = 0.9;
    ctx.beginPath();
    ctx.moveTo(-4 + kickL, 17);
    ctx.lineTo(-4 + kickL, 19.6);
    ctx.moveTo(4 + kickR, 17);
    ctx.lineTo(4 + kickR, 19.6);
    ctx.stroke();
    // hips + gold belt
    ctx.fillStyle = grn;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = grnD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.roundRect(-9, 4.2, 18, 2, 1);
    ctx.fill();
    backArm(grnD, 4);
    // emerald torso
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = grn;
    ctx.fill();
    ctx.strokeStyle = grnD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    // cream chest blaze (bull marking)
    ctx.fillStyle = cream;
    ctx.beginPath();
    ctx.moveTo(0, -10.5);
    ctx.quadraticCurveTo(-4.5, -4, -2.4, 3);
    ctx.lineTo(2.4, 3);
    ctx.quadraticCurveTo(4.5, -4, 0, -10.5);
    ctx.closePath();
    ctx.fill();
    // shoulders
    ctx.fillStyle = grn;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    ctx.fillStyle = grnL;
    ctx.beginPath();
    ctx.arc(-8.7, -5, 1.4, 0, 7);
    ctx.arc(8.7, -5, 1.4, 0, 7);
    ctx.fill();
    // golden cowbell at the collar
    ctx.fillStyle = gold;
    ctx.strokeStyle = grnD;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-2, -9);
    ctx.lineTo(2, -9);
    ctx.lineTo(2.5, -5.6);
    ctx.quadraticCurveTo(0, -4.6, -2.5, -5.6);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = '#8a6410';
    circle(0, -5.4, 0.7, '#8a6410');
    frontArm(grnD, 4);
    hands('#3fd97a', '#d8ffe0', '#127a3e');
  } else if (outfit === 'emblem') {
    // Emblem Vault: regal gold vault-keeper coat with a glowing ◈ gem
    const gold = '#ffd27a',
      goldD = '#c9992e',
      goldDD = '#8a6a1e',
      dark = '#3a2e14',
      gem = '#ffe08a';
    ctx.strokeStyle = dark;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = goldD;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4, 2.6, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4, 2.6, 0, 0, 7);
    ctx.fill();
    // gold belt + buckle
    ctx.fillStyle = dark;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = goldDD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.roundRect(-9, 5, 18, 1.8, 1);
    ctx.fill();
    ctx.fillStyle = goldD;
    ctx.beginPath();
    ctx.roundRect(-2.4, 4, 4.8, 4, 1);
    ctx.fill();
    backArm(goldDD, 4);
    // gold coat torso
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = gold;
    ctx.fill();
    ctx.strokeStyle = goldD;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    // dark lapel V
    ctx.fillStyle = dark;
    ctx.beginPath();
    ctx.moveTo(-4.6, -10.5);
    ctx.lineTo(4.6, -10.5);
    ctx.lineTo(0, -1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = goldDD;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-4.6, -10.5);
    ctx.lineTo(0, -1);
    ctx.lineTo(4.6, -10.5);
    ctx.stroke();
    // glowing ◈ emblem gem
    ctx.save();
    ctx.shadowColor = gem;
    ctx.shadowBlur = 9;
    ctx.fillStyle = gem;
    ctx.beginPath();
    ctx.moveTo(0, -6.5);
    ctx.lineTo(2.4, -4);
    ctx.lineTo(0, -1.5);
    ctx.lineTo(-2.4, -4);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
    ctx.fillStyle = '#fff8e0';
    ctx.beginPath();
    ctx.moveTo(0, -5.6);
    ctx.lineTo(0.9, -4);
    ctx.lineTo(0, -2.6);
    ctx.lineTo(-0.9, -4);
    ctx.closePath();
    ctx.fill();
    // gold epaulette shoulders
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    ctx.strokeStyle = goldD;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.stroke();
    ctx.fillStyle = goldDD;
    circle(-8.5, -2.4, 1, goldDD);
    circle(8.5, -2.4, 1, goldDD);
    frontArm(goldDD, 4);
    hands('#ffd27a', '#fff4c8', '#c9992e');
  } else if (outfit === 'labrat') {
    // Labrat: white labcoat over a teal shirt, dark slacks, blue gloves (glasses in headwear)
    const coat = '#eef1f4',
      coatSh = '#c8cfd6',
      shirt = '#2a8a9a',
      slack = '#2e3440';
    ctx.strokeStyle = slack;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = '#1a1c22';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.8, 2.4, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.8, 2.4, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = slack;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = '#1a1c22';
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    backArm(coatSh);
    // teal shirt base, then open white labcoat panels over it
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = shirt;
    ctx.fill();
    ctx.fillStyle = coat;
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(-1.4, -10.5);
    ctx.lineTo(-3, 3);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = coatSh;
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(9, 3);
    ctx.lineTo(9, -4);
    ctx.quadraticCurveTo(9, -9, 4, -10.5);
    ctx.lineTo(1.4, -10.5);
    ctx.lineTo(3, 3);
    ctx.closePath();
    ctx.fillStyle = coat;
    ctx.fill();
    ctx.strokeStyle = coatSh;
    ctx.lineWidth = 1;
    ctx.stroke();
    // chest pocket + red pen
    ctx.strokeStyle = coatSh;
    ctx.lineWidth = 0.7;
    ctx.strokeRect(-7.4, -6, 3, 3);
    ctx.strokeStyle = '#ff5b6e';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-5.9, -6.6);
    ctx.lineTo(-5.9, -4);
    ctx.stroke();
    // white coat shoulders
    ctx.fillStyle = coat;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.fill();
    ctx.strokeStyle = coatSh;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(-8.5, -3.5, 4.2, 0, 7);
    ctx.arc(8.5, -3.5, 4.2, 0, 7);
    ctx.stroke();
    frontArm(coatSh);
    hands('#8fd0ff', '#e0f4ff', '#5aa0d0');
  } else if (outfit === 'cabal') {
    // Cabal: the LA Cabal's dark ceremonial robe — black cloak, crimson lining, gold sigil, ember-glow hands
    const robe = '#141018',
      robeSh = '#0b0810',
      lining = '#8a1224',
      gold = '#d8a12e',
      glow = Math.sin(tick * 0.14) * 0.5 + 0.5;
    // long robe skirt (flared, with crimson inner)
    ctx.fillStyle = lining;
    ctx.beginPath();
    ctx.moveTo(-7, 1);
    ctx.lineTo(-12, 15);
    ctx.lineTo(12, 15);
    ctx.lineTo(7, 1);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.moveTo(-8, 0);
    ctx.lineTo(-12.5, 15);
    ctx.lineTo(-3, 15);
    ctx.lineTo(-2.5, 1);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(8, 0);
    ctx.lineTo(12.5, 15);
    ctx.lineTo(3, 15);
    ctx.lineTo(2.5, 1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(0, 1);
    ctx.lineTo(0, 15);
    ctx.stroke(); // gold center seam
    ctx.fillStyle = '#1a1420';
    ctx.beginPath();
    ctx.ellipse(-6, 16, 3.4, 2, 0, 0, 7);
    ctx.ellipse(6, 16, 3.4, 2, 0, 0, 7);
    ctx.fill();
    backArm(robeSh);
    // torso robe + crimson stole
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = robe;
    ctx.fill();
    ctx.strokeStyle = robeSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fillStyle = lining;
    ctx.beginPath();
    ctx.moveTo(-3.4, -9.5);
    ctx.lineTo(-1.6, 4);
    ctx.lineTo(0, -1);
    ctx.lineTo(1.6, 4);
    ctx.lineTo(3.4, -9.5);
    ctx.closePath();
    ctx.fill(); // V-stole
    // glowing gold sigil on the chest (all-seeing triangle)
    ctx.save();
    ctx.shadowColor = '#ffcf5a';
    ctx.shadowBlur = 6 * glow + 2;
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, -6.5);
    ctx.lineTo(2.4, -2.2);
    ctx.lineTo(-2.4, -2.2);
    ctx.closePath();
    ctx.stroke();
    ctx.fillStyle = 'rgba(255,60,60,' + (0.5 + 0.4 * glow) + ')';
    ctx.beginPath();
    ctx.arc(0, -3.7, 0.7, 0, 7);
    ctx.fill();
    ctx.restore();
    // hood shoulders
    ctx.fillStyle = robe;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.4, 4.9, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.4, 4.9, -0.15, 0, 7);
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.arc(-8.7, -4.6, 4.4, 3.7, 5.0);
    ctx.arc(8.7, -4.6, 4.4, 4.4, 5.7);
    ctx.stroke();
    frontArm(robe);
    hands('#ff5a2a', '#ffd08a', '#c81e10'); // ember-glow hands
  } else if (outfit === 'neko') {
    // Neko: soft pink hoodie-dress, black thigh-highs, a bell collar, paw-mitten hands, and a swishing tail
    const dress = '#f7a8c8',
      dressSh = '#d97ba6',
      trim = '#fff6fb',
      sock = '#241f2c',
      shoe = '#4a3f52',
      tsw = Math.sin(tick * 0.11) * 3.2 + (p.vx || 0) * 0.8;
    // tail (behind the body)
    ctx.strokeStyle = dress;
    ctx.lineWidth = 3.4;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(6, 9);
    ctx.quadraticCurveTo(13, 11, 14.5 + tsw, 3.5);
    ctx.stroke();
    ctx.strokeStyle = sock;
    ctx.lineWidth = 3.4;
    ctx.beginPath();
    ctx.moveTo(13.5 + tsw * 0.9, 5);
    ctx.lineTo(15 + tsw, 2.5);
    ctx.stroke();
    // legs w/ black thigh-highs
    ctx.strokeStyle = sock;
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 14);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 14);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(-4 + kickL, 14);
    ctx.lineTo(-4 + kickL * 1.6, 18);
    ctx.moveTo(4 + kickR, 14);
    ctx.lineTo(4 + kickR * 1.6, 18);
    ctx.stroke();
    ctx.fillStyle = shoe;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL * 1.6, 19, 3.6, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR * 1.6, 19, 3.6, 2.3, 0, 0, 7);
    ctx.fill();
    backArm(dressSh);
    // flared hoodie-dress skirt
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.moveTo(-8, 1);
    ctx.lineTo(-11, 10);
    ctx.lineTo(11, 10);
    ctx.lineTo(8, 1);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = trim;
    ctx.beginPath();
    ctx.roundRect(-11, 8.6, 22, 1.8, 1);
    ctx.fill();
    // torso
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = dress;
    ctx.fill();
    ctx.strokeStyle = dressSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fillStyle = dressSh;
    ctx.beginPath();
    ctx.moveTo(3, -9);
    ctx.quadraticCurveTo(9, -6, 9, 3);
    ctx.lineTo(4, 3);
    ctx.closePath();
    ctx.fill(); // side shade
    // hoodie sleeves/shoulders
    ctx.fillStyle = dress;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill();
    ctx.strokeStyle = dressSh;
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.stroke();
    // bell collar
    ctx.strokeStyle = '#241f2c';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-4.6, -9.2);
    ctx.quadraticCurveTo(0, -6.6, 4.6, -9.2);
    ctx.stroke();
    ctx.fillStyle = '#ffd23a';
    ctx.beginPath();
    ctx.arc(0, -6.8, 1.6, 0, 7);
    ctx.fill();
    ctx.strokeStyle = '#c99a1e';
    ctx.lineWidth = 0.5;
    ctx.beginPath();
    ctx.moveTo(-1.2, -6.8);
    ctx.lineTo(1.2, -6.8);
    ctx.stroke();
    ctx.fillStyle = '#c99a1e';
    ctx.beginPath();
    ctx.arc(0, -5.7, 0.4, 0, 7);
    ctx.fill();
    frontArm(dress);
    hands('#ffb3d9', '#fff0f6', '#ff8ac0'); // soft pink paw-mittens
  } else if (outfit === 'kigurumi') {
    // Bear kigurumi: cozy footed onesie, cream belly patch, mitten paws (bear-face hood in headwear)
    const suit = '#b07a45',
      suitSh = '#8a5c30',
      belly = '#f0dcc0';
    ctx.strokeStyle = suit;
    ctx.lineWidth = 6.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4.2, 3, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4.2, 3, 0, 0, 7);
    ctx.fill(); // paw feet
    ctx.fillStyle = belly;
    ctx.beginPath();
    ctx.arc(-4 + kickL, 18.6, 1.4, 0, 7);
    ctx.arc(4 + kickR, 18.6, 1.4, 0, 7);
    ctx.fill(); // foot pads
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 9, 4);
    ctx.fill();
    backArm(suitSh);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = suit;
    ctx.fill();
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fillStyle = belly;
    ctx.beginPath();
    ctx.ellipse(0, -1.5, 4.6, 5.8, 0, 0, 7);
    ctx.fill(); // belly patch
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.moveTo(0, -9);
    ctx.lineTo(0, -3.5);
    ctx.stroke(); // zipper
    ctx.fillStyle = '#d8b47a';
    ctx.beginPath();
    ctx.arc(0, -9, 0.9, 0, 7);
    ctx.fill(); // zipper pull
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill();
    frontArm(suit);
    hands('#f0dcc0', '#fff4e6', '#c8a878'); // mitten paws
  } else if (outfit === 'cheese') {
    // Mouse kigurumi: grey footed onesie, cheese-wedge belly (with holes), pink paw pads, a long curly tail
    const suit = '#b8b8c6',
      suitSh = '#8f8f9e',
      belly = '#f2d066',
      pad = '#ff9ec4';
    ctx.strokeStyle = pad;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(6, 8);
    ctx.quadraticCurveTo(15, 10, 14, 4);
    ctx.quadraticCurveTo(13, 0, 17, 0.4);
    ctx.stroke(); // curly tail (behind)
    ctx.strokeStyle = suit;
    ctx.lineWidth = 6.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4.2, 3, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4.2, 3, 0, 0, 7);
    ctx.fill(); // paw feet
    ctx.fillStyle = pad;
    ctx.beginPath();
    ctx.arc(-4 + kickL, 18.6, 1.4, 0, 7);
    ctx.arc(4 + kickR, 18.6, 1.4, 0, 7);
    ctx.fill(); // foot pads
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 9, 4);
    ctx.fill();
    backArm(suitSh);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = suit;
    ctx.fill();
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fillStyle = belly;
    ctx.beginPath();
    ctx.ellipse(0, -1.5, 4.6, 5.8, 0, 0, 7);
    ctx.fill(); // cheese belly patch
    ctx.fillStyle = '#d8b23a';
    ctx.beginPath();
    ctx.arc(-1.6, -3, 0.9, 0, 7);
    ctx.arc(1.8, -0.2, 1.1, 0, 7);
    ctx.arc(-0.6, 2.4, 0.7, 0, 7);
    ctx.fill(); // cheese holes
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.moveTo(0, -9);
    ctx.lineTo(0, -3.5);
    ctx.stroke(); // zipper
    ctx.fillStyle = '#e8e8ee';
    ctx.beginPath();
    ctx.arc(0, -9, 0.9, 0, 7);
    ctx.fill(); // zipper pull
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill();
    frontArm(suit);
    hands('#cfcfda', '#f0f0f6', '#a8a8b6'); // mitten paws (grey)
  } else if (outfit === 'business') {
    // Business: navy blazer over a white shirt, crimson tie, grey slacks, dress shoes
    const suit = '#28324e',
      suitSh = '#1b2338',
      shirt = '#f2f4f8',
      tie = '#c02a3a',
      slack = '#39414f',
      shoe = '#171310';
    ctx.strokeStyle = slack;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = shoe;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 4, 2.4, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 4, 2.4, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = slack;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.fill();
    backArm(suitSh);
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = shirt;
    ctx.fill(); // white shirt base
    // navy blazer panels
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(-1, -10);
    ctx.lineTo(-3.4, 3);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(9, 3);
    ctx.lineTo(9, -4);
    ctx.quadraticCurveTo(9, -9, 4, -10.5);
    ctx.lineTo(1, -10);
    ctx.lineTo(3.4, 3);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = suitSh;
    ctx.beginPath();
    ctx.moveTo(-1, -10);
    ctx.lineTo(-3.4, -5.5);
    ctx.lineTo(-3.4, -3);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(1, -10);
    ctx.lineTo(3.4, -5.5);
    ctx.lineTo(3.4, -3);
    ctx.closePath();
    ctx.fill(); // lapels
    // crimson tie
    ctx.fillStyle = tie;
    ctx.beginPath();
    ctx.moveTo(-1.1, -8.5);
    ctx.lineTo(1.1, -8.5);
    ctx.lineTo(0.7, -6.8);
    ctx.lineTo(-0.7, -6.8);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(-0.9, -6.8);
    ctx.lineTo(0.9, -6.8);
    ctx.lineTo(1.7, 0.5);
    ctx.lineTo(0, 2.5);
    ctx.lineTo(-1.7, 0.5);
    ctx.closePath();
    ctx.fillStyle = tie;
    ctx.fill();
    ctx.strokeStyle = '#8a1c28';
    ctx.lineWidth = 0.5;
    ctx.stroke();
    ctx.fillStyle = suit;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill(); // blazer shoulders
    ctx.strokeStyle = suitSh;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.stroke();
    // pocket square
    ctx.fillStyle = '#f2f4f8';
    ctx.beginPath();
    ctx.moveTo(-7.4, -5.6);
    ctx.lineTo(-5.4, -5.6);
    ctx.lineTo(-6.4, -4.3);
    ctx.closePath();
    ctx.fill();
    frontArm(suit);
    hands(skin, '#8a5c38', skinSh); // bare hands
  } else if (outfit === 'jester') {
    // Jester (Pomni-style harlequin): blue/red split motley, white ruffle collar, diamond accents, curly bell shoes
    const blue = '#3f52c4',
      red = '#d8354a',
      white = '#f4f1e8',
      blueSh = '#2c3a95',
      redSh = '#a82235',
      gold = '#ffd23a';
    // tights (blue left, red right) + curly bell shoes
    ctx.strokeStyle = blue;
    ctx.lineWidth = 5.2;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 15);
    ctx.stroke();
    ctx.strokeStyle = red;
    ctx.lineWidth = 5.2;
    ctx.beginPath();
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 15);
    ctx.stroke();
    ctx.strokeStyle = red;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-4 + kickL, 15);
    ctx.quadraticCurveTo(-7.5 + kickL, 18.5, -5.4 + kickL, 19);
    ctx.stroke(); // curly toe
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(-5.6 + kickL, 19.4, 1.3, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#c99a1e';
    ctx.beginPath();
    ctx.arc(-5.6 + kickL, 19.4, 0.5, 0, 7);
    ctx.fill();
    ctx.strokeStyle = blue;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(4 + kickR, 15);
    ctx.quadraticCurveTo(7.5 + kickR, 18.5, 5.4 + kickR, 19);
    ctx.stroke();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(5.6 + kickR, 19.4, 1.3, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#c99a1e';
    ctx.beginPath();
    ctx.arc(5.6 + kickR, 19.4, 0.5, 0, 7);
    ctx.fill();
    // motley hips (split)
    ctx.fillStyle = blue;
    ctx.beginPath();
    ctx.moveTo(-9, 2);
    ctx.lineTo(0, 2);
    ctx.lineTo(0, 11);
    ctx.lineTo(-9, 11);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.moveTo(0, 2);
    ctx.lineTo(9, 2);
    ctx.lineTo(9, 11);
    ctx.lineTo(0, 11);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = white;
    ctx.beginPath();
    ctx.moveTo(-6, 4.5);
    ctx.lineTo(-4.5, 6.5);
    ctx.lineTo(-6, 8.5);
    ctx.lineTo(-7.5, 6.5);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(6, 4.5);
    ctx.lineTo(7.5, 6.5);
    ctx.lineTo(6, 8.5);
    ctx.lineTo(4.5, 6.5);
    ctx.closePath();
    ctx.fill(); // hip diamonds
    backArm(blueSh);
    // torso split blue(left)/red(right) with opposite-colour diamonds
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.clip();
    ctx.fillStyle = blue;
    ctx.fillRect(-9, -11, 9, 15);
    ctx.fillStyle = red;
    ctx.fillRect(0, -11, 9, 15);
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.moveTo(-5, -7);
    ctx.lineTo(-3.4, -4.5);
    ctx.lineTo(-5, -2);
    ctx.lineTo(-6.6, -4.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = blue;
    ctx.beginPath();
    ctx.moveTo(5, -6);
    ctx.lineTo(6.6, -3.5);
    ctx.lineTo(5, -1);
    ctx.lineTo(3.4, -3.5);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
    ctx.strokeStyle = 'rgba(0,0,0,0.25)';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(0, -10.5);
    ctx.lineTo(0, 3);
    ctx.stroke(); // centre seam
    ctx.fillStyle = blue;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.fill();
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill();
    // white ruffle collar
    ctx.fillStyle = white;
    for (let i = -5; i <= 5; i += 2) {
      ctx.beginPath();
      ctx.arc(i, -9.2, 1.9, 0, 7);
      ctx.fill();
    }
    ctx.fillStyle = '#d8d2c4';
    for (let i = -5; i <= 5; i += 2) {
      ctx.beginPath();
      ctx.arc(i, -9.2, 0.7, 0, 7);
      ctx.fill();
    }
    frontArm(red);
    hands(white, '#ffffff', '#cfc8ba'); // white jester gloves
  } else if (outfit === 'samurai') {
    // Samurai: lacquered dō (cuirass) with red lacing, big shoulder guards (sode), tasset skirt, hakama + tabi
    const armor = '#2b2f3c',
      armorSh = '#1a1d26',
      lace = '#c33346',
      gold = '#d8a72e',
      hakama = '#3a2030';
    ctx.strokeStyle = hakama;
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 16);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 16);
    ctx.stroke();
    ctx.fillStyle = '#efe6d4';
    ctx.beginPath();
    ctx.ellipse(-4 + kickL, 18, 3.7, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR, 18, 3.7, 2.3, 0, 0, 7);
    ctx.fill(); // tabi
    // kusazuri (tasset skirt plates)
    ctx.fillStyle = armor;
    ctx.beginPath();
    ctx.roundRect(-9.5, 2, 19, 9, 2);
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 0.7;
    for (let i = -6; i <= 6; i += 4) {
      ctx.beginPath();
      ctx.moveTo(i, 2);
      ctx.lineTo(i, 11);
      ctx.stroke();
    }
    ctx.strokeStyle = lace;
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.moveTo(-9.5, 5);
    ctx.lineTo(9.5, 5);
    ctx.stroke();
    backArm(armorSh);
    // dō (cuirass) with odoshi lacing rows + gold boss
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.lineTo(4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = armor;
    ctx.fill();
    ctx.strokeStyle = armorSh;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.strokeStyle = lace;
    ctx.lineWidth = 1.3;
    for (let ly = -7; ly <= 1; ly += 3) {
      ctx.beginPath();
      ctx.moveTo(-7, ly);
      ctx.lineTo(7, ly);
      ctx.stroke();
    }
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(0, -3.5, 1.6, 0, 7);
    ctx.fill();
    ctx.strokeStyle = lace;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(0, -2);
    ctx.lineTo(0, 4);
    ctx.stroke(); // agemaki cord
    // sode (large shoulder guards) with gold trim
    ctx.fillStyle = armor;
    ctx.beginPath();
    ctx.roundRect(-13, -6.5, 5.6, 9.5, 2);
    ctx.roundRect(7.4, -6.5, 5.6, 9.5, 2);
    ctx.fill();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 0.8;
    ctx.strokeRect(-13, -6.5, 5.6, 9.5);
    ctx.strokeRect(7.4, -6.5, 5.6, 9.5);
    ctx.strokeStyle = lace;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-13, -2);
    ctx.lineTo(-7.4, -2);
    ctx.moveTo(7.4, -2);
    ctx.lineTo(13, -2);
    ctx.stroke();
    frontArm(armorSh);
    hands('#c9b088', '#e8d4a8', '#8a6a3a'); // kote (armored gloves)
  } else {
    const tee = '#d02f3a',
      teeSh = '#9c1f27',
      denim = '#3f6390',
      denimSh = '#2c476b',
      sock = '#f2efe6',
      shoe = '#26222e';
    ctx.strokeStyle = skin;
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4, 7);
    ctx.lineTo(-4 + kickL, 13);
    ctx.moveTo(4, 7);
    ctx.lineTo(4 + kickR, 13);
    ctx.stroke();
    ctx.strokeStyle = sock;
    ctx.lineWidth = 5.5;
    ctx.beginPath();
    ctx.moveTo(-4 + kickL, 13);
    ctx.lineTo(-4 + kickL * 1.6, 18);
    ctx.moveTo(4 + kickR, 13);
    ctx.lineTo(4 + kickR * 1.6, 18);
    ctx.stroke();
    ctx.fillStyle = shoe;
    ctx.beginPath();
    ctx.ellipse(-4 + kickL * 1.6, 19, 3.6, 2.3, 0, 0, 7);
    ctx.ellipse(4 + kickR * 1.6, 19, 3.6, 2.3, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = denim;
    ctx.beginPath();
    ctx.roundRect(-9, 2, 18, 8, 3);
    ctx.strokeStyle = denimSh;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.fill();
    ctx.fillStyle = denimSh;
    ctx.beginPath();
    ctx.roundRect(-9, 7, 18, 3, 2);
    ctx.fill();
    ctx.strokeStyle = '#cdb478';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(0, 2.6);
    ctx.lineTo(0, 9);
    ctx.stroke();
    backArm(skinSh); // back bare arm tucked at her side
    // torso (tee) — soft tee-toned outline (no harsh black line through the chest), like the nano suit
    ctx.beginPath();
    ctx.moveTo(-9, 3);
    ctx.lineTo(-9, -4);
    ctx.quadraticCurveTo(-9, -9, -4, -10.5);
    ctx.quadraticCurveTo(0, -9, 4, -10.5);
    ctx.quadraticCurveTo(9, -9, 9, -4);
    ctx.lineTo(9, 3);
    ctx.closePath();
    ctx.fillStyle = tee;
    ctx.fill();
    ctx.strokeStyle = teeSh;
    ctx.lineWidth = 1.3;
    ctx.stroke();
    // gentle chest/collar shading
    ctx.fillStyle = teeSh;
    ctx.beginPath();
    ctx.moveTo(3, -9);
    ctx.quadraticCurveTo(9, -6, 9, 3);
    ctx.lineTo(4, 3);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = teeSh;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-4.5, -9.5);
    ctx.quadraticCurveTo(0, -7.5, 4.5, -9.5);
    ctx.stroke(); // soft collar curve
    // short tee sleeves cover both shoulders + upper arms so the bare forearms emerge cleanly
    ctx.fillStyle = tee;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.fill();
    ctx.strokeStyle = teeSh;
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.ellipse(-8.7, -3.4, 4.3, 4.8, 0.15, 0, 7);
    ctx.ellipse(8.7, -3.4, 4.3, 4.8, -0.15, 0, 7);
    ctx.stroke();
    frontArm(skin); // front bare arm on top
    hands('#ff8ad6', '#ffd6f2', '#ff5bb0');
  }
  // ---- head ----
  const hy = -16 + idle;
  ctx.fillStyle = hair;
  ctx.beginPath();
  ctx.arc(0, hy + 1, 11, 0, 7);
  ctx.fill(); // hair back
  ctx.beginPath();
  ctx.moveTo(-11, hy - 1);
  ctx.quadraticCurveTo(-13, hy + 8, -8, hy + 12);
  ctx.quadraticCurveTo(-9, hy + 5, -9, hy);
  ctx.closePath();
  ctx.fill(); // side locks (bob)
  ctx.beginPath();
  ctx.moveTo(11, hy - 1);
  ctx.quadraticCurveTo(13, hy + 8, 8, hy + 12);
  ctx.quadraticCurveTo(9, hy + 5, 9, hy);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = skin;
  ctx.beginPath();
  ctx.ellipse(0, hy + 3, 8.6, 9, 0, 0, 7);
  ctx.fill(); // face
  if (!custom) {
    ctx.fillStyle = skinSh;
    ctx.beginPath();
    ctx.ellipse(0, hy + 9, 4, 2.6, 0, 0, Math.PI);
    ctx.fill();
  } // chin shade (hidden for the stylised faces — reads as a 2nd mouth otherwise)
  // bear ears (black, brown inner) — skipped for outfits whose headwear covers/replaces them (no double ears)
  if (!EAR_HIDE.has(outfit)) {
    ctx.fillStyle = hair;
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 5, 0, 7);
    ctx.arc(8, hy - 8, 5, 0, 7);
    ctx.fill();
    ctx.fillStyle = outfit === 'nanosuit' ? '#9aa2ac' : skinSh;
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 2.2, 0, 7);
    ctx.arc(8, hy - 8, 2.2, 0, 7);
    ctx.fill(); // nanosuit tints the inner ear gray
  }
  // straight-cut bangs with soft points
  ctx.fillStyle = hair;
  ctx.beginPath();
  ctx.moveTo(-10.5, hy + 1);
  ctx.quadraticCurveTo(-11, hy - 10, 0, hy - 11);
  ctx.quadraticCurveTo(11, hy - 10, 10.5, hy + 1);
  ctx.lineTo(7, hy - 1.5);
  ctx.lineTo(5, hy + 2.5);
  ctx.lineTo(2.5, hy - 1.5);
  ctx.lineTo(0, hy + 2.5);
  ctx.lineTo(-2.5, hy - 1.5);
  ctx.lineTo(-5, hy + 2.5);
  ctx.lineTo(-7, hy - 1.5);
  ctx.closePath();
  ctx.fill();
  ctx.strokeStyle = hairHi;
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(-4, hy - 8);
  ctx.quadraticCurveTo(2, hy - 9, 7, hy - 5);
  ctx.stroke();
  // brows — softer, raised & gently arched for the open-eyed smile (reads friendly, not intense); default otherwise
  if (smile || squee) {
    /* brows sit under the bangs / closed eyes — no separate brow */
  } else if (annoyed) {
    ctx.strokeStyle = hair;
    ctx.lineWidth = 1.2;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-7, hy - 0.2);
    ctx.lineTo(-3, hy + 1);
    ctx.moveTo(3, hy + 0.4);
    ctx.lineTo(7, hy - 0.9);
    ctx.stroke();
  } // mildly annoyed: one brow lowered-inward, the other cocked up (unimpressed)
  else {
    ctx.strokeStyle = hair;
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.moveTo(-7, hy + 0.6);
    ctx.quadraticCurveTo(-5, hy - 0.2, -3, hy + 0.6);
    ctx.moveTo(3, hy + 0.6);
    ctx.quadraticCurveTo(5, hy - 0.2, 7, hy + 0.6);
    ctx.stroke();
  }
  // blush — classic anime slash marks ( / / / ) for the uwu face, soft rosy cheeks otherwise
  if (uwu) {
    ctx.strokeStyle = '#d8546e';
    ctx.lineWidth = 0.9;
    ctx.lineCap = 'round';
    for (let i = 0; i < 3; i++) {
      const bx = -8 + i * 1.5;
      ctx.beginPath();
      ctx.moveTo(bx - 0.7, hy + 7.5);
      ctx.lineTo(bx + 0.7, hy + 5.5);
      ctx.stroke();
    }
    for (let i = 0; i < 3; i++) {
      const bx = 5 + i * 1.5;
      ctx.beginPath();
      ctx.moveTo(bx - 0.7, hy + 7.5);
      ctx.lineTo(bx + 0.7, hy + 5.5);
      ctx.stroke();
    }
  } else if (squee) {
    ctx.fillStyle = 'rgba(240,120,150,0.5)';
    ctx.beginPath();
    ctx.arc(-6.3, hy + 6.6, 2.4, 0, 7);
    ctx.arc(6.3, hy + 6.6, 2.4, 0, 7);
    ctx.fill();
  } // >w< : big excited blush
  else if (smile) {
    ctx.fillStyle = 'rgba(232,120,150,0.42)';
    ctx.beginPath();
    ctx.arc(-6, hy + 7.5, 1.9, 0, 7);
    ctx.arc(6, hy + 7.5, 1.9, 0, 7);
    ctx.fill();
  } // smile face: soft round pink blush
  else if (annoyed) {
    ctx.fillStyle = 'rgba(200,100,90,0.26)';
    ctx.beginPath();
    ctx.arc(-6, hy + 6.6, 1.7, 0, 7);
    ctx.arc(6, hy + 6.6, 1.7, 0, 7);
    ctx.fill();
  } // faint blush
  else if (giggle) {
    ctx.fillStyle = 'rgba(235,120,150,0.46)';
    ctx.beginPath();
    ctx.arc(-6.2, hy + 6.9, 2.1, 0, 7);
    ctx.arc(6.2, hy + 6.9, 2.1, 0, 7);
    ctx.fill();
  } // giggle: soft happy blush
  else {
    ctx.fillStyle = 'rgba(219,120,120,0.42)';
    ctx.beginPath();
    ctx.arc(-6, hy + 6.5, 2.2, 0, 7);
    ctx.arc(6, hy + 6.5, 2.2, 0, 7);
    ctx.fill();
  }
  // eyes (big anime, brown)
  const blink = tick % 230 < 7 && !squee; // the >v< victory face never blinks
  if (uwu) {
    // happy closed ^ ^ eyes with lash flicks — raised slightly to match the smile face's proportions
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-7.8, hy + 4.8);
    ctx.quadraticCurveTo(-5, hy + 1.1, -2.2, hy + 4.8);
    ctx.moveTo(2.2, hy + 4.8);
    ctx.quadraticCurveTo(5, hy + 1.1, 7.8, hy + 4.8);
    ctx.stroke();
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(-7.8, hy + 4.8);
    ctx.lineTo(-8.9, hy + 3.9);
    ctx.moveTo(7.8, hy + 4.8);
    ctx.lineTo(8.9, hy + 3.9);
    ctx.stroke();
  } else if (giggle) {
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round'; // happy closed ^^ giggle eyes (never blinks)
    ctx.beginPath();
    ctx.moveTo(-7.6, hy + 4.5);
    ctx.quadraticCurveTo(-5, hy + 1.1, -2.4, hy + 4.5);
    ctx.moveTo(2.4, hy + 4.5);
    ctx.quadraticCurveTo(5, hy + 1.1, 7.6, hy + 4.5);
    ctx.stroke();
  } else if (blink) {
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-7, hy + 4);
    ctx.quadraticCurveTo(-5, hy + 5, -3, hy + 4);
    ctx.moveTo(3, hy + 4);
    ctx.quadraticCurveTo(5, hy + 5, 7, hy + 4);
    ctx.stroke();
  } else if (smile) {
    for (const ex of [-5, 5]) {
      const dir = ex < 0 ? -1 : 1; // her locked-in smile eyes: big amber almond iris (dark top → gold bottom), thick black upper lid + outer wedge, sits high on the face
      const ig = ctx.createLinearGradient(ex, hy + 1.5, ex, hy + 6.7);
      ig.addColorStop(0, '#48260a');
      ig.addColorStop(0.45, '#9a6326');
      ig.addColorStop(1, '#ecba60'); // amber iris — dark top → gold bottom
      ctx.fillStyle = ig;
      ctx.beginPath();
      ctx.ellipse(ex, hy + 4.0, 2.5, 2.7, 0, 0, 7);
      ctx.fill();
      ctx.fillStyle = '#241205';
      ctx.beginPath();
      ctx.arc(ex, hy + 4.05, 1, 0, 7);
      ctx.fill(); // dark pupil
      ctx.fillStyle = 'rgba(255,238,196,0.92)';
      ctx.beginPath();
      ctx.arc(ex + dir * 0.3, hy + 5.0, 0.75, 0, 7);
      ctx.fill(); // bright reflection low in the iris
      ctx.fillStyle = '#fff';
      ctx.beginPath();
      ctx.arc(ex - dir * 0.8, hy + 3.1, 0.6, 0, 7);
      ctx.fill(); // small upper catchlight
      ctx.strokeStyle = ln;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.lineWidth = 2.4; // thick black upper lid — near-level across the top (calm), outer corner lifted a touch
      ctx.beginPath();
      ctx.moveTo(ex - dir * 2.5, hy + 2.4);
      ctx.quadraticCurveTo(ex, hy + 1.5, ex + dir * 2.7, hy + 2.0);
      ctx.stroke();
      ctx.fillStyle = ln;
      ctx.beginPath();
      ctx.moveTo(ex + dir * 2.7, hy + 2.0);
      ctx.lineTo(ex + dir * 4, hy + 1.5);
      ctx.lineTo(ex + dir * 3, hy + 3.0);
      ctx.closePath();
      ctx.fill(); // thick outer-corner lash wedge (up-out)
    }
  } else if (annoyed) {
    for (const ex of [-5, 5]) {
      const dir = ex < 0 ? -1 : 1; // mildly annoyed: half-lidded, only the lower half of the amber eye shows under a heavy flat lid
      const ig = ctx.createLinearGradient(ex, hy + 3.8, ex, hy + 6.6);
      ig.addColorStop(0, '#6a3d12');
      ig.addColorStop(1, '#cf9646');
      ctx.fillStyle = ig;
      ctx.beginPath();
      ctx.arc(ex, hy + 4.4, 2.3, 0, Math.PI);
      ctx.fill(); // lower half of the eye only
      ctx.fillStyle = '#241205';
      ctx.beginPath();
      ctx.arc(ex, hy + 4.9, 0.9, 0, Math.PI);
      ctx.fill(); // pupil (looking down)
      ctx.fillStyle = '#fff';
      ctx.beginPath();
      ctx.arc(ex - dir * 0.7, hy + 4.9, 0.4, 0, 7);
      ctx.fill();
      ctx.strokeStyle = ln;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.lineWidth = 2.1; // heavy flat droopy upper lid
      ctx.beginPath();
      ctx.moveTo(ex - 2.5, hy + 4.2);
      ctx.quadraticCurveTo(ex, hy + 4.6, ex + 2.5, hy + 4.1);
      ctx.stroke();
    }
  } else if (squee) {
    ctx.strokeStyle = ln;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = 2.3; // >v< : squeezed-shut chevron eyes (slightly bigger) pointing toward the nose
    for (const ex of [-5, 5]) {
      const dir = ex < 0 ? -1 : 1;
      const outerX = ex + dir * 2.6,
        vtxX = ex - dir * 1.7;
      ctx.beginPath();
      ctx.moveTo(outerX, hy + 2.1);
      ctx.lineTo(vtxX, hy + 3.9);
      ctx.lineTo(outerX, hy + 5.7);
      ctx.stroke();
    }
  } else {
    for (const ex of [-5, 5]) {
      ctx.fillStyle = '#fff';
      ctx.beginPath();
      ctx.ellipse(ex, hy + 4, 2.8, 3.6, 0, 0, 7);
      ctx.fill();
      const ig = ctx.createRadialGradient(ex, hy + 4.9, 0.4, ex, hy + 4.4, 3.1);
      ig.addColorStop(0, '#d69b4c');
      ig.addColorStop(1, '#4a2408');
      ctx.fillStyle = ig;
      ctx.beginPath();
      ctx.arc(ex, hy + 4.4, 2.5, 0, 7);
      ctx.fill();
      ctx.fillStyle = '#160b04';
      ctx.beginPath();
      ctx.arc(ex, hy + 4.6, 1.05, 0, 7);
      ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.beginPath();
      ctx.arc(ex - 0.9, hy + 3.1, 1.1, 0, 7);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(ex + 1, hy + 5.4, 0.55, 0, 7);
      ctx.fill();
      ctx.strokeStyle = ln;
      ctx.lineWidth = 1.3;
      ctx.beginPath();
      ctx.ellipse(ex, hy + 4, 2.8, 3.6, 0, Math.PI * 1.02, Math.PI * 2.05);
      ctx.stroke();
    }
  }
  // nose + mouth
  if (custom) {
    ctx.fillStyle = '#3a2012';
    ctx.beginPath();
    ctx.moveTo(-0.9, hy + 6.9);
    ctx.lineTo(0.9, hy + 6.9);
    ctx.lineTo(0, hy + 7.9);
    ctx.closePath();
    ctx.fill();
  } // small dark angular nose (ref) — shared by all her stylised faces
  else
    ((ctx.fillStyle = skinSh),
      ctx.beginPath(),
      ctx.arc(0, hy + 7, 0.7, 0, 7),
      ctx.fill());
  if (uwu) {
    // :3 / w cat mouth (black)
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.4;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-2.8, hy + 8.4);
    ctx.quadraticCurveTo(-1.3, hy + 10.7, 0, hy + 8.9);
    ctx.quadraticCurveTo(1.3, hy + 10.7, 2.8, hy + 8.4);
    ctx.stroke();
  } else if (smile) {
    // small, soft closed smile (ref) — subtle & content
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.2;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-1.5, hy + 8.9);
    ctx.quadraticCurveTo(0, hy + 10, 1.6, hy + 8.7);
    ctx.stroke();
  } else if (annoyed) {
    // small flat pursed mouth (unimpressed), tugged down a touch on one side
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-1.7, hy + 9);
    ctx.quadraticCurveTo(0, hy + 8.9, 1.9, hy + 9.3);
    ctx.stroke();
  } else if (squee) {
    // small "v" mouth (the v in >v<)
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.7;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-2, hy + 8.4);
    ctx.lineTo(0, hy + 10.2);
    ctx.lineTo(2, hy + 8.4);
    ctx.stroke();
  } else if (giggle) {
    // open laugh mouth
    ctx.fillStyle = '#6a2626';
    ctx.beginPath();
    ctx.moveTo(-2.1, hy + 8.5);
    ctx.quadraticCurveTo(0, hy + 11.4, 2.1, hy + 8.5);
    ctx.quadraticCurveTo(0, hy + 9.4, -2.1, hy + 8.5);
    ctx.fill();
    ctx.strokeStyle = ln;
    ctx.lineWidth = 1.1;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-2.1, hy + 8.5);
    ctx.quadraticCurveTo(0, hy + 11.4, 2.1, hy + 8.5);
    ctx.stroke();
  } else {
    ctx.fillStyle = '#7a2c2c';
    ctx.beginPath();
    ctx.moveTo(-1.6, hy + 9);
    ctx.quadraticCurveTo(0, hy + 11, 1.6, hy + 9);
    ctx.quadraticCurveTo(0, hy + 10, -1.6, hy + 9);
    ctx.fill();
  }
  // outfit headwear
  if (outfit === 'maid') {
    ctx.fillStyle = '#f4efe6';
    ctx.beginPath();
    ctx.moveTo(-9, hy - 6);
    ctx.quadraticCurveTo(0, hy - 12, 9, hy - 6);
    ctx.lineTo(9, hy - 3.5);
    ctx.quadraticCurveTo(0, hy - 8.5, -9, hy - 3.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#d6cdbf';
    for (let i = -8; i < 9; i += 3.5) {
      ctx.beginPath();
      ctx.arc(i + 1.5, hy - 3.5, 1.3, 0, Math.PI);
      ctx.fill();
    }
    ctx.fillStyle = '#d23a44';
    circle(-8.5, hy - 5, 1.5, '#d23a44');
    circle(8.5, hy - 5, 1.5, '#d23a44');
  } else if (outfit === 'bride') {
    // sheer side veil framing the face + a little jeweled tiara
    ctx.fillStyle = 'rgba(255,255,255,0.4)';
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.moveTo(s * 8, hy - 9);
      ctx.quadraticCurveTo(s * 15, hy + 2, s * 12, hy + 16);
      ctx.quadraticCurveTo(s * 9.5, hy + 14, s * 8.5, hy + 2);
      ctx.quadraticCurveTo(s * 10, hy - 4, s * 8, hy - 9);
      ctx.closePath();
      ctx.fill();
    }
    ctx.strokeStyle = '#ffe08a';
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(-7.5, hy - 9);
    ctx.quadraticCurveTo(0, hy - 13, 7.5, hy - 9);
    ctx.stroke();
    circle(0, hy - 12.4, 1.5, '#fff');
    circle(-3.5, hy - 10.6, 1, '#ffd6e6');
    circle(3.5, hy - 10.6, 1, '#ffd6e6');
    circle(0, hy - 12.4, 0.7, '#ff9ec4');
  } else if (outfit === 'angel') {
    // glowing golden halo hovering above
    const hbo = Math.sin(tick * 0.1) * 0.8;
    ctx.save();
    ctx.strokeStyle = '#ffe38a';
    ctx.lineWidth = 2.2;
    ctx.shadowColor = '#ffd76a';
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.ellipse(0, hy - 13 + hbo, 6.6, 2.4, 0, 0, 7);
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.strokeStyle = 'rgba(255,255,255,0.85)';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.ellipse(0, hy - 13 + hbo, 6.6, 2.4, 0, Math.PI * 1.08, Math.PI * 1.92);
    ctx.stroke();
    ctx.restore();
  } else if (outfit === 'golden') {
    // jeweled gold crown + a twinkle
    ctx.fillStyle = '#ffcf3a';
    ctx.strokeStyle = '#c8901a';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-7, hy - 8);
    ctx.lineTo(-7, hy - 11);
    ctx.lineTo(-4, hy - 9);
    ctx.lineTo(-2, hy - 12.6);
    ctx.lineTo(0, hy - 9.4);
    ctx.lineTo(2, hy - 12.6);
    ctx.lineTo(4, hy - 9);
    ctx.lineTo(7, hy - 11);
    ctx.lineTo(7, hy - 8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    circle(0, hy - 9.6, 0.9, '#ff5b8d');
    circle(-4, hy - 9.3, 0.7, '#8fd0ff');
    circle(4, hy - 9.3, 0.7, '#8fd0ff');
    ctx.globalAlpha = 0.5 + 0.5 * Math.abs(Math.sin(tick * 0.2));
    circle(8.5, hy - 11, 0.9, '#fff');
    ctx.globalAlpha = 1;
  } else if (outfit === 'succubus') {
    // curved demon horns (replace her ears)
    ctx.strokeStyle = '#4a0818';
    ctx.lineWidth = 0.7;
    for (const s of [-1, 1]) {
      const gg = ctx.createLinearGradient(s * 4, hy - 8, s * 6, hy - 16);
      gg.addColorStop(0, '#5a0a20');
      gg.addColorStop(1, '#c81e4a');
      ctx.fillStyle = gg;
      ctx.beginPath();
      ctx.moveTo(s * 3.5, hy - 7.5);
      ctx.quadraticCurveTo(s * 8.5, hy - 11, s * 6, hy - 16.5);
      ctx.quadraticCurveTo(s * 9.5, hy - 11, s * 7.5, hy - 7);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = '#ff7a9c';
      circle(s * 6.2, hy - 14.6, 0.7, '#ff7a9c');
    } // horn tip gloss
  } else if (outfit === 'nanosuit') {
    // A10-nerve-clip forehead piece (inner ears are tinted gray by the ear code)
    ctx.fillStyle = '#e8324a';
    ctx.beginPath();
    ctx.moveTo(-4.2, hy - 8.5);
    ctx.lineTo(4.2, hy - 8.5);
    ctx.lineTo(2.4, hy - 6.3);
    ctx.lineTo(-2.4, hy - 6.3);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#16121c';
    ctx.lineWidth = 0.8;
    ctx.stroke();
  } else if (outfit === 'badger') {
    // badger hood: dark cap, rounded ears, white center stripe, honey brim
    ctx.fillStyle = '#2a2620';
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.quadraticCurveTo(0, hy - 15, 11, hy - 1);
    ctx.quadraticCurveTo(6, hy - 7, 0, hy - 7.5);
    ctx.quadraticCurveTo(-6, hy - 7, -11, hy - 1);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#2a2620';
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 4.2, 0, 7);
    ctx.arc(8, hy - 8, 4.2, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#f6efe0';
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 1.9, 0, 7);
    ctx.arc(8, hy - 8, 1.9, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#ece7da';
    ctx.beginPath();
    ctx.moveTo(-2.2, hy - 12.6);
    ctx.lineTo(2.2, hy - 12.6);
    ctx.lineTo(1.5, hy - 6);
    ctx.lineTo(-1.5, hy - 6);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#f0b030';
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.quadraticCurveTo(0, hy - 11, 11, hy - 1);
    ctx.stroke();
  } else if (outfit === 'honeybee') {
    // bee antennae topped with little glowing pollen balls
    ctx.strokeStyle = '#1a1712';
    ctx.lineWidth = 1.4;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-3, hy - 7);
    ctx.quadraticCurveTo(-7, hy - 13, -5, hy - 16.5);
    ctx.moveTo(3, hy - 7);
    ctx.quadraticCurveTo(7, hy - 13, 5, hy - 16.5);
    ctx.stroke();
    ctx.save();
    ctx.shadowColor = '#ffd23a';
    ctx.shadowBlur = 4;
    circle(-5, hy - 17, 1.6, '#ffd23a');
    circle(5, hy - 17, 1.6, '#ffd23a');
    ctx.restore();
  } else if (outfit === 'voidling') {
    // otherworldly void aura: rising shadow-flame tendrils, drifting motes, a glowing third eye
    ctx.lineCap = 'round';
    for (let i = 0; i < 5; i++) {
      const bx = (i - 2) * 3.2,
        sway = Math.sin(tick * 0.09 + i * 1.3) * 2.2,
        topY = hy - 15 - Math.abs(i - 2) * 1.4; // rising void tendrils w/ glowing tips
      ctx.strokeStyle = '#20103a';
      ctx.lineWidth = 2.6;
      ctx.beginPath();
      ctx.moveTo(bx, hy - 5);
      ctx.quadraticCurveTo(bx + sway, hy - 11, bx + sway * 1.7, topY);
      ctx.stroke();
      ctx.save();
      ctx.shadowColor = '#9d6bff';
      ctx.shadowBlur = 6;
      ctx.fillStyle = '#c9a0ff';
      ctx.beginPath();
      ctx.arc(bx + sway * 1.7, topY, 1.1, 0, 7);
      ctx.fill();
      ctx.restore();
    }
    ctx.save();
    ctx.shadowColor = '#9d6bff';
    ctx.shadowBlur = 5;
    ctx.fillStyle = '#b98cff'; // drifting void motes orbiting overhead
    for (let i = 0; i < 3; i++) {
      const a = tick * 0.045 + i * 2.094;
      ctx.beginPath();
      ctx.arc(Math.cos(a) * 8, hy - 10 + Math.sin(a) * 3, 0.9, 0, 7);
      ctx.fill();
    }
    ctx.restore();
    ctx.save();
    ctx.shadowColor = '#9d6bff';
    ctx.shadowBlur = 6;
    ctx.fillStyle = '#e4d6ff';
    ctx.beginPath();
    ctx.ellipse(0, hy - 1, 2.1, 1.5, 0, 0, 7);
    ctx.fill();
    ctx.restore(); // glowing third eye
    ctx.fillStyle = '#3a1a6a';
    ctx.beginPath();
    ctx.ellipse(0, hy - 1, 0.85, 1.3, 0, 0, 7);
    ctx.fill();
  } else if (outfit === 'banana') {
    // banana-suit HOOD pulled up around her head — face pokes out the front, brown stem on top
    const ban = '#ffcf3a',
      banD = '#e0a800',
      banL = '#ffe89a',
      tip = '#6a4a24';
    ctx.fillStyle = ban;
    ctx.beginPath();
    ctx.moveTo(-11, hy + 2);
    ctx.quadraticCurveTo(-13, hy - 10, -3, hy - 16);
    ctx.quadraticCurveTo(0, hy - 18, 3, hy - 16);
    ctx.quadraticCurveTo(13, hy - 10, 11, hy + 2); // outer: up and over the top
    ctx.quadraticCurveTo(6, hy - 3, 0, hy - 4);
    ctx.quadraticCurveTo(-6, hy - 3, -11, hy + 2);
    ctx.closePath();
    ctx.fill(); // inner: frames the face opening
    ctx.strokeStyle = banD;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.strokeStyle = banD;
    ctx.lineWidth = 0.8;
    for (const rx of [-5, 0, 5]) {
      ctx.beginPath();
      ctx.moveTo(rx * 0.7, hy - 4.5);
      ctx.quadraticCurveTo(rx * 1.2, hy - 11, rx * 0.6, hy - 16);
      ctx.stroke();
    } // peel ridge lines
    ctx.strokeStyle = banL;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(-11, hy + 2);
    ctx.quadraticCurveTo(-6, hy - 3, 0, hy - 4);
    ctx.quadraticCurveTo(6, hy - 3, 11, hy + 2);
    ctx.stroke(); // lighter peel rim around the face
    ctx.fillStyle = tip;
    ctx.beginPath();
    ctx.roundRect(-1.2, hy - 20, 2.4, 4, 1);
    ctx.fill();
  } // brown stem
  else if (outfit === 'squirrely') {
    // tilted tufted squirrel ears (replacing her bear ears, matching their placement) + acorn
    const fur = '#a5642e',
      furD = '#7a441c',
      tuft = '#e6cfa0',
      inner = '#c07d3e';
    for (const s of [-1, 1]) {
      ctx.save();
      ctx.translate(s * 8, hy - 6);
      ctx.rotate(s * 0.3); // based where her bear ears sit, tilted gently outward to match their orientation
      ctx.fillStyle = fur;
      ctx.beginPath();
      ctx.moveTo(-3.1, 2);
      ctx.quadraticCurveTo(-3.7, -8, 0, -11);
      ctx.quadraticCurveTo(3.7, -8, 3.1, 2);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = furD;
      ctx.lineWidth = 0.8;
      ctx.stroke();
      ctx.fillStyle = inner;
      ctx.beginPath();
      ctx.moveTo(-1.5, 0.5);
      ctx.quadraticCurveTo(-1.7, -6, 0, -8.4);
      ctx.quadraticCurveTo(1.7, -6, 1.5, 0.5);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = tuft;
      ctx.beginPath();
      ctx.arc(0, -10.6, 1.5, 0, 7);
      ctx.fill(); // fluffy tuft tip
      ctx.restore();
    }
    // acorn nestled on top-centre
    ctx.fillStyle = '#dcb87a';
    ctx.beginPath();
    ctx.moveTo(-2.8, hy - 10.5);
    ctx.quadraticCurveTo(-3.2, hy - 7, 0, hy - 6.4);
    ctx.quadraticCurveTo(3.2, hy - 7, 2.8, hy - 10.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#7a4a24';
    ctx.beginPath();
    ctx.ellipse(0, hy - 10.5, 3.4, 2.1, 0, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#5e3818';
    for (let i = -2; i <= 2; i++) {
      ctx.beginPath();
      ctx.arc(i * 1.3, hy - 10.1, 0.45, 0, 7);
      ctx.fill();
    }
    ctx.strokeStyle = '#5e3818';
    ctx.lineWidth = 1.1;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(0, hy - 12.4);
    ctx.lineTo(0.5, hy - 14.2);
    ctx.stroke();
  } else if (outfit === 'honeypot') {
    // a little bee buzzing above her head
    const a = tick * 0.06,
      bx = Math.cos(a) * 9,
      by = hy - 13 + Math.sin(a) * 2.6;
    ctx.fillStyle = 'rgba(220,240,255,0.7)';
    ctx.beginPath();
    ctx.ellipse(bx - 0.6, by - 1.8, 1.5, 0.9, -0.5, 0, 7);
    ctx.ellipse(bx + 0.6, by - 1.8, 1.5, 0.9, 0.5, 0, 7);
    ctx.fill(); // wings
    ctx.fillStyle = '#ffd23a';
    ctx.beginPath();
    ctx.ellipse(bx, by, 2.3, 1.6, 0, 0, 7);
    ctx.fill(); // body
    ctx.fillStyle = '#1a1712';
    ctx.fillRect(bx - 1.7, by - 1.6, 0.8, 3.2);
    ctx.fillRect(bx + 0.5, by - 1.6, 0.8, 3.2);
  } // stripes
  else if (outfit === 'empress') {
    // a gold cosmic diadem with a violet star gem + orbiting stars
    ctx.save();
    ctx.shadowColor = '#ffe08a';
    ctx.shadowBlur = 4;
    ctx.strokeStyle = '#e8c063';
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(-8, hy - 6.5);
    ctx.quadraticCurveTo(0, hy - 10.5, 8, hy - 6.5);
    ctx.stroke();
    ctx.restore(); // diadem band
    ctx.save();
    ctx.shadowColor = '#bfa0ff';
    ctx.shadowBlur = 5;
    ctx.fillStyle = '#e4d6ff';
    ctx.beginPath();
    ctx.moveTo(0, hy - 13);
    ctx.lineTo(1.4, hy - 9.6);
    ctx.lineTo(0, hy - 8.4);
    ctx.lineTo(-1.4, hy - 9.6);
    ctx.closePath();
    ctx.fill();
    ctx.restore(); // star gem
    ctx.fillStyle = '#ffe08a';
    ctx.beginPath();
    ctx.arc(-6, hy - 7.2, 0.9, 0, 7);
    ctx.arc(6, hy - 7.2, 0.9, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#e8e0ff';
    for (let i = 0; i < 3; i++) {
      const a = tick * 0.03 + i * 2.09;
      ctx.beginPath();
      ctx.arc(Math.cos(a) * 11, hy - 11 + Math.sin(a) * 3, 0.7, 0, 7);
      ctx.fill();
    }
  } else if (outfit === 'viking') {
    // horned helmet + nose guard + eyepatch on her left eye (callback to Vibe)
    const steel = '#b3bcc8',
      steelD = '#79828f',
      horn = '#e8dcc0';
    // horns first (behind helmet), cream, curving up-and-out
    ctx.fillStyle = horn;
    ctx.strokeStyle = '#c8bca0';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-8.5, hy - 4);
    ctx.quadraticCurveTo(-17, hy - 7, -15.5, hy - 15);
    ctx.quadraticCurveTo(-12.5, hy - 8, -7, hy - 7);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(8.5, hy - 4);
    ctx.quadraticCurveTo(17, hy - 7, 15.5, hy - 15);
    ctx.quadraticCurveTo(12.5, hy - 8, 7, hy - 7);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    // helmet dome
    ctx.fillStyle = steel;
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.quadraticCurveTo(0, hy - 15, 11, hy - 1);
    ctx.quadraticCurveTo(6, hy - 6, 0, hy - 6.5);
    ctx.quadraticCurveTo(-6, hy - 6, -11, hy - 1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(-10.5, hy - 2);
    ctx.quadraticCurveTo(0, hy - 6.3, 10.5, hy - 2);
    ctx.stroke();
    ctx.fillStyle = '#d8dee6';
    circle(-6, hy - 6, 0.8, '#d8dee6');
    circle(6, hy - 6, 0.8, '#d8dee6');
    // nose guard
    ctx.fillStyle = steel;
    ctx.beginPath();
    ctx.moveTo(-1.6, hy - 3);
    ctx.lineTo(1.6, hy - 3);
    ctx.lineTo(1, hy + 4);
    ctx.lineTo(-1, hy + 4);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = steelD;
    ctx.lineWidth = 0.7;
    ctx.stroke();
    // eyepatch over her LEFT eye + straps
    ctx.strokeStyle = '#161016';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(2.5, hy + 1.5);
    ctx.lineTo(11, hy - 1.5);
    ctx.moveTo(3, hy + 6.5);
    ctx.lineTo(11, hy + 7.5);
    ctx.stroke();
    ctx.fillStyle = '#181318';
    ctx.beginPath();
    ctx.ellipse(5, hy + 4, 3.5, 4, 0, 0, 7);
    ctx.fill();
    ctx.strokeStyle = '#332a33';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.ellipse(5, hy + 4, 3.5, 4, 0, 0, 7);
    ctx.stroke();
  } else if (outfit === 'ourbit') {
    // green twin-tail tufts + little dark horns (mascot reference)
    ctx.fillStyle = '#3a8a2a';
    ctx.beginPath();
    ctx.ellipse(-11, hy + 3, 3, 6, 0.35, 0, 7);
    ctx.ellipse(11, hy + 3, 3, 6, -0.35, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#5cb23a';
    ctx.beginPath();
    ctx.ellipse(-11, hy + 1, 1.5, 3, 0.35, 0, 7);
    ctx.ellipse(11, hy + 1, 1.5, 3, -0.35, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#2a3320';
    ctx.beginPath();
    ctx.moveTo(-4, hy - 9.5);
    ctx.lineTo(-2.4, hy - 13.5);
    ctx.lineTo(-0.8, hy - 9.8);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(4, hy - 9.5);
    ctx.lineTo(2.4, hy - 13.5);
    ctx.lineTo(0.8, hy - 9.8);
    ctx.closePath();
    ctx.fill();
  } else if (outfit === 'bullbina') {
    // bull horns curving out + septum ring
    const horn = '#f0ead6',
      hornT = '#c8bfa2';
    ctx.fillStyle = horn;
    ctx.strokeStyle = hornT;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-7, hy - 6.5);
    ctx.quadraticCurveTo(-16, hy - 6, -18, hy - 12.5);
    ctx.quadraticCurveTo(-14.5, hy - 8.5, -8.5, hy - 8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(7, hy - 6.5);
    ctx.quadraticCurveTo(16, hy - 6, 18, hy - 12.5);
    ctx.quadraticCurveTo(14.5, hy - 8.5, 8.5, hy - 8);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = hair;
    ctx.beginPath();
    ctx.arc(0, hy - 9, 2.2, 0, 7);
    ctx.fill(); // tuft between horns
    ctx.strokeStyle = '#ffd24a';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.arc(0, hy + 8.4, 1.7, 0.15, Math.PI - 0.15);
    ctx.stroke();
  } // septum ring
  else if (outfit === 'monke') {
    // monkey ears sit where her bear ears were + a banana on top
    ctx.fillStyle = '#7a4a24';
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 4, 0, 7);
    ctx.arc(8, hy - 8, 4, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#d8b47a';
    ctx.beginPath();
    ctx.arc(-8, hy - 8, 2, 0, 7);
    ctx.arc(8, hy - 8, 2, 0, 7);
    ctx.fill();
    ctx.save();
    ctx.translate(0, hy - 11);
    ctx.rotate(-0.3);
    ctx.fillStyle = '#ffd23a';
    ctx.beginPath();
    ctx.ellipse(0, 0, 4.6, 1.8, 0, 0, 7);
    ctx.fill();
    ctx.strokeStyle = '#e0a800';
    ctx.lineWidth = 0.6;
    ctx.stroke();
    ctx.fillStyle = '#3a2a10';
    ctx.fillRect(-4.8, -0.6, 1.1, 1.2);
    ctx.restore();
  } else if (outfit === 'pickle') {
    // green pickle cap with bumps, stem + leaf
    ctx.fillStyle = '#6aa832';
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.quadraticCurveTo(0, hy - 15, 11, hy - 1);
    ctx.quadraticCurveTo(6, hy - 7, 0, hy - 7.5);
    ctx.quadraticCurveTo(-6, hy - 7, -11, hy - 1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#4a7e22';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.fillStyle = '#5a9228';
    for (const bp of [
      [-6, hy - 5],
      [-2, hy - 8.5],
      [3, hy - 8.5],
      [6, hy - 5],
      [0, hy - 11.5],
    ]) {
      ctx.beginPath();
      ctx.arc(bp[0], bp[1], 0.9, 0, 7);
      ctx.fill();
    }
    ctx.strokeStyle = '#3a5a18';
    ctx.lineWidth = 1.6;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(0, hy - 12);
    ctx.lineTo(1.5, hy - 16);
    ctx.stroke();
    ctx.fillStyle = '#7ac040';
    ctx.beginPath();
    ctx.ellipse(3.4, hy - 15, 2.5, 1.3, -0.5, 0, 7);
    ctx.fill();
  } else if (outfit === 'emblem') {
    // gold circlet with a ◈ gem
    ctx.strokeStyle = '#c9992e';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    ctx.moveTo(-8, hy - 5.5);
    ctx.quadraticCurveTo(0, hy - 9, 8, hy - 5.5);
    ctx.stroke();
    ctx.strokeStyle = '#ffd27a';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-8, hy - 5.5);
    ctx.quadraticCurveTo(0, hy - 9, 8, hy - 5.5);
    ctx.stroke();
    ctx.save();
    ctx.shadowColor = '#ffe08a';
    ctx.shadowBlur = 6;
    ctx.fillStyle = '#ffe08a';
    ctx.beginPath();
    ctx.moveTo(0, hy - 11);
    ctx.lineTo(1.9, hy - 8.7);
    ctx.lineTo(0, hy - 6.4);
    ctx.lineTo(-1.9, hy - 8.7);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
    ctx.fillStyle = '#fff8e0';
    ctx.beginPath();
    ctx.moveTo(0, hy - 10.2);
    ctx.lineTo(0.7, hy - 8.7);
    ctx.lineTo(0, hy - 7.2);
    ctx.lineTo(-0.7, hy - 8.7);
    ctx.closePath();
    ctx.fill();
  } else if (outfit === 'labrat') {
    // round lab glasses
    ctx.strokeStyle = '#23252c';
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.arc(-5, hy + 4, 3.1, 0, 7);
    ctx.arc(5, hy + 4, 3.1, 0, 7);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(-1.9, hy + 4);
    ctx.lineTo(1.9, hy + 4);
    ctx.moveTo(-8.1, hy + 3.6);
    ctx.lineTo(-9.6, hy + 3);
    ctx.moveTo(8.1, hy + 3.6);
    ctx.lineTo(9.6, hy + 3);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(255,255,255,0.55)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-6.6, hy + 2.4);
    ctx.lineTo(-4.4, hy + 5.2);
    ctx.moveTo(3.4, hy + 2.4);
    ctx.lineTo(5.6, hy + 5.2);
    ctx.stroke();
  } else if (outfit === 'cabal') {
    // deep cowl hood pulled over her head, crimson inner, gold rim + a floating sigil
    ctx.fillStyle = '#0c0810';
    ctx.beginPath();
    ctx.moveTo(-12, hy + 2);
    ctx.quadraticCurveTo(-13, hy - 15, 0, hy - 15.5);
    ctx.quadraticCurveTo(13, hy - 15, 12, hy + 2);
    ctx.quadraticCurveTo(7, hy - 7, 0, hy - 7.5);
    ctx.quadraticCurveTo(-7, hy - 7, -12, hy + 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#8a1224';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-11.5, hy + 1);
    ctx.quadraticCurveTo(0, hy - 8, 11.5, hy + 1);
    ctx.stroke();
    ctx.strokeStyle = '#d8a12e';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-12, hy + 2);
    ctx.quadraticCurveTo(-13, hy - 15, 0, hy - 15.5);
    ctx.quadraticCurveTo(13, hy - 15, 12, hy + 2);
    ctx.stroke();
    ctx.fillStyle = '#3a2a10';
    ctx.beginPath();
    ctx.arc(-6, hy - 9.5, 0.7, 0, 7);
    ctx.arc(6, hy - 9.5, 0.7, 0, 7);
    ctx.fill(); // hood clasps
    ctx.save();
    ctx.shadowColor = '#ffcf5a';
    ctx.shadowBlur = 5 + 3 * (Math.sin(tick * 0.14) * 0.5 + 0.5);
    ctx.strokeStyle = '#ffd27a';
    ctx.lineWidth = 0.9;
    ctx.beginPath();
    ctx.moveTo(0, hy - 13.5);
    ctx.lineTo(1.7, hy - 10.7);
    ctx.lineTo(-1.7, hy - 10.7);
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
  } else if (outfit === 'neko') {
    // pointy cat ears (matched to her hair) + pink inners, plus little whiskers
    ctx.fillStyle = hair;
    ctx.beginPath();
    ctx.moveTo(-9, hy - 4);
    ctx.lineTo(-6.5, hy - 13);
    ctx.lineTo(-2.5, hy - 6.5);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(9, hy - 4);
    ctx.lineTo(6.5, hy - 13);
    ctx.lineTo(2.5, hy - 6.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#f7a8c8';
    ctx.beginPath();
    ctx.moveTo(-7.6, hy - 5.4);
    ctx.lineTo(-6.3, hy - 10.8);
    ctx.lineTo(-4.1, hy - 6.6);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(7.6, hy - 5.4);
    ctx.lineTo(6.3, hy - 10.8);
    ctx.lineTo(4.1, hy - 6.6);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(60,40,55,0.55)';
    ctx.lineWidth = 0.7;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-6.5, hy + 7.4);
    ctx.lineTo(-11.5, hy + 6.6);
    ctx.moveTo(-6.5, hy + 8.4);
    ctx.lineTo(-11, hy + 8.8);
    ctx.moveTo(6.5, hy + 7.4);
    ctx.lineTo(11.5, hy + 6.6);
    ctx.moveTo(6.5, hy + 8.4);
    ctx.lineTo(11, hy + 8.8);
    ctx.stroke();
  } else if (outfit === 'kigurumi') {
    // bear-face hood pushed back: rounded hood, round bear ears + a little snout up top
    const hood = '#b07a45',
      hoodSh = '#8a5c30';
    ctx.fillStyle = hood;
    ctx.beginPath();
    ctx.moveTo(-12, hy + 2);
    ctx.quadraticCurveTo(-13, hy - 14, 0, hy - 14.5);
    ctx.quadraticCurveTo(13, hy - 14, 12, hy + 2);
    ctx.quadraticCurveTo(7, hy - 6, 0, hy - 6.5);
    ctx.quadraticCurveTo(-7, hy - 6, -12, hy + 2);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = hood;
    ctx.beginPath();
    ctx.arc(-8.5, hy - 11, 4.2, 0, 7);
    ctx.arc(8.5, hy - 11, 4.2, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#f0dcc0';
    ctx.beginPath();
    ctx.arc(-8.5, hy - 11, 2, 0, 7);
    ctx.arc(8.5, hy - 11, 2, 0, 7);
    ctx.fill(); // inner ears
    ctx.fillStyle = '#f0dcc0';
    ctx.beginPath();
    ctx.ellipse(0, hy - 10.5, 3, 2.2, 0, 0, 7);
    ctx.fill(); // snout muzzle
    ctx.fillStyle = '#3a2418';
    ctx.beginPath();
    ctx.ellipse(0, hy - 11.4, 1, 0.8, 0, 0, 7);
    ctx.fill(); // nose
    ctx.fillStyle = '#2a1a10';
    ctx.beginPath();
    ctx.arc(-3, hy - 12.6, 0.7, 0, 7);
    ctx.arc(3, hy - 12.6, 0.7, 0, 7);
    ctx.fill(); // hood eyes
    ctx.strokeStyle = hoodSh;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-11.5, hy + 1);
    ctx.quadraticCurveTo(0, hy - 7, 11.5, hy + 1);
    ctx.stroke();
  } else if (outfit === 'cheese') {
    // mouse-face hood pushed back: grey hood, big round ears (pink inner), pink snout + whiskers
    const hood = '#b8b8c6',
      hoodSh = '#8f8f9e';
    ctx.fillStyle = hood;
    ctx.beginPath();
    ctx.arc(-9.5, hy - 11.5, 5.4, 0, 7);
    ctx.arc(9.5, hy - 11.5, 5.4, 0, 7);
    ctx.fill(); // big round mouse ears
    ctx.fillStyle = '#ffbcd8';
    ctx.beginPath();
    ctx.arc(-9.5, hy - 11.5, 3, 0, 7);
    ctx.arc(9.5, hy - 11.5, 3, 0, 7);
    ctx.fill(); // pink inner ears
    ctx.fillStyle = hood;
    ctx.beginPath();
    ctx.moveTo(-12, hy + 2);
    ctx.quadraticCurveTo(-13, hy - 14, 0, hy - 14.5);
    ctx.quadraticCurveTo(13, hy - 14, 12, hy + 2);
    ctx.quadraticCurveTo(7, hy - 6, 0, hy - 6.5);
    ctx.quadraticCurveTo(-7, hy - 6, -12, hy + 2);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#f0eef4';
    ctx.beginPath();
    ctx.ellipse(0, hy - 10.3, 2.6, 2, 0, 0, 7);
    ctx.fill(); // light snout
    ctx.fillStyle = '#ff7ab0';
    ctx.beginPath();
    ctx.ellipse(0, hy - 11.1, 1, 0.8, 0, 0, 7);
    ctx.fill(); // pink nose
    ctx.fillStyle = '#2a1a10';
    ctx.beginPath();
    ctx.arc(-3, hy - 12.6, 0.7, 0, 7);
    ctx.arc(3, hy - 12.6, 0.7, 0, 7);
    ctx.fill(); // hood eyes
    ctx.strokeStyle = hoodSh;
    ctx.lineWidth = 0.5;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(-1.4, hy - 10.5);
    ctx.lineTo(-6, hy - 11);
    ctx.moveTo(-1.4, hy - 10.1);
    ctx.lineTo(-6, hy - 9.7);
    ctx.moveTo(1.4, hy - 10.5);
    ctx.lineTo(6, hy - 11);
    ctx.moveTo(1.4, hy - 10.1);
    ctx.lineTo(6, hy - 9.7);
    ctx.stroke(); // whiskers
    ctx.strokeStyle = hoodSh;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-11.5, hy + 1);
    ctx.quadraticCurveTo(0, hy - 7, 11.5, hy + 1);
    ctx.stroke();
  } else if (outfit === 'business') {
    // tidy side-part sheen + a little bluetooth earpiece (corporate)
    ctx.strokeStyle = 'rgba(255,255,255,0.18)';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(-6, hy - 6.6);
    ctx.quadraticCurveTo(0, hy - 9, 6, hy - 6.6);
    ctx.stroke();
    ctx.fillStyle = '#20242c';
    ctx.beginPath();
    ctx.roundRect(8.2, hy + 2, 2.4, 4, 1);
    ctx.fill();
    ctx.fillStyle = '#3ad84a';
    ctx.shadowColor = '#3ad84a';
    ctx.shadowBlur = 4;
    ctx.beginPath();
    ctx.arc(9.4, hy + 3, 0.7, 0, 7);
    ctx.fill();
    ctx.shadowBlur = 0;
  } else if (outfit === 'jester') {
    // Pomni-style two-point jester hat with bells (blue point left, red point right)
    const blue = '#3f52c4',
      red = '#d8354a',
      gold = '#ffd23a',
      band = '#f4f1e8';
    const w1 = Math.sin(tick * 0.12) * 1.6,
      w2 = Math.sin(tick * 0.12 + 1) * 1.6;
    ctx.fillStyle = blue;
    ctx.beginPath();
    ctx.moveTo(-2, hy - 7);
    ctx.quadraticCurveTo(-9, hy - 11, -13 + w1, hy - 16);
    ctx.quadraticCurveTo(-8, hy - 9, -1, hy - 8.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.moveTo(2, hy - 7);
    ctx.quadraticCurveTo(9, hy - 11, 13 + w2, hy - 16);
    ctx.quadraticCurveTo(8, hy - 9, 1, hy - 8.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(-13 + w1, hy - 16.5, 1.6, 0, 7);
    ctx.arc(13 + w2, hy - 16.5, 1.6, 0, 7);
    ctx.fill();
    ctx.fillStyle = '#c99a1e';
    ctx.beginPath();
    ctx.arc(-13 + w1, hy - 16.5, 0.6, 0, 7);
    ctx.arc(13 + w2, hy - 16.5, 0.6, 0, 7);
    ctx.fill();
    ctx.fillStyle = band;
    ctx.beginPath();
    ctx.moveTo(-9, hy - 6.5);
    ctx.quadraticCurveTo(0, hy - 11.5, 9, hy - 6.5);
    ctx.quadraticCurveTo(0, hy - 8.5, -9, hy - 6.5);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.arc(-4.5, hy - 8.4, 0.9, 0, 7);
    ctx.fill();
    ctx.fillStyle = blue;
    ctx.beginPath();
    ctx.arc(0, hy - 9.1, 0.9, 0, 7);
    ctx.fill();
    ctx.fillStyle = red;
    ctx.beginPath();
    ctx.arc(4.5, hy - 8.4, 0.9, 0, 7);
    ctx.fill();
  } else if (outfit === 'samurai') {
    // kabuto: lacquered bowl, shikoro side-flares, gold kuwagata horns + crescent maedate
    const helm = '#2b2f3c',
      gold = '#d8a72e';
    ctx.fillStyle = helm;
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.lineTo(-13.5, hy + 5);
    ctx.lineTo(-7.5, hy + 3);
    ctx.closePath();
    ctx.fill(); // shikoro flares
    ctx.beginPath();
    ctx.moveTo(11, hy - 1);
    ctx.lineTo(13.5, hy + 5);
    ctx.lineTo(7.5, hy + 3);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = helm;
    ctx.beginPath();
    ctx.moveTo(-11, hy - 1);
    ctx.quadraticCurveTo(0, hy - 15, 11, hy - 1);
    ctx.quadraticCurveTo(6, hy - 6, 0, hy - 6.5);
    ctx.quadraticCurveTo(-6, hy - 6, -11, hy - 1);
    ctx.closePath();
    ctx.fill(); // bowl
    ctx.strokeStyle = '#12151c';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.strokeStyle = gold;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, hy - 13.5);
    ctx.lineTo(0, hy - 6);
    ctx.stroke(); // tehen ridge
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(-8.6, hy - 1.4, 1.5, 0, 7);
    ctx.arc(8.6, hy - 1.4, 1.5, 0, 7);
    ctx.fill(); // fukigaeshi turnbacks
    // gold kuwagata horns + crescent maedate
    ctx.fillStyle = gold;
    ctx.strokeStyle = '#a9791e';
    ctx.lineWidth = 0.6;
    ctx.beginPath();
    ctx.moveTo(-1.5, hy - 8.5);
    ctx.quadraticCurveTo(-10, hy - 12, -6.5, hy - 19);
    ctx.quadraticCurveTo(-4.2, hy - 12.5, -0.6, hy - 9.5);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(1.5, hy - 8.5);
    ctx.quadraticCurveTo(10, hy - 12, 6.5, hy - 19);
    ctx.quadraticCurveTo(4.2, hy - 12.5, 0.6, hy - 9.5);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.save();
    ctx.shadowColor = gold;
    ctx.shadowBlur = 5;
    ctx.fillStyle = gold;
    ctx.beginPath();
    ctx.arc(0, hy - 12, 2.6, 0.35, Math.PI - 0.35, false);
    ctx.arc(0, hy - 10.4, 2.9, Math.PI - 0.5, 0.5, true);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  } // crescent
  // BOTH arms cradle something (e.g. a mug) in front of the chest, bent at the elbow. Forearms EMERGE FROM BELOW the shoulder
  // sleeves (so the shoulder/sleeve stays the top layer there), while the arms + hands + mug sit above the chest where it counts.
  if (hold) {
    const hcx = hold.x,
      hcy = hold.y + 0.5,
      hc = _handCols || ['#ff8ad6', '#ffd6f2', '#ff5bb0'];
    ctx.strokeStyle = _armCol;
    ctx.lineWidth = _armW;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(-8.3, 2.6);
    ctx.lineTo(-8.7, 7);
    ctx.lineTo(hcx - 2.2, hcy);
    ctx.stroke(); // left: emerges below the sleeve → elbow at her side → hand at the mug
    ctx.beginPath();
    ctx.moveTo(8.3, 2.6);
    ctx.lineTo(8.7, 7);
    ctx.lineTo(hcx + 2.2, hcy);
    ctx.stroke(); // right
    pOrb(hcx - 2.2, hcy, hc[0], hc[1], hc[2]);
    pOrb(hcx + 2.2, hcy, hc[0], hc[1], hc[2]);
  }
  ctx.globalAlpha = 1;
  ctx.restore();
  if (p.focus) {
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.arc(0, 0, 4, 0, 7);
    ctx.stroke();
    ctx.fillStyle = '#ff3b8e';
    ctx.beginPath();
    ctx.arc(0, 0, 2, 0, 7);
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,120,190,0.7)';
    for (let i = 0; i < 4; i++) {
      const a = tick * 0.06 + i * 1.57;
      ctx.beginPath();
      ctx.arc(0, 0, 9, a, a + 0.7);
      ctx.stroke();
    }
    ctx.restore();
  }
}
