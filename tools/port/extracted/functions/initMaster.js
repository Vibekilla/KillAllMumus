function initMaster(){ const ac=actx(); if(ac&&!masterGain){ masterGain=ac.createGain(); masterGain.gain.value=sfxVol; masterGain.connect(ac.destination); } }
