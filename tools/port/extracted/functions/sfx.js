function sfx(type, vmul){
  // Never throw into the game loop (AudioContext / ramp edge cases were killing item-use frames)
  try{
    const ac=actx(); if(!ac)return;
    const t=ac.currentTime, dest=masterGain||ac.destination, vm=(vmul||1)||1;
    const S=(f0,f1,d,ty,vol)=>{
      const o=ac.createOscillator(), g=ac.createGain(); o.connect(g); g.connect(dest);
      const v0=Math.max(0.0008, (vol||0.05)*vm);
      o.type=ty||'sine';
      o.frequency.setValueAtTime(Math.max(1,f0),t);
      o.frequency.exponentialRampToValueAtTime(Math.max(1,f1),t+d);
      g.gain.setValueAtTime(v0,t);
      g.gain.exponentialRampToValueAtTime(0.001,t+d);
      o.start(t); o.stop(t+d+0.02);
    };
    if(type==='shoot') S(1100,620,0.07,'triangle',0.035);
    else if(type==='hit') S(300,140,0.06,'square',0.05);
    else if(type==='kill') S(180,70,0.13,'sawtooth',0.07);
    else if(type==='graze') S(1500,2300,0.05,'sine',0.03);
    else if(type==='item') S(900,1500,0.06,'triangle',0.05);
    else if(type==='power') S(700,1400,0.12,'square',0.06);
    else if(type==='extend'){ [660,880,1320].forEach((f,i)=>{const oo=ac.createOscillator(),gg=ac.createGain();oo.connect(gg);gg.connect(dest);oo.type='triangle';oo.frequency.value=f;gg.gain.setValueAtTime(0.001,t+i*0.09);gg.gain.linearRampToValueAtTime(0.1,t+i*0.09+0.02);gg.gain.exponentialRampToValueAtTime(0.001,t+i*0.09+0.3);oo.start(t+i*0.09);oo.stop(t+i*0.09+0.32);}); }
    else if(type==='bomb') S(120,900,0.5,'sawtooth',0.14);
    else if(type==='hurt') S(240,70,0.35,'square',0.16);
    else if(type==='card'){ [180,300,240].forEach((f,i)=>{const oo=ac.createOscillator(),gg=ac.createGain();oo.connect(gg);gg.connect(dest);oo.type='sawtooth';oo.frequency.setValueAtTime(f,t+i*0.08);gg.gain.setValueAtTime(0.1,t+i*0.08);gg.gain.exponentialRampToValueAtTime(0.001,t+i*0.08+0.25);oo.start(t+i*0.08);oo.stop(t+i*0.08+0.27);}); }
    else if(type==='win'){ [523,659,784,1046,1318].forEach((f,i)=>{const oo=ac.createOscillator(),gg=ac.createGain();oo.connect(gg);gg.connect(dest);oo.type='triangle';oo.frequency.value=f;gg.gain.setValueAtTime(0.001,t+i*0.1);gg.gain.linearRampToValueAtTime(0.1,t+i*0.1+0.02);gg.gain.exponentialRampToValueAtTime(0.001,t+i*0.1+0.3);oo.start(t+i*0.1);oo.stop(t+i*0.1+0.32);}); }
    // ---- melee weapon sounds ----
    else if(type==='slash') S(2600,760,0.14,'sawtooth',0.055);                       // Kuma Katana — plasma shing
    else if(type==='whip')  S(1500,150,0.18,'sine',0.075);                           // Kraken Lash — whoosh
    else if(type==='thud')  S(170,46,0.18,'square',0.15);                            // Monke Bonk — club thud
    else if(type==='boom'){ [110,72].forEach((f,i)=>{const oo=ac.createOscillator(),gg=ac.createGain();oo.connect(gg);gg.connect(dest);oo.type='sawtooth';oo.frequency.setValueAtTime(f*3,t);oo.frequency.exponentialRampToValueAtTime(f,t+0.42);gg.gain.setValueAtTime(0.16,t+i*0.02);gg.gain.exponentialRampToValueAtTime(0.001,t+0.46);oo.start(t);oo.stop(t+0.48);}); }  // Vault Hammer — boom
    else if(type==='claw'){ [1900,2300,1650].forEach((f,i)=>{const oo=ac.createOscillator(),gg=ac.createGain();oo.connect(gg);gg.connect(dest);oo.type='sawtooth';oo.frequency.setValueAtTime(f,t+i*0.045);oo.frequency.exponentialRampToValueAtTime(f*0.5,t+i*0.045+0.06);gg.gain.setValueAtTime(0.055,t+i*0.045);gg.gain.exponentialRampToValueAtTime(0.001,t+i*0.045+0.08);oo.start(t+i*0.045);oo.stop(t+i*0.045+0.1);}); }  // Badger Claws — triple scratch
    else if(type==='warp'){ const o=ac.createOscillator(),g=ac.createGain(); o.connect(g); g.connect(dest); o.type='sine'; o.frequency.setValueAtTime(180,t); o.frequency.exponentialRampToValueAtTime(1400,t+0.18); o.frequency.exponentialRampToValueAtTime(90,t+0.5); g.gain.setValueAtTime(0.13*vm,t); g.gain.exponentialRampToValueAtTime(0.001,t+0.5); o.start(t); o.stop(t+0.52); }  // Wormhole
  }catch(e){ /* audio optional — never break gameplay */ }
}
// Music = shuffled YouTube playlist. The old lofi radio stream ended, playVideo() on
// that ENDED state was a no-op, and the tab dropped its audio icon. Hidden IFrame.
// Autoplays at the saved volume once the user taps the sound-gate.
let lofiOn=false, ytPlayer=null, ytReady=false, ytWant=false, ytShuffled=false, ytErrSkips=0, ytKickUntil=0;
const YT_LIST='PLC6gDrhD6E1X_mZ8arMGO48Ta-cpsnuzR';
