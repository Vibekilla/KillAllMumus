function applyMusicVol(){ if(ytReady&&ytPlayer){ try{ ytPlayer.setVolume(Math.round(musicVol*100)); }catch(e){} } }
