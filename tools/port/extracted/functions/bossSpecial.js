function bossSpecial(b,cx,cy){ // signature heavy attack, fired while b.specialT>0
  const p=player, port=b.data.portrait, col=b.data.color;
  if(port==='ape'){ if(b.t%6===0){ b.spin+=0.5; for(let a=0;a<8;a++) eb(cx,cy,b.spin+a*0.785,2.6,7,'#ffd27a'); } if(b.t%30===0) fanAt(cx,cy,p.x,p.y,9,1.0,3.2,7,'#e6c65a'); }
  else if(port==='robotnik'){ if(b.t%16===0){ for(let k=1;k<=3;k++) ring(cx,cy,18,1.4+k*0.5,6,'#a0e0ff',b.t*0.05+k); } }
  else if(port==='mumina'){ b.spin+=0.16; if(b.t%3===0){ for(let a=0;a<6;a++) eb(cx,cy,b.spin+a*1.047,2.2,6,'#7ed957'); } if(b.t%40===0) fanAt(cx,cy,p.x,p.y,11,1.4,3,6,'#bff58a'); }
  else { if(b.t%40<20){ if(b.t%5===0) fanAt(cx,cy,cx,PF.y-20,7,0.6,-3.4,7,'#ff8a3c'); } else { if(b.t%4===0) for(let a=0;a<9;a++) eb(cx,cy,a/9*6.2832,2.0,6,'#ff5b3c'); } }
}
