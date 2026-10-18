function _hEsc(s){ return String(s).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c])); }
const CONTROLS=[
  ['Move','Mouse (she follows the cursor) · Arrow keys'],
  ['Fire','hold Z / J'],
  ['Melee swipe','SPACE (hold = charge)'],
  ['Switch melee','D'],
  ['Bomb','X / K'],
  ['Special','V use · B cycle'],
  ['Swap weapon','C / Q'],
  ['Focus (slow + hitbox)','hold SHIFT'],
  ['Dash','double-tap SHIFT'],
  ['Pause','P'],
  ['Menu','M'],
];
