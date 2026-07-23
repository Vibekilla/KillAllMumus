function openKeybinds(){ const m=document.getElementById('keybinds'); if(m){ rebindAction=null; renderKeybinds(); try{ syncSettingsUI(); }catch(e){} m.classList.add('on'); } }
