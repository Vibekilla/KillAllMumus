function dashLandExplosion(p){ const slash=p.slashDash, base=(tick*4)%360, n=slash?26:16;
  for(let i=0;i<n;i++){ const a=i/n*6.283+Math.random()*0.2, sp=(slash?4:2.6)+Math.random()*(slash?4.5:3), hue=(base+i*(360/n))%360;
    particles.push({x:p.x,y:p.y,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp,life:15+((Math.random()*16)|0),c:`hsl(${hue|0},100%,66%)`}); }
  meleeFx.push({ring:true,rainbow:true,x:p.x,y:p.y,r0:5,r1:slash?62:42,col:'#fff',life:18,t:0});   // expanding rainbow ring
  screenShake=Math.max(screenShake, slash?4.5:2.2); sfx('item'); if(slash) sfx('graze');
}
