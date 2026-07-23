function eb(x,y,ang,spd,r,col,hp){ spd*=SPD; bullets.push({x,y,vx:Math.cos(ang)*spd,vy:Math.sin(ang)*spd,r:r||6,col:col||'#ff6ec7',grazed:false,hp:hp||0}); }
