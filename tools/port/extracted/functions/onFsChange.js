function onFsChange(){ const on=!!(document.fullscreenElement||document.webkitFullscreenElement); if(fsBtn) fsBtn.textContent=on?'🗕':'⛶'; setTimeout(fit,60); }
