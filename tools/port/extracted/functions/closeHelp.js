function closeHelp(){ if(helpEl) helpEl.classList.remove('on'); }
(function(){ renderKeybinds();
  const hb=document.getElementById('set-help'); if(hb){ hb.addEventListener('click',openHelp); hb.addEventListener('touchstart',e=>{e.preventDefault();openHelp();},{passive:false}); }
  const hc=document.getElementById('help-close'); if(hc){ hc.addEventListener('click',closeHelp); hc.addEventListener('touchstart',e=>{e.preventDefault();closeHelp();},{passive:false}); }
  if(helpEl) helpEl.addEventListener('click',e=>{ if(e.target===helpEl) closeHelp(); });
  // keybinds submenu — open from Settings and from the Pause screen
  const skb=document.getElementById('set-keybinds'); if(skb) skb.addEventListener('click',openKeybinds);
  const pkb=document.getElementById('ps-keybinds'); if(pkb) pkb.addEventListener('click',openKeybinds);
  const kbd=document.getElementById('kb-done'); if(kbd) kbd.addEventListener('click',closeKeybinds);
  const kbr=document.getElementById('kb-reset'); if(kbr) kbr.addEventListener('click',()=>{ binds=Object.assign({},DEFAULT_BINDS); saveBinds(); rebuildKMAP(); rebindAction=null; renderKeybinds(); });
  const km=document.getElementById('keybinds'); if(km) km.addEventListener('click',e=>{ if(e.target===km) closeKeybinds(); });
  // reset-inventory: button opens a confirm dialog; confirm wipes bought gear/items/skulls (keeps emblems, outfits, NG+)
  const riOpen=document.getElementById('set-resetinv'); if(riOpen) riOpen.addEventListener('click',()=>{ const m=document.getElementById('resetinv'); if(m) m.classList.add('on'); });
  const riCancel=document.getElementById('ri-cancel'); if(riCancel) riCancel.addEventListener('click',()=>{ const m=document.getElementById('resetinv'); if(m) m.classList.remove('on'); });
  const riConfirm=document.getElementById('ri-confirm'); if(riConfirm) riConfirm.addEventListener('click',()=>{ resetInventory(); const m=document.getElementById('resetinv'); if(m) m.classList.remove('on'); closeSettings(); flashMsg={t:120,txt:'🗑 Inventory reset — starter kit restored'}; try{ sfx('item'); }catch(e){} });
  const rim=document.getElementById('resetinv'); if(rim) rim.addEventListener('click',e=>{ if(e.target===rim) rim.classList.remove('on'); }); })();
let run=null, player, enemies, bullets, pshots, items, particles, floaters, scoreTexts, emotes=[], boss, dialog;
let stageTime, stagePhase, clearInfo, totalKills, sessionScore, graze, killsThisStage, winTimer=0, introTimer=0, flashMsg=null;
let stageEmblemMark=0;   // index into newEmblems at the start of the current stage → lets stage-clear show ONLY emblems actually earned this stage
let clearPortal=null, clearShop=null, clearMsgT=0, shopSel=0, shopReturn='stageclear', shopBtns=[], shopMsg='', shopMsgT=0;   // post-boss: a portal to the clear screen + Honey Badger's shop
// ---- Mumu Heads: currency you collect from kills, spent at Honey Badger's shop (persistent) ----
let mumuHeads=(()=>{ try{ return parseInt(localStorage.getItem('bobina_heads'))||0; }catch(e){ return 0; } })();
let shopUnlocks=(()=>{ try{ return JSON.parse(localStorage.getItem('bobina_shopunlocks'))||{}; }catch(e){ return {}; } })();
