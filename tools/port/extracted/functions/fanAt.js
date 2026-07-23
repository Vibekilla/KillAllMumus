function fanAt(x,y,tx,ty,n,arc,spd,r,col){ const base=Math.atan2(ty-y,tx-x); for(let i=0;i<n;i++){ const a=base+(i-(n-1)/2)*(arc/Math.max(1,n-1)); eb(x,y,a,spd,r,col);} }
