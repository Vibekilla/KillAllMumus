function bulletCancelAll(){ let pts=0; for(const b of bullets){ floaters.push({x:b.x,y:b.y,life:22,vy:-0.6,scale:0.42}); if(pts<40){ dropItem(b.x,b.y,'point'); pts++; } } bullets=[]; }
