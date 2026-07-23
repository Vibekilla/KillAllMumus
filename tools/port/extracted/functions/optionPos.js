function optionPos(p,o){ const rot=(p&&p.face!==undefined?p.face:-Math.PI/2)+Math.PI/2, c=Math.cos(rot), s=Math.sin(rot), ly=o.y+16;
  return { x:p.x + c*o.x - s*ly, y:p.y-16 + s*o.x + c*ly }; }
