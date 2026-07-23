function circle(x,y,r,fill,line){ ctx.beginPath(); ctx.arc(x,y,r,0,7); if(line){ctx.strokeStyle=line;ctx.lineWidth=2;ctx.stroke();} ctx.fillStyle=fill; ctx.fill(); }
