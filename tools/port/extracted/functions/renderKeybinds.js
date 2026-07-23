function renderKeybinds(){ const sc=document.getElementById('kb-list'); if(!sc)return;
  let html='';
  for(const [a,label] of BIND_LIST){ const w=(rebindAction===a);
    html+=`<div class="kb-row"><span>${_hEsc(label)}</span><button class="kb-key${w?' waiting':''}" data-a="${a}">${w?'press…':_hEsc(keyName(binds[a]))}</button></div>`; }
  sc.innerHTML=html;
  sc.querySelectorAll('.kb-key').forEach(b=>{ b.onclick=ev=>{ ev.stopPropagation(); rebindAction=(rebindAction===b.dataset.a?null:b.dataset.a); renderKeybinds(); }; });
}
