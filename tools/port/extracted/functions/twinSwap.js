function twinSwap(b){   // voluntary hand-off — the current twin retreats (banking his HP) and the other takes the stage
  const other=b.active==='igor'?'grichka':'igor';
  b.tw[b.active].hp=b.hp;
  b.active=other; b.hp=b.tw[other].hp; b.maxhp=b.tw[other].max;
  b.hudName=(other==='igor'?'Igor':'Grichka')+' Bogdanoff';
  b.swapCd=420+((Math.random()*240)|0); b.flash=10; b.spin=0; bulletCancelAll(); sfx('card');
  flashMsg={t:90,txt:'⟳ '+(other==='igor'?'IGOR':'GRICHKA')+' takes the strings'};
  b.mtx=PF.x+55+Math.random()*(PF.w-110); b.mty=PF.y+55+Math.random()*(PF.h-135);
  for(let i=0;i<26;i++) particles.push({x:b.x,y:b.y,vx:(Math.random()-.5)*8,vy:(Math.random()-.5)*8,life:28,c:other==='igor'?'#b48ce0':'#e0b84a'});
  if(!dialog && b.data.taunts) startDialog([{w:0,t:b.data.taunts[(Math.random()*b.data.taunts.length)|0]}], b.data);
}
