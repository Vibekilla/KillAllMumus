function fmtScore(n){ n=Math.max(0,Math.floor(Number(n)||0)); if(n<1000) return String(n);
  const U=['','K','M','B','T','Qa','Qi','Sx','Sp','Oc','No','Dc']; let u=0, v=n; while(v>=1000 && u<U.length-1){ v/=1000; u++; }
  let s=v>=100?v.toFixed(0):v>=10?v.toFixed(1):v.toFixed(2); if(s.indexOf('.')>=0) s=s.replace(/\.?0+$/,''); return s+U[u]; }
