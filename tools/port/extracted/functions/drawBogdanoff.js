function drawBogdanoff(b,flash){ const R=b.r;
  // which twin is on the strings? (fake bust passes no active → reflect the live boss, else default Igor)
  const igor = (b.active!==undefined)? b.active==='igor' : (boss&&boss.twin&&boss.active? boss.active==='igor' : true);
  const skin=flash?'#fff':'#c99a6a', skinSh='#a2764c', hair=flash?'#fff':'#e8dcc4', tux='#20202a', accent=igor?'#b48ce0':'#e0b84a';
  const bust=(b.t===undefined);   // the dialogue-box portrait passes a fake with no .t → draw a STATIC astral glow (no per-frame pulse)
  // astral aura behind him (pulses on the field, static in the dialogue picture)
  ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.globalAlpha=bust?0.34:(0.32+0.16*Math.sin(tick*0.1)); ctx.fillStyle=accent; ctx.beginPath(); ctx.arc(0,-R*0.05,R*1.05,0,7); ctx.fill(); ctx.restore();
  // faint puppet strings descending from above
  ctx.strokeStyle=_hexA(accent,0.35); ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(-R*0.5,R*0.2); ctx.lineTo(-R*0.72,-R*1.4); ctx.moveTo(R*0.5,R*0.2); ctx.lineTo(R*0.72,-R*1.4); ctx.stroke();
  // tuxedo shoulders + shirt + bow tie
  ctx.fillStyle=tux; ctx.beginPath(); ctx.ellipse(0,R*0.72,R*0.95,R*0.5,0,0,7); ctx.fill();
  ctx.fillStyle='#f4efe6'; ctx.beginPath(); ctx.moveTo(0,R*0.3); ctx.lineTo(-R*0.15,R*0.72); ctx.lineTo(R*0.15,R*0.72); ctx.closePath(); ctx.fill();
  ctx.fillStyle=accent; ctx.beginPath(); ctx.moveTo(0,R*0.32); ctx.lineTo(-R*0.08,R*0.5); ctx.lineTo(0,R*0.62); ctx.lineTo(R*0.08,R*0.5); ctx.closePath(); ctx.fill();
  // long gaunt face with the signature jutting chin + high cheekbones
  ctx.fillStyle=skin; ctx.beginPath();
  ctx.moveTo(-R*0.42,-R*0.34);
  ctx.quadraticCurveTo(-R*0.54,R*0.04,-R*0.34,R*0.3);
  ctx.quadraticCurveTo(-R*0.2,R*0.64,0,R*0.68);
  ctx.quadraticCurveTo(R*0.2,R*0.64,R*0.34,R*0.3);
  ctx.quadraticCurveTo(R*0.54,R*0.04,R*0.42,-R*0.34);
  ctx.quadraticCurveTo(0,-R*0.5,-R*0.42,-R*0.34); ctx.closePath(); ctx.fill();
  // cheekbone + jaw shadows (over-sculpted look)
  ctx.fillStyle=skinSh; ctx.beginPath(); ctx.ellipse(-R*0.3,R*0.14,R*0.1,R*0.2,0.3,0,7); ctx.ellipse(R*0.3,R*0.14,R*0.1,R*0.2,-0.3,0,7); ctx.fill();
  ctx.beginPath(); ctx.ellipse(0,R*0.5,R*0.16,R*0.12,0,0,7); ctx.fill();   // chin shadow
  // huge swept-back hair
  ctx.fillStyle=hair; ctx.beginPath();
  ctx.moveTo(-R*0.44,-R*0.26);
  ctx.quadraticCurveTo(-R*0.62,-R*0.92,-R*0.08,-R*0.82);
  ctx.quadraticCurveTo(R*0.12,-R*1.08,R*0.52,-R*0.76);
  ctx.quadraticCurveTo(R*0.72,-R*0.48,R*0.44,-R*0.26);
  ctx.quadraticCurveTo(R*0.2,-R*0.48,0,-R*0.44);
  ctx.quadraticCurveTo(-R*0.2,-R*0.48,-R*0.44,-R*0.26); ctx.closePath(); ctx.fill();
  // hair sweep lines
  ctx.strokeStyle=_hexA('#c9bfa2',0.6); ctx.lineWidth=1.2; ctx.beginPath(); for(let i=-2;i<=3;i++){ ctx.moveTo(i*R*0.16,-R*0.4); ctx.quadraticCurveTo(i*R*0.16-R*0.2,-R*0.75,i*R*0.16-R*0.05,-R*0.9); } ctx.stroke();
  // heavy brow + deep-set glowing eyes
  ctx.strokeStyle='#3a2a1a'; ctx.lineWidth=R*0.06; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(-R*0.32,-R*0.12); ctx.lineTo(-R*0.08,-R*0.05); ctx.moveTo(R*0.32,-R*0.12); ctx.lineTo(R*0.08,-R*0.05); ctx.stroke();
  ctx.save(); ctx.shadowColor=accent; ctx.shadowBlur=8; circle(-R*0.2,0.02*R,R*0.07,flash?'#fff':accent); circle(R*0.2,0.02*R,R*0.07,flash?'#fff':accent); ctx.restore();
  ctx.fillStyle='#1a1008'; circle(-R*0.2,0.02*R,R*0.03,'#1a1008'); circle(R*0.2,0.02*R,R*0.03,'#1a1008');
  // long nose + thin flat mouth
  ctx.strokeStyle=skinSh; ctx.lineWidth=2; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(0,-R*0.02); ctx.lineTo(-R*0.05,R*0.2); ctx.lineTo(R*0.04,R*0.22); ctx.stroke();
  ctx.strokeStyle='#7a4a3a'; ctx.beginPath(); ctx.moveTo(-R*0.13,R*0.38); ctx.quadraticCurveTo(0,R*0.34,R*0.13,R*0.38); ctx.stroke();
  // initial floating above (I / G)
  ctx.fillStyle=accent; ctx.font='bold '+(R*0.32)+'px "Trebuchet MS"'; ctx.textAlign='center'; ctx.save(); ctx.shadowColor=accent; ctx.shadowBlur=8; ctx.fillText(igor?'I':'G', 0, -R*0.62); ctx.restore(); ctx.textAlign='left';
}
