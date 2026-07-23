function angDiff(a,b){ let d=(a-b)%(Math.PI*2); if(d>Math.PI)d-=Math.PI*2; if(d<-Math.PI)d+=Math.PI*2; return Math.abs(d); }
