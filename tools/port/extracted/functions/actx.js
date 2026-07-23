function actx(){ if(!AC){ try{ AC=new(window.AudioContext||window.webkitAudioContext)(); }catch(e){} } return AC; }
