function bodyCtr(p){ const r=(p.face!==undefined?p.face:-Math.PI/2)+Math.PI/2; return { x:p.x-Math.sin(r)*16, y:(p.y-16)+Math.cos(r)*16 }; }
// Wormhole phase veil — dims the field into a vague "alt reality" with scrolling lane-lines + entry/exit shear bars
