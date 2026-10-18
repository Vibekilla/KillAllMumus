function saveConsum(){ try{ if(typeof consumInv!=='object'||!consumInv||Array.isArray(consumInv)) consumInv={}; localStorage.setItem('bobina_consum', JSON.stringify(consumInv)); }catch(e){} }

// ======== CLOUD PROGRESS (Bobina-linked accounts) ========
// Mirrors all game mechanics into Postgres for signed-in bc_id users.
let _cloudTimer=null, _cloudBusy=false, _cloudReady=false, _cloudPullDone=false;
