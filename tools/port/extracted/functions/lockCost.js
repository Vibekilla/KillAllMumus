function lockCost(type, key){ if(FREE_CONTENT[type+':'+key]) return 0; return SHOP_COST[type+':'+key] || CONTENT_COST[type] || 30; }
// One-time migration: anyone with an existing save keeps every weapon/special/melee they previously had access to
// (under the old rules, everything except a handful of shop items was free). Fresh saves skip this and start locked.
(function(){ try{ if(localStorage.getItem('bobina_invmigrated')) return;
  const existing=['bobina_arsenal','bobina_emblems','bobina_estats','bobina_heads','bobina_nglevel','bobina_shopunlocks'].some(k=>{ const v=localStorage.getItem(k); return v && v!=='{}' && v!=='0' && v!=='null'; });
  if(existing){ const OLD_LOCKED={'w:lotus':1,'w:shock':1,'s:kraken':1,'s:void':1,'m:hammer':1};
    for(const k of WEAPON_ORDER) if(!OLD_LOCKED['w:'+k]) shopUnlocks['w:'+k]=true;
    for(const s of SPECIALS) if(!OLD_LOCKED['s:'+s.key]) shopUnlocks['s:'+s.key]=true;
    for(const m of MELEE) if(!OLD_LOCKED['m:'+m.key]) shopUnlocks['m:'+m.key]=true;
    saveShopUnlocks(); }
  localStorage.setItem('bobina_invmigrated','1');
}catch(e){} })();
// ---- CONSUMABLES: stored items you buy, carry, cycle with [A] and USE by tapping [Q] ----
const CONSUMABLES=[
  { key:'honeycomb', name:'Honeycomb',  icon:'🍯', col:'#ffcf5a', cost:16, desc:'Restore 1 heart.',   full:()=>!!run && run.lives>=MAX_LIVES, apply:()=>{ if(run) run.lives=Math.min(MAX_LIVES, (run.lives|0)+1); } },
  { key:'bulltears', name:'Bull Tears',  icon:'💧', col:'#8fd0ff', cost:12, desc:'Fill 10% power.',    full:()=>!!run && run.power>=powerCap(), apply:()=>{ if(run) run.power=Math.min(powerCap(), (+run.power||1)+0.5); } },   // power range is 1→6 (five tiers, span 5); cap lowers on HARD/HELL
  { key:'bullsouls', name:'Bull Souls',  icon:'🔮', col:'#b98cff', cost:28, desc:'Fill 30% power.',    full:()=>!!run && run.power>=powerCap(), apply:()=>{ if(run) run.power=Math.min(powerCap(), (+run.power||1)+1.5); } },
  { key:'galaxygas', name:'Galaxy Gas',  icon:'🌌', col:'#9d6bff', cost:56, desc:'Fill 75% power.',    full:()=>!!run && run.power>=powerCap(), apply:()=>{ if(run) run.power=Math.min(powerCap(), (+run.power||1)+3.75); },
    draw:(s)=>{ const u=s/24; ctx.save(); ctx.scale(u,u);   // literal galaxy-in-a-jar (matches Honey Badger's shop ware)
      ctx.save(); ctx.beginPath(); ctx.roundRect(-7,-6,14,15,4); ctx.clip();   // swirling galaxy, clipped inside the glass
      const g=ctx.createRadialGradient(-1,3,0.4,-1,3,10); g.addColorStop(0,'#efe4ff'); g.addColorStop(0.32,'#9d6bff'); g.addColorStop(0.7,'#3a1a6a'); g.addColorStop(1,'#0a0618'); ctx.fillStyle=g; ctx.fillRect(-8,-7,16,17);
      ctx.strokeStyle='rgba(222,205,255,0.75)'; ctx.lineWidth=0.7; for(let arm=0;arm<2;arm++){ ctx.beginPath(); for(let t=0.2;t<3.2;t+=0.25){ const r=t*2.1, an=t*1.5+arm*Math.PI, x=-1+Math.cos(an)*r, y=3+Math.sin(an)*r*0.85; t<=0.2?ctx.moveTo(x,y):ctx.lineTo(x,y);} ctx.stroke(); }
      ctx.fillStyle='#fff'; for(const st of [[-4,-2,0.7],[3,5,0.6],[-3,6,0.5],[5,1,0.5],[1,-3,0.6],[-5,2,0.5],[2,2,0.4]]){ ctx.beginPath(); ctx.arc(st[0],st[1],st[2],0,7); ctx.fill(); }
      ctx.restore();
      ctx.strokeStyle='rgba(200,225,255,0.6)'; ctx.lineWidth=1; ctx.beginPath(); ctx.roundRect(-7,-6,14,15,4); ctx.stroke();   // glass
      ctx.strokeStyle='rgba(255,255,255,0.55)'; ctx.lineWidth=0.9; ctx.beginPath(); ctx.moveTo(-4.5,-3); ctx.lineTo(-4.5,5); ctx.stroke();   // highlight
      ctx.fillStyle='#cdb083'; ctx.beginPath(); ctx.roundRect(-8,-9.5,16,4,1.6); ctx.fill(); ctx.fillStyle='#e6cfa2'; ctx.beginPath(); ctx.roundRect(-5,-11,10,2.4,1); ctx.fill();   // lid
      ctx.restore(); } },
  { key:'clover',    name:'Clover',      icon:'🍀', col:'#7ed957', cost:25, desc:'Charge 25% special.', full:()=>!!run && (+run.special||0)>=100, apply:()=>{ if(run) run.special=Math.min(100, (+run.special||0)+25); } },
  { key:'bubbles',   name:'Bubbles',     icon:'🫧', col:'#8fd0ff', cost:30, desc:'I blow bubbles that trap Mumus, then pop them for AoE.', apply:()=>{ if(run&&player) spawnBubbles(); } },
  { key:'wagyu',     name:'Wagyu',       icon:'🥩', col:'#ff8aa0', cost:38, desc:'Restore 3 hearts.',   full:()=>!!run && run.lives>=MAX_LIVES, apply:()=>{ if(run) run.lives=Math.min(MAX_LIVES, (run.lives|0)+3); } },
  { key:'stardust',  name:'Stardust',    icon:'✨', col:'#ffe08a', cost:35, desc:'Questionable dust — stars spawn around me and sap power from nearby Mumus.', apply:()=>{ if(run&&player) spawnStardust(); } },
  { key:'vial',      name:'Unholy Vial',  icon:'🧪', col:'#9d6bff', cost:32, desc:'Void energy shields me from the next 3 bullets for 5s.', apply:()=>{ if(player){ player.vialHits=3; player.vialT=300; sfx('power'); flashMsg={t:80,txt:'🧪 UNHOLY VIAL — VOID WARD!'}; } } },
  { key:'banana',    name:'Banana',       icon:'🍌', col:'#ffd23a', cost:22, desc:'A quick snack — induces Monke’s Frenzy rapid fire.', apply:()=>{ if(player){ player.rapidT=Math.max(+player.rapidT||0,330); sfx('power'); flashMsg={t:80,txt:'🍌 MONKE’S FRENZY!'}; } } },
  { key:'wormhole',  name:'Wormhole',     icon:'🌀', col:'#7fdfff', cost:46, desc:'Phase into an alt reality for 3s — untouchable & no collision, but I still hurt Mumus.', apply:()=>{ if(player){ player.phaseT=180; sfx('warp'); screenShake=Math.max(screenShake||0,5); flashMsg={t:80,txt:'🌀 WORMHOLE — PHASED!'}; if(!Array.isArray(particles)) particles=[]; for(let i=0;i<24;i++) particles.push({x:player.x,y:player.y,vx:(Math.random()-.5)*10,vy:(Math.random()-.5)*10,life:26,c:i%2?'#7fdfff':'#b98cff'}); } } },
];
let consumInv=(()=>{ try{ const v=JSON.parse(localStorage.getItem('bobina_consum')||'{}'); return (v&&typeof v==='object'&&!Array.isArray(v))?v:{}; }catch(e){ return {}; } })();
try{ const a=JSON.parse(localStorage.getItem('bobina_arsenal')||'null'); if(a&&Array.isArray(a.i)) arsenalI=a.i.filter(k=>CONSUMABLES.some(c=>c.key===k)); }catch(e){}   // load persisted item loadout
if(!Array.isArray(arsenalI)) arsenalI=['honeycomb','bulltears','bullsouls'];
if(arsenalI.length>ARS_CAP.i) arsenalI=arsenalI.slice(0,ARS_CAP.i);
let selConsum=0, shopTab='w';
