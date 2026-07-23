function joyHomePos(){ const vh=(window.visualViewport?window.visualViewport.height:window.innerHeight);
  const mx=parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--mx'))||40;
  return { x: Math.max(58, mx*0.5+32), y: vh - 106 }; }
