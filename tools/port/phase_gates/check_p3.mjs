#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
let fail=0; const ok=(c,m)=>{ if(c) console.log('  ✓',m); else { console.log('  ✗',m); fail++; } };
const r=p=>fs.readFileSync(path.join(ROOT,p),'utf8');
const fx=r('godot/scripts/render/drawers/drawCombatFx.gd');
const bob=r('godot/scripts/player/BobinaSprite.gd');
const layer=r('godot/scripts/render/FxLayer.gd');
console.log('Gate P3: combat entity/visual drawers\n');
for (const f of ['draw_melee_weapon','draw_power_aura','draw_dash_comet','pose_params','draw_pose_prop','draw_power_radiance','draw_options','coffee_hold'])
  ok(fx.includes(`func ${f}`), `drawCombatFx.${f}`);
ok(bob.includes('draw_power_aura') && bob.includes('draw_options'), 'BobinaSprite wires aura+options');
ok(bob.includes('draw_dash_comet'), 'BobinaSprite dash comet');
ok(layer.includes('get_swipe_fx') || layer.includes('draw_melee_weapon'), 'FxLayer melee swipe');
ok(r('godot/scripts/player/Player.gd').includes('trail'), 'player dash trail');
const fmap=JSON.parse(r('tools/port/function_map.json'));
const todo=Object.entries(fmap).filter(([,v])=>v.phase===3 && v.status!=='ported');
ok(todo.length===0, `P3 map todos=0 (got ${todo.length})`);
if(fail){ console.log('\nGate P3: FAIL'); process.exit(1);} console.log('\nGate P3: PASS');
