function saveDisplayPrefs(){
  try{
    localStorage.setItem('bobina_disp_scale', String(displayScale));
    localStorage.setItem('bobina_disp_hz', String(refreshRate));
    localStorage.setItem('bobina_disp_debug', debugLayer?'1':'0');
  }catch(e){}
  if(typeof scheduleCloudSave==='function') try{ scheduleCloudSave(false); }catch(e){}
}
