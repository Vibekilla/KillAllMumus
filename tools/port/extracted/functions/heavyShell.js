function heavyShell(x,y,tx,ty,spd){ spd*=SPD; const a=Math.atan2(ty-y,tx-x); bullets.push({x,y,vx:Math.cos(a)*spd,vy:Math.sin(a)*spd,r:12,col:'#ffd27a',grazed:false,hp:4,shell:true}); }
