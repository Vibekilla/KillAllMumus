function consumQty(k){ if(typeof consumInv!=='object'||!consumInv||Array.isArray(consumInv)) consumInv={}; return Math.max(0, Number(consumInv[k])||0); }
