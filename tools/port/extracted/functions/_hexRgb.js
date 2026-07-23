function _hexRgb(h){ h=(h||'#fff').replace('#',''); if(h.length===3)h=h.split('').map(c=>c+c).join(''); const n=parseInt(h,16); return [(n>>16)&255,(n>>8)&255,n&255]; }
