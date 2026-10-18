function readUiOverride(){ try{ const q=new URLSearchParams(location.search).get('touch');
    if(q==='1'||q==='0'){ localStorage.setItem('bobina_ui', q==='1'?'touch':'desktop'); }
    const v=localStorage.getItem('bobina_ui'); if(v==='touch') return true; if(v==='desktop') return false; }catch(e){} return null; }
const _uiOverride=readUiOverride();
const isTouch = _uiOverride!==null ? _uiOverride
  : ((window.matchMedia && window.matchMedia('(hover: none) and (pointer: coarse)').matches)
     || (!window.matchMedia && (('ontouchstart' in window) || navigator.maxTouchPoints>0)));
if(isTouch) document.body.classList.add('touch');
const btnEls={};
document.querySelectorAll('.btn').forEach(b=>{ const k=b.dataset.k; btnEls[k]=b;
  const dn=e=>{e.preventDefault(); if(!keys[k])keyPress(k); keys[k]=true;}; const up=e=>{e.preventDefault(); keys[k]=false;};
  b.addEventListener('touchstart',dn,{passive:false}); b.addEventListener('touchend',up); b.addEventListener('touchcancel',up);
  b.addEventListener('mousedown',dn); b.addEventListener('mouseup',up); b.addEventListener('mouseleave',up);
});
// live touch buttons: SPEC glows "USE!" when charged (tap to unleash) or shows charge % (tap to switch); BOMB shows count; SWAP shows weapon
