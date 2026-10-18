function ytKick(){
  if(!ytWant) return;
  var vol=Math.round(musicVol*100);
  try{ if(ytPlayer){ ytPlayer.setVolume(vol); ytPlayer.unMute(); ytPlayer.playVideo(); } }catch(e){}
  ytPost('setVolume',[vol]); ytPost('unMute'); ytPost('playVideo');
}
