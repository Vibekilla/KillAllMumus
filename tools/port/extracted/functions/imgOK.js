function imgOK(i){ return i&&i.complete&&i.naturalWidth; }

/* ---------- Input ---------- */
const keys={};
// This is a mouse-driven game — she follows the cursor. Arrow keys still nudge her (fixed), but there's no editable
// keyboard movement/WASD. Everything else is rebindable in Settings → Controls.
const FIXED_KMAP={ ArrowUp:'up', ArrowDown:'down', ArrowLeft:'left', ArrowRight:'right', KeyM:'menu', KeyT:'tweet', Enter:'start' };
const DEFAULT_BINDS={ shoot:'KeyZ', focus:'ShiftLeft', melee:'Space', meleeswap:'KeyD', bomb:'KeyX', swap:'KeyC', special:'KeyV', cycle:'KeyB', pause:'KeyP', interact:'KeyE', item_switch:'KeyA', item_use:'KeyQ' };
const BIND_LIST=[ ['shoot','Fire'],['focus','Focus / Dash'],['melee','Melee (hold=charge)'],['meleeswap','Switch Melee'],['bomb','Bomb'],['swap','Swap Weapon'],['special','Use Special'],['cycle','Cycle Special'],['item_switch','Switch Item'],['item_use','Use Item (tap)'],['interact','Interact / Shop'],['pause','Pause'] ];
let binds=(()=>{ try{ return Object.assign({}, DEFAULT_BINDS, JSON.parse(localStorage.getItem('bobina_binds'))||{}); }catch(e){ return Object.assign({},DEFAULT_BINDS); } })();
let rebindAction=null, KMAP={};
