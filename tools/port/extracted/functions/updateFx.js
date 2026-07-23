function updateFx(){
  const p=player;
  for(const f of fx){
    if(f.type==='laser'){ f.t--; f.x=p.x; f.y=p.y; f.ang=(p.aim!==undefined?p.aim:-Math.PI/2); const dx=Math.cos(f.ang),dy=Math.sin(f.ang),half=f.w/2;
      const onBeam=(ex,ey,rad)=>{ const rx=ex-f.x,ry=ey-f.y,proj=rx*dx+ry*dy; if(proj<0||proj>PF.w+PF.h)return false; return Math.abs(rx*dy-ry*dx)<half+rad; };
      for(const e of enemies){ if(onBeam(e.x,e.y,e.r)){ e.hp-=2; e.flash=4; if(e.hp<=0){ killEnemy(e); } } }
      if(boss&&!boss.dead&&boss.intro<=0 && onBeam(boss.x,boss.y,boss.r)){ boss.hp-=4; boss.flash=3; }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; return !onBeam(b.x,b.y,0); });
      if(f.t%3===0){ const d=40+Math.random()*300; sparks(f.x+dx*d,f.y+dy*d,'#c9a0ff'); }
    } else if(f.type==='mech'){ f.t--; f.ct++;
      // escort that FOLLOWS her orientation — hovers in front (her aim direction) and turns with her
      const face=(p.aim!==undefined?p.aim:-Math.PI/2), hx=p.x+Math.cos(face)*46, hy=p.y+Math.sin(face)*46;
      f.x+=(hx-f.x)*0.2; f.y+=(hy-f.y)*0.2; f.x=Math.max(PF.x+16,Math.min(PF.x+PF.w-16,f.x)); f.y=Math.max(PF.y+18,Math.min(PF.y+PF.h-18,f.y)); f.face=face;
      // MIMIC her equipped ranged weapon and DOUBLE the output — fires her weapon's shots from both cannons at twice the cadence
      if(f.ct%3===0){ const wep=(run&&run.weapon)||'spread'; optionShot(f.x-9,f.y,face,wep); optionShot(f.x+9,f.y,face,wep); if(f.ct%9===0) sfx('shoot'); }
      // SHIELD her — cancel any enemy bullets that reach the bubble around her
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; if(Math.hypot(b.x-p.x,b.y-p.y)<28){ floaters.push({x:b.x,y:b.y,life:10,vy:-0.4,scale:0.28}); sparks(b.x,b.y,'#8fb8ff'); return false; } return true; });
    } else if(f.type==='bearzooka'){ f.t--; f.ct++; f.x += (PF.w+90)/156; f.y = PF.y+34 + Math.sin(f.ct*0.14)*6;   // gunship sweeps across the top
      const overField=(f.x>PF.x-14 && f.x<PF.x+PF.w+14);
      if(overField && f.ct%5===0){ for(let d=0;d<3;d++) fx.push({type:'bombdrop', t:150, x:f.x+(Math.random()-.5)*72, y:f.y+12, vy:2.3+Math.random()*0.8, ty:PF.y+80+Math.random()*(PF.h-150)}); }   // carpet bombs — a wide, dense, slower-falling spread
      if(overField && f.ct%3===0){ for(let k=-1;k<=1;k++) pshots.push({x:f.x+k*10,y:f.y+8,vx:(Math.random()-.5)*3,vy:9+Math.random()*3,dmg:2,dead:false}); if(f.ct%9===0)sfx('shoot'); }   // bullet volley
    } else if(f.type==='bombdrop'){ f.t--; f.y+=f.vy; f.vy+=0.26;
      if(f.y>=f.ty){ f._dead=true; burst(f.x,f.ty,'#ff9a3c'); burst(f.x,f.ty,'#ffd27a'); screenShake=Math.max(screenShake,4.5); if(Math.random()<0.5)sfx('bomb',0.65);
        for(let i=0;i<18;i++) particles.push({x:f.x,y:f.ty,vx:(Math.random()-.5)*11,vy:(Math.random()-.5)*11,life:24,c:i%2?'#ff9a3c':'#fff'});
        for(const e of enemies){ if(Math.hypot(e.x-f.x,e.y-f.ty)<62){ e.hp-=12; e.flash=6; if(e.hp<=0) killEnemy(e); } }
        if(boss&&!boss.dead&&boss.intro<=0 && Math.hypot(boss.x-f.x,boss.y-f.ty)<70){ boss.hp-=6; boss.flash=5; }
        bullets=bullets.filter(b=>{ if(b.hp>0)return true; return Math.hypot(b.x-f.x,b.y-f.ty)>54; }); } }
    else if(f.type==='blackhole'){ f.t--; f.dt++;
      if(f.dt<16){ f.x+=f.vx; f.y+=f.vy; f.vx*=0.9; f.vy*=0.9; }   // launch, then settle and pull
      f.x=Math.max(PF.x+24,Math.min(PF.x+PF.w-24,f.x)); f.y=Math.max(PF.y+24,Math.min(PF.y+PF.h-24,f.y)); f.r=Math.min(15,(f.r||0)+1.1);
      const pull=155;
      for(const e of enemies){ const dx=f.x-e.x, dy=f.y-e.y, d=Math.hypot(dx,dy)||1; if(d<pull){ const g=(1-d/pull)*2.6; e.x+=dx/d*g; e.y+=dy/d*g;   // suck toward centre → groups them
        if(d<26 && f.dt%8===0){ e.hp-=4; e.flash=4; if(e.hp<=0) killEnemy(e); } } }
      enemies=enemies.filter(e=>e.hp>0);
      if(boss&&!boss.dead&&boss.intro<=0 && f.dt%12===0 && Math.hypot(f.x-boss.x,f.y-boss.y)<pull*0.7){ boss.hp-=3; boss.flash=3; }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; const dx=f.x-b.x,dy=f.y-b.y,d=Math.hypot(dx,dy)||1;
        if(d<pull){ const g=(1-d/pull)*2.4; b.vx=b.vx*0.9+dx/d*g; b.vy=b.vy*0.9+dy/d*g;   // gravity + orbital decay: kills their momentum and spirals them in
          if(d<16){ floaters.push({x:b.x,y:b.y,life:8,vy:-0.3,scale:0.24}); sparks(b.x,b.y,f.col); return false; } }   // devoured at the core
        return true; });
      if(!paused && f.dt%2===0){ const a=Math.random()*6.283, rr=pull*(0.5+Math.random()*0.5); particles.push({x:f.x+Math.cos(a)*rr,y:f.y+Math.sin(a)*rr,vx:-Math.cos(a)*3.5,vy:-Math.sin(a)*3.5,life:14,c:Math.random()<0.55?f.col:'#0a3018'}); }
      if(f.t<=0) f._dead=true; }
    else if(f.type==='wave'){ if(f.delay>0){ f.delay--; continue; } f.r+=9;
      const lo=f.r-14, hi=f.r+6;
      for(const e of enemies){ if(!f.hit.has(e)){ const d=Math.hypot(e.x-f.x,e.y-f.y); if(d>lo&&d<hi){ f.hit.add(e); e.hp-=5; e.flash=5; if(e.hp<=0) killEnemy(e); } } }
      if(boss&&!boss.dead&&boss.intro<=0 && !f.hit.has(boss)){ const d=Math.hypot(boss.x-f.x,boss.y-f.y); if(d>lo&&d<hi){ f.hit.add(boss); boss.hp-=14; boss.flash=5; } }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; const d=Math.hypot(b.x-f.x,b.y-f.y); return !(d>lo&&d<hi); });
      if(f.r>PF.w+PF.h) f.alive=false;
    } else if(f.type==='bull'){ f.t--; f.y-=9.5; f.x+=Math.sin((100-f.t)*0.2)*0.6;
      for(const e of enemies){ if(!f.hit.has(e) && Math.abs(e.x-f.x)<24+e.r && Math.abs(e.y-f.y)<30){ f.hit.add(e); e.hp-=7; e.flash=5; if(e.hp<=0) killEnemy(e); } }
      if(boss&&!boss.dead&&boss.intro<=0 && Math.abs(boss.x-f.x)<28+boss.r && Math.abs(boss.y-f.y)<34){ boss.hp-=3; boss.flash=4; }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; return !(Math.abs(b.x-f.x)<24 && Math.abs(b.y-f.y)<26); });
      if(f.y<PF.y-40) f._dead=true;
    } else if(f.type==='badger'){ f.t--; f.x+=f.dir*12; f.y+=Math.sin((90-f.t)*0.3)*1.2;   // fearless charge across the field
      for(const e of enemies){ if(!f.hit.has(e) && Math.abs(e.x-f.x)<26+e.r && Math.abs(e.y-f.y)<22){ f.hit.add(e); e.hp-=8; e.flash=5; if(e.hp<=0) killEnemy(e); } }
      if(boss&&!boss.dead&&boss.intro<=0 && Math.abs(boss.x-f.x)<32+boss.r && Math.abs(boss.y-f.y)<26){ boss.hp-=3; boss.flash=4; }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; return !(Math.abs(b.x-f.x)<30 && Math.abs(b.y-f.y)<20); });   // honey badger don't care about bullets
      if(f.dir>0 && f.x>PF.x+PF.w+50) f._dead=true; if(f.dir<0 && f.x<PF.x-50) f._dead=true;
    }
    else if(f.type==='kiss'){ f.t--; f.r+=8; if(f.t<=0) f._dead=true; }   // charm shockwave (enemies already flagged e.charm)
    else if(f.type==='tentacle'){ f.t--; f.ph+=0.13;   // Unleash the Kraken — thrashes nearby Mumus
      for(const e of enemies){ const d=Math.hypot(e.x-f.x,e.y-f.y); if(d<f.reach){ if(f.t%9===0){ e.hp-=4; e.flash=4; if(e.hp<=0) killEnemy(e); } const g=(1-d/f.reach)*0.5; e.x+=(f.x-e.x)/(d||1)*g; e.y+=(f.y-e.y)/(d||1)*g; } }
      if(boss&&!boss.dead&&boss.intro<=0 && f.t%12===0 && Math.hypot(f.x-boss.x,f.y-boss.y)<f.reach){ boss.hp-=2; boss.flash=2; }
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; if(Math.hypot(b.x-f.x,b.y-f.y)<f.reach*0.5){ floaters.push({x:b.x,y:b.y,life:8,vy:-0.3,scale:0.24}); return false; } return true; });
      if(f.t<=0) f._dead=true; }
    else if(f.type==='servitor'){ f.t--; f.ct++;   // Call of the Void — eldritch minion hunts Mumus, has HP
      let tgt=null, best=1e9; for(const e of enemies){ const d=Math.hypot(e.x-f.x,e.y-f.y); if(d<best){ best=d; tgt=e; } }
      if(!tgt && boss&&!boss.dead&&boss.intro<=0){ tgt={x:boss.x,y:boss.y}; }
      if(tgt){ const dx=tgt.x-f.x,dy=tgt.y-f.y,d=Math.hypot(dx,dy)||1; if(d>62){ f.x+=dx/d*2.2; f.y+=dy/d*2.2; }
        if(f.ct%8===0){ const base=Math.atan2(dy,dx); for(let b=-1;b<=1;b++){ const a=base+b*0.16; pshots.push({x:f.x,y:f.y,vx:Math.cos(a)*9,vy:Math.sin(a)*9,dmg:3,dead:false,laser:true,voidbolt:true}); } if(f.ct%24===0)sfx('shoot'); } }   // fires a 3-bolt spread, far more often
      else { f.x+=Math.sin(f.ct*0.05)*0.7; f.y+=Math.cos(f.ct*0.04)*0.7; }
      f.x=Math.max(PF.x+18,Math.min(PF.x+PF.w-18,f.x)); f.y=Math.max(PF.y+18,Math.min(PF.y+PF.h-18,f.y));
      bullets=bullets.filter(b=>{ if(b.hp>0)return true; if(Math.hypot(b.x-f.x,b.y-f.y)<13*(f.sz||1)){ f.hp-=5; sparks(b.x,b.y,'#9d6bff'); return false; } return true; });   // their big bodies soak bullets but take heavy damage doing it — they don't last long under fire
      if(f.hp<=0 || f.t<=0){ f._dead=true; burst(f.x,f.y,'#9d6bff'); } }
    else if(f.type==='bubble'){
      if(f.pop>0){ f.pop--; f.popR+=4; if(f.pop<=0) f._dead=true; }   // popping — expanding shockwave
      else { f.life--; f.x+=f.vx; f.y+=f.vy; f.vy+=0.015; f.vx*=0.99; f.vy*=0.985; f.r=Math.min(f.rmax, f.r+0.35);
        if(f.x<PF.x+f.r){ f.x=PF.x+f.r; f.vx=Math.abs(f.vx)*0.6; } if(f.x>PF.x+PF.w-f.r){ f.x=PF.x+PF.w-f.r; f.vx=-Math.abs(f.vx)*0.6; }
        if(f.y<PF.y+f.r){ f.y=PF.y+f.r; f.vy=Math.abs(f.vy)*0.6; } if(f.y>PF.y+PF.h-f.r){ f.y=PF.y+PF.h-f.r; f.vy=-Math.abs(f.vy)*0.6; }
        let caught=0; for(const e of enemies){ const dx=f.x-e.x, dy=f.y-e.y, d=Math.hypot(dx,dy)||1; if(d<f.r+e.r+10){ const gp=(1-Math.min(1,d/(f.r+34)))*1.7; e.x+=dx/d*gp; e.y+=dy/d*gp; e.flash=Math.max(e.flash,2); caught++; } }   // trap: pull Mumus in, grouping them
        f.caught=caught;
        if(f.life<=0 || f.caught>=5){ f.pop=16; f.popR=f.r; sfx('bomb');   // POP → AoE burst
          const R=f.r+46; for(const e of enemies){ if(Math.hypot(e.x-f.x,e.y-f.y)<R){ e.hp-=18; e.flash=6; if(e.hp<=0) killEnemy(e); } }
          if(boss && !boss.dead && boss.intro<=0 && Math.hypot(boss.x-f.x,boss.y-f.y)<R){ boss.hp-=12; boss.flash=4; }
          for(let i=0;i<18;i++) particles.push({x:f.x,y:f.y,vx:(Math.random()-.5)*7,vy:(Math.random()-.5)*7,life:24,c:i%2?'#bfe8ff':'#eafcff'}); }
      }
    }
    else if(f.type==='stardust'){ const pp=player; f.life--; if(f.life<=0) f._dead=true;
      if(pp&&!pp.dead){ f.x=pp.x; f.y=pp.y-14; }
      // birth a new twinkling star at a random spot around her
      if(f.life>0 && f.life%5===0){ const a=Math.random()*6.283, r=18+Math.random()*58; f.stars.push({x:f.x+Math.cos(a)*r, y:f.y+Math.sin(a)*r, life:28, t:0, sz:1.3+Math.random()*1.5, rot:Math.random()*6.28, hue:(tick*4+Math.random()*100)%360|0, sapping:false}); }
      // each star saps HP from the nearest Mumu it's near
      for(const st of f.stars){ st.t++; let tgt=null,bd=1e9; for(const e of enemies){ const d=(e.x-st.x)**2+(e.y-st.y)**2; if(d<bd){ bd=d; tgt=e; } }
        if(tgt && bd<34*34){ tgt.hp-=0.5; tgt.flash=Math.max(tgt.flash,2); st.sapX=tgt.x; st.sapY=tgt.y; st.sapping=true; if(tgt.hp<=0) killEnemy(tgt); } else st.sapping=false; }
      f.stars=f.stars.filter(s=>s.t<s.life);
    }
  }
  fx=fx.filter(f=> f.type==='wave'? f.alive!==false : (!f._dead && f.t>0));
  enemies=enemies.filter(e=>e.hp>0);
}
