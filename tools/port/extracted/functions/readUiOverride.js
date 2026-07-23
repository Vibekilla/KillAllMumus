function readUiOverride(){ try{ const q=new URLSearchParams(location.search).get('touch');
    if(q==='1'||q==='0'){ localStorage.setItem('bobina_ui', q==='1'?'touch':'desktop'); }
    const v=localStorage.getItem('bobina_ui'); if(v==='touch') return true; if(v==='desktop') return false; }catch(e){} return null; }
