function dropLoot(e){
  if(e.kind==='elite'){                                    // elites: point/support drops — their POWER reward is granted directly on kill (see killEnemy), a big chunk but NOT a full fill
    for(let i=0;i<4;i++) dropItem(e.x+(Math.random()-.5)*30,e.y,'point');
    if(Math.random()<0.30) dropItem(e.x,e.y,'life');
    if(Math.random()<0.30) dropItem(e.x,e.y,'bomb');
    if(Math.random()<0.12) dropItem(e.x,e.y,'shield');
  } else if(e.kind==='big'){
    for(let i=0;i<2;i++) dropItem(e.x+(Math.random()-.5)*20,e.y,'power');
    for(let i=0;i<3;i++) dropItem(e.x+(Math.random()-.5)*24,e.y,'point');
    if(Math.random()<0.30) dropItem(e.x,e.y,'life');
    if(Math.random()<0.28) dropItem(e.x,e.y,'bomb');
    if(Math.random()<0.09) dropWeapon(e.x,e.y);            // instant full-power now rare (was 24% + a flat 6%)
    if(Math.random()<0.10) dropItem(e.x,e.y,'shield');     // Monke Frenzy no longer drops — shield only
  } else {
    const r=Math.random();
    if(r<0.13) dropItem(e.x,e.y,'power');                  // regular Mumus no longer drop full power at all
    else if(r<0.58) dropItem(e.x,e.y,'point');
  }
}
