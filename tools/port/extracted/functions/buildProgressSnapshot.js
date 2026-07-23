function buildProgressSnapshot(){
  let handle=''; try{ handle=(localStorage.getItem('bobina_handle')||''); }catch(e){}
  let bindsSnap=null; try{ bindsSnap = (typeof binds!=='undefined') ? binds : JSON.parse(localStorage.getItem('bobina_binds')||'null'); }catch(e){}
  return {
    v:1,
    emblems: (typeof emblemsGot!=='undefined' && emblemsGot) ? emblemsGot : {},
    estats: (typeof estats!=='undefined' && estats) ? estats : {},
    arsenal: {
      w: (typeof arsenalW!=='undefined') ? arsenalW.slice() : [],
      s: (typeof arsenalS!=='undefined') ? arsenalS.slice() : [],
      m: (typeof arsenalM!=='undefined') ? arsenalM.slice() : [],
      i: (typeof arsenalI!=='undefined') ? arsenalI.slice() : []
    },
    heads: (typeof mumuHeads!=='undefined') ? mumuHeads : 0,
    shopUnlocks: (typeof shopUnlocks!=='undefined' && shopUnlocks) ? shopUnlocks : {},
    consum: (typeof consumInv!=='undefined' && consumInv) ? consumInv : {},
    ngUnlocked: (typeof ngUnlocked!=='undefined') ? ngUnlocked : 0,
    hellCleared: !!(typeof hellCleared!=='undefined' && hellCleared),
    difficulty: (typeof difficulty!=='undefined') ? difficulty : 0,
    ngPlus: (typeof ngPlus!=='undefined') ? ngPlus : 0,
    outfit: (typeof selectedOutfit!=='undefined') ? selectedOutfit : 'og',
    pose: (typeof outfitPose!=='undefined') ? outfitPose : 0,
    face: (typeof victoryFace!=='undefined') ? victoryFace : 0,
    handle: handle,
    binds: bindsSnap,
    settings: {
      musicVol: (typeof musicVol!=='undefined') ? musicVol : null,
      sfxVol: (typeof sfxVol!=='undefined') ? sfxVol : null,
      follow: (typeof MOUSE!=='undefined') ? MOUSE.follow : null,
      mspeed: (typeof MOUSE!=='undefined') ? MOUSE.speed : null,
      speedrun: !!(typeof speedrun!=='undefined' && speedrun),
      autofire: (typeof autoFire==='undefined') ? true : !!autoFire,
      ui: (function(){ try{ return localStorage.getItem('bobina_ui'); }catch(e){ return null; } })(),
      displayScale: (typeof displayScale!=='undefined')?displayScale:1,
      refreshRate: (typeof refreshRate!=='undefined')?refreshRate:60,
      debugLayer: !!(typeof debugLayer!=='undefined' && debugLayer)
    }
  };
}
