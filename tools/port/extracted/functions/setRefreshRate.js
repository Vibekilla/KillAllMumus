function setRefreshRate(hz){
  hz=Number(hz)||60; if(hz!==30&&hz!==60&&hz!==120) hz=60;
  refreshRate=hz; simStepMs=1000/refreshRate;
  const v=document.getElementById('disp-hz-v'); if(v) v.textContent=hz+' Hz';
  document.querySelectorAll('.disp-hz').forEach(b=>b.classList.toggle('on', Number(b.dataset.hz)===hz));
  saveDisplayPrefs();
}
