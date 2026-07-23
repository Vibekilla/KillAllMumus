function lerpAngle(a,b,t){ let d=(b-a)%(Math.PI*2); if(d> Math.PI)d-=Math.PI*2; if(d<-Math.PI)d+=Math.PI*2; return a+d*t; }
