function drawBobina(p){
  const lean=p.lean||0;
  ctx.save(); ctx.translate(p.x,p.y);
  if(p.iframe>0 && Math.floor(p.iframe/4)%2) ctx.globalAlpha=0.5;
  const breath=Math.sin(tick*0.1)*0.6;         // gentle up/down
  const idle=Math.sin(tick*0.12)*0.7;          // head bob
  const sway=Math.sin(tick*0.09)*1.3 + lean*7; // skirt hem drift (+ trails when leaning)
  const sBob=Math.sin(tick*0.13)*0.9;          // sleeve bob
  ctx.lineJoin='round'; ctx.lineCap='round';
  // rotate the whole body to face her travel direction (full 360), about her centre
  const rot=(p.face!==undefined?p.face:-Math.PI/2)+Math.PI/2;
  ctx.translate(0,-16); ctx.rotate(rot); ctx.translate(0,16+breath);
  // ground shadow + soft glow — drawn INSIDE the rotated frame at her feet, so it flips with her orientation
  ctx.save(); const _ga=ctx.globalAlpha;
  ctx.globalAlpha=_ga*0.5;  ctx.fillStyle='#08040c'; ctx.beginPath(); ctx.ellipse(0,20,13,4.6,0,0,7); ctx.fill();   // drop shadow at her feet
  ctx.globalAlpha=_ga*0.34; ctx.fillStyle='#ff8ad6'; ctx.beginPath(); ctx.ellipse(0,19,11,4,0,0,7);   ctx.fill();   // pink glow
  ctx.restore();
  const _grh=(p.outfit||selectedOutfit||'og')==='ourbit';   // Ourbit mascot has green hair
  const skin='#7c4c31',skinSh='#5f3823',hair=_grh?'#4a9e3a':'#181320',hairHi=_grh?'#7cc255':'#3a3048',ln='#241019';
  // movement-driven animation: legs pump + arms swing when she flies fast
  const mspd=Math.hypot(p.vx||0,p.vy||0), amt=Math.min(1,mspd/3.2), aph=tick*0.4;
  const kickL=Math.sin(aph)*amt*3.2, kickR=Math.sin(aph+Math.PI)*amt*3.2, armSw=Math.sin(aph+0.6)*amt*2.2;
  // shared, consistent arm geometry for EVERY outfit (arms tuck at her sides, shoulders covered) — fixes wonky/mismatched limbs
  // BOTH arms are drawn here (behind the torso) so they poke out the back symmetrically — anchored up at the shoulder joints so they read as in-socket, hanging down to the hands
  const hold=p.hold;   // {x,y}: raise her RIGHT arm + orb to this point (e.g. lifting a coffee) — drawn in front, after the head, so it stays visible
  let _armCol=skinSh, _armW=3.8, _handCols=null;
  const backArm=(col,lw)=>{ _armCol=col; _armW=lw||3.8; if(hold) return;   // when holding, BOTH arms are drawn in front of the chest (below)
    ctx.strokeStyle=col; ctx.lineWidth=_armW;
    ctx.beginPath(); ctx.moveTo(-7.5,-4); ctx.lineTo(-10.5-armSw*0.7,7+sBob); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(7.5,-4);  ctx.lineTo(10.5+armSw*0.7,7-sBob); ctx.stroke(); };
  const frontArm=(col,lw)=>{};   // arms now both drawn by backArm (behind the body); kept as a no-op so every outfit's call site still works
  const hands=(g,c1,c2)=>{ _handCols=[g,c1,c2]; if(hold) return; pOrb(-10.5-armSw*0.7,7.6+sBob,g,c1,c2); pOrb(10.5+armSw*0.7,7.6-sBob,g,c1,c2); };
  const outfit=(p.outfit||selectedOutfit||'og');
  const uwu=(p.expr==='uwu');   // cute ^w^ easter-egg face (closed :3 eyes)
  const smile=(!p.expr || p.expr==='smile');   // her updated open-eye model — now the DEFAULT face (in-game player, main menu, win screen, etc.)
  const annoyed=(p.expr==='annoyed');   // mildly annoyed: half-lidded droopy eyes + flat mouth (Twirl)
  const squee=(p.expr==='squee');       // >v< : squeezed chevron eyes + v mouth + big blush (victory pose, no blink)
  const giggle=(p.expr==='giggle');     // giggling: happy closed ^^ eyes + open laugh mouth (Coffee pose)
  const custom=(uwu||smile||annoyed||squee||giggle);   // any of her stylised preview expressions
  // ===== BODY (outfit-specific) =====
  if(outfit==='maid'){
    const dress='#201b2e', white='#f4efe6', whiteSh='#d6cdbf', ribbon='#d23a44', sway2=Math.sin(tick*0.09)*1.2;
    ctx.strokeStyle=white; ctx.lineWidth=5.5; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,18); ctx.moveTo(4,7); ctx.lineTo(4+kickR,18); ctx.stroke();
    ctx.fillStyle='#26222e'; ctx.beginPath(); ctx.ellipse(-4+kickL,19,3.6,2.3,0,0,7); ctx.ellipse(4+kickR,19,3.6,2.3,0,0,7); ctx.fill();
    ctx.fillStyle=dress; ctx.beginPath(); ctx.moveTo(-8,2); ctx.quadraticCurveTo(-13+sway2,9,-11+sway2,13); ctx.lineTo(11+sway2,13); ctx.quadraticCurveTo(13+sway2,9,8,2); ctx.closePath(); ctx.strokeStyle=ln; ctx.lineWidth=1.4; ctx.stroke(); ctx.fill();
    ctx.fillStyle=white; for(let i=-11;i<11;i+=4){ ctx.beginPath(); ctx.arc(i+2+sway2,13,2.2,0,Math.PI); ctx.fill(); }
    ctx.fillStyle=white; ctx.beginPath(); ctx.moveTo(-5,3); ctx.lineTo(5,3); ctx.lineTo(4,12); ctx.lineTo(-4,12); ctx.closePath(); ctx.fill();
    backArm(skinSh);
    ctx.fillStyle=dress; ctx.beginPath(); ctx.roundRect(-8,-6,16,10,4); ctx.strokeStyle=ln; ctx.lineWidth=1.4; ctx.stroke(); ctx.fill();
    ctx.fillStyle=white; ctx.beginPath(); ctx.roundRect(-4.5,-6,9,10,2); ctx.fill();
    ctx.fillStyle=ribbon; ctx.beginPath(); ctx.moveTo(0,-6); ctx.lineTo(-4,-3); ctx.lineTo(0,-1.5); ctx.lineTo(4,-3); ctx.closePath(); ctx.fill(); circle(0,-3.6,1.4,ribbon);
    ctx.fillStyle=white; ctx.beginPath(); ctx.ellipse(-8.5,-3.3,4.3,4.7,0,0,7); ctx.ellipse(8.5,-3.3,4.3,4.7,0,0,7); ctx.fill();   // puff sleeves cover the shoulders
    frontArm(skin);
    hands('#ff8ad6','#ffd6f2','#ff5bb0');
  } else if(outfit==='bride'){
    // flowing white wedding gown with a pink sash + bouquet
    const gown='#f7f2ec', gownSh='#dcd2c6', sash='#ffcfe0', lace='#ffffff', sway2=Math.sin(tick*0.09)*1.3;
    ctx.strokeStyle='#efe7dc'; ctx.lineWidth=5; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,18); ctx.moveTo(4,7); ctx.lineTo(4+kickR,18); ctx.stroke();
    ctx.fillStyle='#e8dccb'; ctx.beginPath(); ctx.ellipse(-4+kickL,19,3.4,2.2,0,0,7); ctx.ellipse(4+kickR,19,3.4,2.2,0,0,7); ctx.fill();
    ctx.fillStyle=gown; ctx.beginPath(); ctx.moveTo(-8,1); ctx.quadraticCurveTo(-15+sway2,10,-13+sway2,16); ctx.quadraticCurveTo(0,19,13+sway2,16); ctx.quadraticCurveTo(15+sway2,10,8,1); ctx.closePath(); ctx.strokeStyle=gownSh; ctx.lineWidth=1.2; ctx.stroke(); ctx.fill();
    ctx.fillStyle=lace; for(let i=-12;i<12;i+=3.4){ ctx.beginPath(); ctx.arc(i+2+sway2,16,1.8,0,Math.PI); ctx.fill(); }
    ctx.strokeStyle=gownSh; ctx.lineWidth=0.7; ctx.beginPath(); ctx.moveTo(0,3); ctx.lineTo(0,16); ctx.stroke();
    backArm(gownSh);
    ctx.fillStyle=gown; ctx.beginPath(); ctx.roundRect(-8,-6,16,9,4); ctx.strokeStyle=gownSh; ctx.lineWidth=1.2; ctx.stroke(); ctx.fill();
    ctx.fillStyle=gownSh; ctx.beginPath(); ctx.moveTo(-5,-6); ctx.quadraticCurveTo(0,-3.4,5,-6); ctx.quadraticCurveTo(0,-4.6,-5,-6); ctx.fill();
    ctx.fillStyle=sash; ctx.fillRect(-8,1.4,16,2.2);
    ctx.beginPath(); ctx.moveTo(0,2.5); ctx.lineTo(-4,0.3); ctx.lineTo(-4,4.9); ctx.closePath(); ctx.moveTo(0,2.5); ctx.lineTo(4,0.3); ctx.lineTo(4,4.9); ctx.closePath(); ctx.fill(); circle(0,2.5,1.3,'#ff9ec4');
    ctx.fillStyle=lace; ctx.beginPath(); ctx.ellipse(-8.5,-3.3,4.2,4.6,0,0,7); ctx.ellipse(8.5,-3.3,4.2,4.6,0,0,7); ctx.fill();
    frontArm('#efe7dc');
    hands('#ffd6e6','#ffffff','#ffb0d0');
  } else if(outfit==='angel'){
    // white-and-gold robe with feathered wings + gold cord
    const robe='#fbf6e8', robeSh='#e6dcc0', gold='#ffd76a', sway2=Math.sin(tick*0.09)*1.2, wf=Math.sin(tick*0.13)*1.4;
    ctx.fillStyle='rgba(255,255,255,0.94)';
    for(const s of [-1,1]){ ctx.beginPath(); ctx.moveTo(s*5,-3);
      ctx.quadraticCurveTo(s*(16+wf),-10, s*(19+wf),0); ctx.quadraticCurveTo(s*(16+wf),3, s*(13+wf),4);
      ctx.quadraticCurveTo(s*(16+wf),7, s*(11+wf),10); ctx.quadraticCurveTo(s*9,7, s*5,4); ctx.closePath(); ctx.fill();
      ctx.strokeStyle='rgba(214,206,180,0.6)'; ctx.lineWidth=0.6; ctx.stroke(); }
    ctx.strokeStyle=robe; ctx.lineWidth=5; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,18); ctx.moveTo(4,7); ctx.lineTo(4+kickR,18); ctx.stroke();
    ctx.fillStyle='#e8dcc0'; ctx.beginPath(); ctx.ellipse(-4+kickL,19,3.3,2.1,0,0,7); ctx.ellipse(4+kickR,19,3.3,2.1,0,0,7); ctx.fill();
    ctx.fillStyle=robe; ctx.beginPath(); ctx.moveTo(-8,1); ctx.quadraticCurveTo(-13+sway2,10,-11+sway2,15); ctx.quadraticCurveTo(0,17,11+sway2,15); ctx.quadraticCurveTo(13+sway2,10,8,1); ctx.closePath(); ctx.fill();
    ctx.strokeStyle=gold; ctx.lineWidth=1.4; ctx.beginPath(); ctx.moveTo(-11+sway2,15); ctx.quadraticCurveTo(0,17,11+sway2,15); ctx.stroke();
    backArm(robeSh);
    ctx.fillStyle=robe; ctx.beginPath(); ctx.roundRect(-8,-6,16,9,4); ctx.fill();
    ctx.strokeStyle=gold; ctx.lineWidth=1.5; ctx.beginPath(); ctx.moveTo(-6,-5); ctx.lineTo(4,3); ctx.stroke();
    ctx.fillStyle=gold; ctx.fillRect(-8,2,16,1.6);
    ctx.fillStyle=robe; ctx.beginPath(); ctx.ellipse(-8.5,-3.3,4.2,4.6,0,0,7); ctx.ellipse(8.5,-3.3,4.2,4.6,0,0,7); ctx.fill();
    frontArm(robe);
    hands('#fff4c2','#ffffff','#ffe08a');
  } else if(outfit==='golden'){
    // shimmering gold gown with a chest gem + crown (headwear)
    const gold='#ffcf3a', goldHi='#fff1a8', goldSh='#c8901a', sway2=Math.sin(tick*0.09)*1.2;
    ctx.strokeStyle=goldSh; ctx.lineWidth=5; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,18); ctx.moveTo(4,7); ctx.lineTo(4+kickR,18); ctx.stroke();
    ctx.fillStyle='#a8760f'; ctx.beginPath(); ctx.ellipse(-4+kickL,19,3.4,2.2,0,0,7); ctx.ellipse(4+kickR,19,3.4,2.2,0,0,7); ctx.fill();
    const gg=ctx.createLinearGradient(-12,0,12,0); gg.addColorStop(0,goldSh); gg.addColorStop(0.5,goldHi); gg.addColorStop(1,gold);
    ctx.fillStyle=gg; ctx.beginPath(); ctx.moveTo(-8,2); ctx.quadraticCurveTo(-13+sway2,9,-11+sway2,14); ctx.lineTo(11+sway2,14); ctx.quadraticCurveTo(13+sway2,9,8,2); ctx.closePath(); ctx.fill();
    ctx.strokeStyle=goldSh; ctx.lineWidth=0.8; for(let i=-2;i<=2;i++){ ctx.beginPath(); ctx.moveTo(i*2.4,3); ctx.lineTo(i*3.4+sway2,14); ctx.stroke(); }
    backArm(goldSh);
    ctx.fillStyle=gg; ctx.beginPath(); ctx.roundRect(-8,-6,16,10,4); ctx.strokeStyle=goldSh; ctx.lineWidth=1.2; ctx.stroke(); ctx.fill();
    circle(0,-2,1.9,'#fff1a8'); circle(0,-2,1,'#ff5b8d');
    ctx.fillStyle=goldHi; ctx.beginPath(); ctx.ellipse(-8.5,-3.3,4.2,4.6,0,0,7); ctx.ellipse(8.5,-3.3,4.2,4.6,0,0,7); ctx.fill();
    frontArm(gold);
    hands('#fff1a8','#ffffff','#ffcf3a');
  } else if(outfit==='succubus'){
    // dark crimson bodice + jagged skirt, bat wings, a spade-tipped tail (horns in headwear)
    const dress='#8a1030', dressSh='#5a0a20', trim='#2a1030', sway2=Math.sin(tick*0.09)*1.3, wf=Math.sin(tick*0.13)*1.5;
    // bat wings BEHIND
    ctx.fillStyle='rgba(58,12,44,0.94)'; ctx.strokeStyle='rgba(150,24,64,0.6)'; ctx.lineWidth=0.7;
    for(const s of [-1,1]){ ctx.beginPath(); ctx.moveTo(s*5,-4);
      ctx.quadraticCurveTo(s*(15+wf),-12, s*(20+wf),-3); ctx.lineTo(s*(15.5+wf),-0.5); ctx.lineTo(s*(19+wf),3.5); ctx.lineTo(s*(13.5+wf),3.5); ctx.lineTo(s*(16+wf),8); ctx.lineTo(s*(10.5+wf),6.5);
      ctx.quadraticCurveTo(s*8,3, s*5,1); ctx.closePath(); ctx.fill(); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(s*6,-2); ctx.lineTo(s*(17+wf),-3); ctx.moveTo(s*6,0); ctx.lineTo(s*(14.5+wf),2); ctx.stroke(); }   // wing struts
    // spade-tipped tail
    const tw2=Math.sin(tick*0.11)*2.2;
    ctx.strokeStyle=dress; ctx.lineWidth=1.8; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(5,10); ctx.quadraticCurveTo(14+tw2,13,12.5+tw2,20); ctx.stroke();
    ctx.fillStyle=dress; ctx.beginPath(); ctx.moveTo(12.5+tw2,17.5); ctx.lineTo(15.2+tw2,22); ctx.lineTo(12.5+tw2,21); ctx.lineTo(9.8+tw2,22); ctx.closePath(); ctx.fill();
    // legs (thigh-high stockings)
    ctx.strokeStyle=trim; ctx.lineWidth=5; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,18); ctx.moveTo(4,7); ctx.lineTo(4+kickR,18); ctx.stroke();
    ctx.fillStyle='#1a0a14'; ctx.beginPath(); ctx.ellipse(-4+kickL,19,3.4,2.2,0,0,7); ctx.ellipse(4+kickR,19,3.4,2.2,0,0,7); ctx.fill();
    // jagged short skirt
    ctx.fillStyle=dress; ctx.beginPath(); ctx.moveTo(-8,2); ctx.lineTo(-9+sway2,11); ctx.lineTo(-5.5,8.5); ctx.lineTo(-2.5,12); ctx.lineTo(0,8.5); ctx.lineTo(2.5,12); ctx.lineTo(5.5,8.5); ctx.lineTo(9+sway2,11); ctx.lineTo(8,2); ctx.closePath(); ctx.fill(); ctx.strokeStyle=dressSh; ctx.lineWidth=0.8; ctx.stroke();
    backArm(dressSh);
    // strapless bodice + heart cutout
    ctx.fillStyle=dress; ctx.beginPath(); ctx.roundRect(-8,-5,16,8,4); ctx.strokeStyle=dressSh; ctx.lineWidth=1.2; ctx.stroke(); ctx.fill();
    ctx.fillStyle=trim; ctx.beginPath(); ctx.moveTo(0,-0.6); ctx.bezierCurveTo(-3,-3,-2.4,-5.4,0,-3.6); ctx.bezierCurveTo(2.4,-5.4,3,-3,0,-0.6); ctx.fill();
    ctx.fillStyle=dress; ctx.beginPath(); ctx.ellipse(-8.5,-3,3.4,3.9,0,0,7); ctx.ellipse(8.5,-3,3.4,3.9,0,0,7); ctx.fill();   // shoulder bands
    frontArm(skin);
    hands('#ff3b6e','#ffd6e6','#c81e4a');
  } else if(outfit==='nanosuit'){
    // Eva-style red plugsuit: red bodysuit, black accent stripes, orange chest plates, green core gem
    const red='#d0202a', redD='#9c1420', black='#16121c', orange='#ff7a2a', orangeL='#ffb060', green='#3ad84a', steel='#cdd2da';
    // legs (red with black stripe) + boots
    ctx.strokeStyle=red; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,15); ctx.moveTo(4,7); ctx.lineTo(4+kickR,15); ctx.stroke();
    ctx.strokeStyle=black; ctx.lineWidth=1.4; ctx.beginPath(); ctx.moveTo(-4,9.5); ctx.lineTo(-4+kickL*0.7,14.5); ctx.moveTo(4,9.5); ctx.lineTo(4+kickR*0.7,14.5); ctx.stroke();
    ctx.fillStyle=black; ctx.beginPath(); ctx.ellipse(-4+kickL,18,4,2.6,0,0,7); ctx.ellipse(4+kickR,18,4,2.6,0,0,7); ctx.fill();
    // hips (red) with black seam
    ctx.fillStyle=red; ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.strokeStyle=redD; ctx.lineWidth=1.4; ctx.stroke(); ctx.fill();
    ctx.strokeStyle=black; ctx.lineWidth=1.4; ctx.beginPath(); ctx.moveTo(-9,6); ctx.lineTo(9,6); ctx.moveTo(0,2); ctx.lineTo(0,10); ctx.stroke();
    backArm(redD,4);
    // torso (red suit)
    ctx.beginPath(); ctx.moveTo(-9,3); ctx.lineTo(-9,-4); ctx.quadraticCurveTo(-9,-9,-4,-10.5); ctx.lineTo(4,-10.5); ctx.quadraticCurveTo(9,-9,9,-4); ctx.lineTo(9,3); ctx.closePath(); ctx.strokeStyle=redD; ctx.lineWidth=1.4; ctx.stroke(); ctx.fillStyle=red; ctx.fill();
    // black accent stripes down the torso
    ctx.strokeStyle=black; ctx.lineWidth=1.3; ctx.beginPath(); ctx.moveTo(-7.5,-9); ctx.lineTo(-8.5,3); ctx.moveTo(7.5,-9); ctx.lineTo(8.5,3); ctx.stroke();
    // orange chest plates (two) with highlights
    ctx.fillStyle=orange; ctx.beginPath(); ctx.ellipse(-3.6,-5,3.4,3.9,0.25,0,7); ctx.ellipse(3.6,-5,3.4,3.9,-0.25,0,7); ctx.fill();
    ctx.fillStyle=orangeL; ctx.beginPath(); ctx.ellipse(-4.2,-6.2,1.3,1.6,0.2,0,7); ctx.ellipse(3,-6.2,1.3,1.6,-0.2,0,7); ctx.fill();
    ctx.strokeStyle=redD; ctx.lineWidth=0.9; ctx.beginPath(); ctx.ellipse(-3.6,-5,3.4,3.9,0.25,0,7); ctx.ellipse(3.6,-5,3.4,3.9,-0.25,0,7); ctx.stroke();
    // green core gem at sternum
    ctx.fillStyle=green; ctx.shadowColor=green; ctx.shadowBlur=8; ctx.beginPath(); ctx.arc(0,-1,2.2,0,7); ctx.fill(); ctx.shadowBlur=0;
    ctx.fillStyle='#d8ffd0'; ctx.beginPath(); ctx.arc(-0.6,-1.7,0.85,0,7); ctx.fill();
    // black plugsuit collar with steel nubs
    ctx.fillStyle=black; ctx.beginPath(); ctx.roundRect(-6,-11,12,3,1.5); ctx.fill();
    ctx.fillStyle=steel; ctx.beginPath(); ctx.arc(-4,-9.5,0.8,0,7); ctx.arc(4,-9.5,0.8,0,7); ctx.fill();
    // shoulder pads (dark red) cover the joints
    ctx.fillStyle=redD; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();
    frontArm(redD,4);
    hands('#ff9a4a','#ffe0b0','#ff7a2a');
  } else if(outfit==='badger'){
    // cute honey-badger onesie: charcoal fur, white dorsal stripe, honey-amber trim
    const furc='#2a2620', furD='#1a1712', white='#ece7da', honey='#f0b030', cream='#f6efe0';
    // legs (charcoal) + cream paw feet with tiny claws
    ctx.strokeStyle=furc; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,16); ctx.moveTo(4,7); ctx.lineTo(4+kickR,16); ctx.stroke();
    ctx.fillStyle=cream; ctx.beginPath(); ctx.ellipse(-4+kickL,18,3.8,2.5,0,0,7); ctx.ellipse(4+kickR,18,3.8,2.5,0,0,7); ctx.fill();
    ctx.strokeStyle='#c9b48a'; ctx.lineWidth=0.8; ctx.beginPath();
    ctx.moveTo(-6+kickL,19.4); ctx.lineTo(-6+kickL,20.4); ctx.moveTo(-2.4+kickL,19.4); ctx.lineTo(-2.4+kickL,20.4);   // left foot claws
    ctx.moveTo(2.4+kickR,19.4); ctx.lineTo(2.4+kickR,20.4); ctx.moveTo(6+kickR,19.4); ctx.lineTo(6+kickR,20.4);   // right foot claws (was missing)
    ctx.stroke();
    // hips
    ctx.fillStyle=furc; ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.strokeStyle=furD; ctx.lineWidth=1.4; ctx.stroke(); ctx.fill();
    backArm(furD,4);
    // torso (charcoal onesie)
    ctx.beginPath(); ctx.moveTo(-9,3); ctx.lineTo(-9,-4); ctx.quadraticCurveTo(-9,-9,-4,-10.5); ctx.lineTo(4,-10.5); ctx.quadraticCurveTo(9,-9,9,-4); ctx.lineTo(9,3); ctx.closePath(); ctx.strokeStyle=furD; ctx.lineWidth=1.4; ctx.stroke(); ctx.fillStyle=furc; ctx.fill();
    // white dorsal/front stripe (badger signature)
    ctx.fillStyle=white; ctx.beginPath(); ctx.moveTo(-4,-10.5); ctx.lineTo(4,-10.5); ctx.lineTo(3,3); ctx.lineTo(-3,3); ctx.closePath(); ctx.fill();
    // honey-amber collar + belly emblem
    ctx.fillStyle=honey; ctx.beginPath(); ctx.roundRect(-6,-11,12,2.6,1.3); ctx.fill();
    ctx.fillStyle=honey; ctx.beginPath(); ctx.arc(0,-2,1.9,0,7); ctx.fill(); ctx.fillStyle='#fff2c8'; ctx.beginPath(); ctx.arc(-0.5,-2.6,0.7,0,7); ctx.fill();
    // shoulder tufts (dark, white flecks) cover the joints
    ctx.fillStyle=furc; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();
    ctx.fillStyle=white; ctx.beginPath(); ctx.arc(-8.7,-5,1.5,0,7); ctx.arc(8.7,-5,1.5,0,7); ctx.fill();
    frontArm(furD,4);
    hands('#f0b030','#fff2c8','#e0902a');
  } else if(outfit==='honeybee'){
    // black-and-yellow striped bee suit with buzzing translucent wings + fuzzy shoulders
    const yel='#ffd23a', blk='#1a1712', wing='rgba(210,235,255,0.5)', wingE='rgba(180,215,255,0.8)';
    ctx.strokeStyle=blk; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,16); ctx.moveTo(4,7); ctx.lineTo(4+kickR,16); ctx.stroke();   // black legs
    ctx.fillStyle=yel; ctx.beginPath(); ctx.ellipse(-4+kickL,18,3.6,2.4,0,0,7); ctx.ellipse(4+kickR,18,3.6,2.4,0,0,7); ctx.fill();   // yellow boots
    const wf=Math.sin(tick*0.6)*0.18; ctx.fillStyle=wing; ctx.strokeStyle=wingE; ctx.lineWidth=0.8;   // buzzing wings (behind)
    for(const s of [-1,1]){ ctx.save(); ctx.translate(s*7,-7); ctx.rotate(s*(0.6+wf)); ctx.beginPath(); ctx.ellipse(s*5,0,6.5,3.4,0,0,7); ctx.fill(); ctx.stroke(); ctx.restore(); }
    ctx.fillStyle=yel; ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.fill();   // striped abdomen
    ctx.save(); ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.clip(); ctx.fillStyle=blk; ctx.fillRect(-9,3.6,18,1.8); ctx.fillRect(-9,7,18,1.8); ctx.restore();
    backArm(blk,4);
    ctx.beginPath(); ctx.moveTo(-9,3); ctx.lineTo(-9,-4); ctx.quadraticCurveTo(-9,-9,-4,-10.5); ctx.lineTo(4,-10.5); ctx.quadraticCurveTo(9,-9,9,-4); ctx.lineTo(9,3); ctx.closePath(); ctx.fillStyle=yel; ctx.fill();   // striped torso
    ctx.save(); ctx.clip(); ctx.fillStyle=blk; ctx.fillRect(-9,-8,18,2); ctx.fillRect(-9,-3.5,18,2); ctx.fillRect(-9,1,18,2); ctx.restore();
    ctx.fillStyle=blk; ctx.beginPath(); ctx.roundRect(-6,-11,12,2.6,1.3); ctx.fill();   // black collar
    ctx.fillStyle=yel; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();   // fuzzy shoulders
    ctx.fillStyle=blk; ctx.beginPath(); ctx.arc(-8.7,-2.2,1.4,0,7); ctx.arc(8.7,-2.2,1.4,0,7); ctx.fill();
    frontArm(blk,4);
    hands('#ffd23a','#fff3b0','#e0a91e');
  } else if(outfit==='voidling'){
    // eldritch void robe: deep violet, glowing rune trim, a void-eye sigil, wispy tentacle hem
    const voidc='#241238', voidD='#160a24', glow='#9d6bff', glowL='#c9a0ff', rune='#b98cff';
    ctx.strokeStyle=voidc; ctx.lineWidth=6; ctx.lineCap='round';   // tentacle legs
    ctx.beginPath(); ctx.moveTo(-4,7); ctx.quadraticCurveTo(-5+kickL,13,-4+kickL,17); ctx.moveTo(4,7); ctx.quadraticCurveTo(5+kickR,13,4+kickR,17); ctx.stroke();
    ctx.save(); ctx.shadowColor=glow; ctx.shadowBlur=6; ctx.fillStyle=glow; ctx.beginPath(); ctx.arc(-4+kickL,18,1.9,0,7); ctx.arc(4+kickR,18,1.9,0,7); ctx.fill(); ctx.restore();   // glowing tips
    ctx.strokeStyle=voidD; ctx.lineWidth=2.6; for(let i=-2;i<=2;i++){ const tx=i*4, wob=Math.sin(tick*0.12+i)*2; ctx.beginPath(); ctx.moveTo(tx,5); ctx.quadraticCurveTo(tx+wob,11,tx+wob*1.4,16); ctx.stroke(); }   // wispy hem tentacles
    ctx.fillStyle=voidc; ctx.beginPath(); ctx.moveTo(-8,2); ctx.quadraticCurveTo(-12,10,-9,14); ctx.lineTo(9,14); ctx.quadraticCurveTo(12,10,8,2); ctx.closePath(); ctx.fill();   // robe skirt
    backArm(voidD,4);
    ctx.beginPath(); ctx.moveTo(-9,3); ctx.lineTo(-9,-4); ctx.quadraticCurveTo(-9,-9,-4,-10.5); ctx.lineTo(4,-10.5); ctx.quadraticCurveTo(9,-9,9,-4); ctx.lineTo(9,3); ctx.closePath(); ctx.fillStyle=voidc; ctx.fill();   // torso robe
    ctx.save(); ctx.shadowColor=glow; ctx.shadowBlur=6; ctx.fillStyle=glowL; ctx.beginPath(); ctx.ellipse(0,-3,3,2,0,0,7); ctx.fill(); ctx.restore();   // glowing void-eye sigil
    ctx.fillStyle=voidD; ctx.beginPath(); ctx.ellipse(0,-3,1.1,1.6,0,0,7); ctx.fill();   // slit pupil
    ctx.save(); ctx.shadowColor=glow; ctx.shadowBlur=4; ctx.strokeStyle=rune; ctx.lineWidth=1.3; ctx.beginPath(); ctx.moveTo(-6,-10.6); ctx.lineTo(6,-10.6); ctx.stroke(); ctx.restore();   // glowing rune collar
    ctx.lineCap='butt'; ctx.fillStyle=voidD; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();   // shadow shoulder tufts
    frontArm(voidD,4);
    hands('#9d6bff','#e0d0ff','#6a3aa0');
  } else if(outfit==='banana'){
    // a plump banana costume — curved yellow peel body with ridge lines, ripe spots + a lighter belly
    const ban='#ffcf3a', banD='#e0a800', banL='#ffe89a', spot='#a5732a', tip='#6a4a24';
    ctx.strokeStyle=ban; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,16); ctx.moveTo(4,7); ctx.lineTo(4+kickR,16); ctx.stroke();   // legs
    ctx.fillStyle=banD; ctx.beginPath(); ctx.ellipse(-4+kickL,18,3.6,2.3,0,0,7); ctx.ellipse(4+kickR,18,3.6,2.3,0,0,7); ctx.fill();
    ctx.fillStyle=ban; ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.fill();   // hips
    backArm(banD,4);
    ctx.fillStyle=ban; ctx.beginPath(); ctx.moveTo(-8,-9); ctx.quadraticCurveTo(-12,0,-8,9); ctx.quadraticCurveTo(0,12,8,9); ctx.quadraticCurveTo(12,0,8,-9); ctx.quadraticCurveTo(0,-11,-8,-9); ctx.closePath(); ctx.fill(); ctx.strokeStyle=banD; ctx.lineWidth=1.3; ctx.stroke();   // banana body
    ctx.strokeStyle=banD; ctx.lineWidth=0.9; for(const rx of [-4,0,4]){ ctx.beginPath(); ctx.moveTo(rx,-8); ctx.quadraticCurveTo(rx*1.3,0,rx,9); ctx.stroke(); }   // ridge lines
    ctx.fillStyle=banL; ctx.beginPath(); ctx.ellipse(-2,0,2.2,5,0,0,7); ctx.fill();   // belly highlight
    ctx.fillStyle=spot; for(const sp of [[5,-4],[-6,3],[3,6]]){ ctx.beginPath(); ctx.arc(sp[0],sp[1],0.9,0,7); ctx.fill(); }   // ripe spots
    ctx.fillStyle=tip; ctx.beginPath(); ctx.ellipse(0,10,2,1.6,0,0,7); ctx.fill();   // brown tip
    ctx.fillStyle=ban; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();   // shoulders
    frontArm(banD,4);
    hands('#ffcf3a','#ffe89a','#e0a800');
  } else if(outfit==='squirrely'){
    // squirrel onesie: warm brown fur, cream belly, a big bushy tail curling up behind (like Monke)
    const fur='#a5642e', furD='#7a441c', cream='#e6cfa0', furL='#c07d3e';
    ctx.fillStyle=fur; ctx.beginPath(); ctx.moveTo(8,9); ctx.quadraticCurveTo(21,7,21,-6); ctx.quadraticCurveTo(21,-19,7,-16); ctx.quadraticCurveTo(15,-8,12,-1); ctx.quadraticCurveTo(15,5,8,9); ctx.closePath(); ctx.fill();   // big bushy tail
    ctx.strokeStyle=furL; ctx.lineWidth=1; for(let i=0;i<4;i++){ ctx.beginPath(); ctx.moveTo(11,6-i*4.5); ctx.quadraticCurveTo(18,2-i*4.5,16.5,-4-i*3.5); ctx.stroke(); }
    ctx.strokeStyle=fur; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(-4,7); ctx.lineTo(-4+kickL,16); ctx.moveTo(4,7); ctx.lineTo(4+kickR,16); ctx.stroke();
    ctx.fillStyle=cream; ctx.beginPath(); ctx.ellipse(-4+kickL,18,3.8,2.5,0,0,7); ctx.ellipse(4+kickR,18,3.8,2.5,0,0,7); ctx.fill();
    ctx.fillStyle=fur; ctx.beginPath(); ctx.roundRect(-9,2,18,8,3); ctx.strokeStyle=furD; ctx.lineWidth=1.3; ctx.stroke(); ctx.fill();
    backArm(furD,4);
    ctx.beginPath(); ctx.moveTo(-9,3); ctx.lineTo(-9,-4); ctx.quadraticCurveTo(-9,-9,-4,-10.5); ctx.lineTo(4,-10.5); ctx.quadraticCurveTo(9,-9,9,-4); ctx.lineTo(9,3); ctx.closePath(); ctx.fillStyle=fur; ctx.fill(); ctx.strokeStyle=furD; ctx.lineWidth=1.3; ctx.stroke();
    ctx.fillStyle=cream; ctx.beginPath(); ctx.ellipse(0,-2,4,5.4,0,0,7); ctx.fill();
    ctx.fillStyle=fur; ctx.beginPath(); ctx.arc(-8.5,-3.5,4.2,0,7); ctx.arc(8.5,-3.5,4.2,0,7); ctx.fill();
    frontArm(furD,4);
    hands('#c07d3e','#e6cfa0','#7a441c');
  } else if(outfit==='honeypot'){
    // she's wearing a round honeypot — clean amber pot body with honey drips, little legs poking out
    const pot='#e0972a', potD='#b0731a', honey='#ffcf5a';
    ctx.strokeStyle='#7c4c31'; ctx.lineWidth=5.5; ctx.beginPath(); ctx.moveTo(-4,10); ctx.lineTo(-4+kickL,17); ctx.moveTo(4,10); ctx.lineTo(4+kickR,17); ctx.stroke();
    ctx.fillStyle='#5f3823'; ctx.beginPath(); ctx.ellipse(-4+kickL,18.5,3.4,2.2,0,0,7); ctx.ellipse(4+kickR,18.5,3.4,2.2,0,0,7); ctx.fill();
    backArm('#7c4c31',3.8);
    ctx.fillStyle=pot; ctx.beginPath(); ctx.moveTo(-9,-6); ctx.quadraticCurveTo(-13,0,-10,9); ctx.quadraticCurveTo(0,13,10,9); ctx.quadraticCurveTo(13,0,9,-6); ctx.closePath(); ctx.fill(); ctx.strokeStyle=potD; ctx.lineWidth=1.4; ctx.stroke();   // pot body
    ctx.fillStyle=potD; ctx.beginPath(); ctx.ellipse(0,-6,9.5,3,0,0,7); ctx.fill(); ctx.fillStyle=honey; ctx.beginPath(); ctx.ellipse(0,-6,7.5,2.2,0,0,7); ctx.fill();   // honey-filled rim
    ctx.fillStyle=honey; ctx.beginPath(); ctx.moveTo(-8,-5); ctx.quadraticCurveTo(-9,0,-7.5,2); ctx.quadraticCurveTo(-6,0,-6,-5); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.arc(-7.5,2.4,1.4,0,7); ctx.fill();   // drip L
    ctx.beginPath(); ctx.moveTo(6,-5); ctx.quadraticCurveTo(5.5,2,7,4); ctx.quadraticCurveTo(8.5,2,8,-5); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.arc(7,4.4,1.3,0,7); ctx.fill();   // drip R
    ctx.fillStyle=potD; ctx.beginPath(); ctx.roundRect(-9,1.5,18,1.8,1); ctx.fill();   // simple decorative band
    ctx.strokeStyle='rgba(255,255,255,0.4)'; ctx.lineWidth=1.4; ctx.beginPath(); ctx.arc(0,1,7,Math.PI*0.72,Math.PI*0.96); ctx.stroke();   // pot sheen
    frontArm('#7c4c31',3.8);
    hands('#e0972a','#ffcf5a','#b0731a');
  }