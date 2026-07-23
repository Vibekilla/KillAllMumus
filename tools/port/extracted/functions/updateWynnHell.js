function updateWynnHell(b){ b.hellT++;
  b.hellR = Math.min(82, b.hellT*0.7);
  if(b.hellT%2===0) particles.push({ x:b.x+(Math.random()-.5)*b.hellR*1.5, y:(b.hy||b.y)+ (Math.random()-.4)*b.hellR, vx:(Math.random()-.5)*2, vy:-1-Math.random()*2.4, life:26, c:['#ff3b1a','#ff7a2a','#ffc030'][(Math.random()*3)|0] });
  b.hellShake = (b.hellT<210)? Math.sin(b.hellT*0.7)*Math.min(3.5, b.hellT*0.03) : 0;
  if(!dialog){ b.hellDone++; b.hellSpin += 0.42; b.y = (b.hy||b.y) + b.hellDone*0.5; b.hellScale = Math.max(0, 1 - b.hellDone/74);
    if(b.hellDone>96){ onBossDefeated(); } }
}
