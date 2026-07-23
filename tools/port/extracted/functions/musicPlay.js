function musicPlay(){ ytWant=true; if(ytReady&&ytPlayer){ try{ ytPlayer.setVolume(Math.round(musicVol*100)); ytPlayer.unMute(); ytPlayer.playVideo(); }catch(e){} } }
