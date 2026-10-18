function musicPause(){ ytWant=false; ytKickUntil=0; try{ if(ytPlayer) ytPlayer.pauseVideo(); }catch(e){} ytPost('pauseVideo'); }
setInterval(function(){ if(ytWant && Date.now()<ytKickUntil) ytKick(); }, 1000);
// Sound-enable verification gate — the tap is the user gesture browsers require to autoplay audio
const soundGate=document.getElementById('soundgate');
// go fullscreen on touch devices for an immersive experience (best effort — no-op on iOS Safari, which has no Fullscreen API)
