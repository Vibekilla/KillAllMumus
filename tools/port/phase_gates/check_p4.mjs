#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
let fail=0; const ok=(c,m)=>{ if(c) console.log('  ✓',m); else { console.log('  ✗',m); fail++; } };
const r=p=>fs.readFileSync(path.join(ROOT,p),'utf8');
const ch=r('godot/scripts/combat/CombatHelpers.gd');
const fire=r('godot/scripts/combat/FireSystem.gd');
const html=r('public/index.html');
console.log('Gate P4: combat helpers + fire table\n');
ok(html.includes("p.focus?4:6")||html.includes('p.focus ? 4 : 6'), 'HTML fire cd');
ok(fire.includes('4.0 if focus else 6.0')||fire.includes('3.2 if wep == "grenade"'), 'FireSystem HTML cadence');
const fns=['threat_mul','score_mult','rank_index','power_cap','add_power','gain_life','shot_level','swap_weapon','cycle_special','burst','pop','sparks','ang_diff','lerp_angle','nearest_target','aim_angle','body_ctr','check_extend'];
for (const f of fns) ok(ch.includes(`func ${f}`), `CombatHelpers.${f}`);
ok(r('godot/project.godot').includes('CombatHelpers='), 'CombatHelpers autoload');
ok(r('godot/scripts/enemies/EnemyBase.gd').includes('ItemSystem.kill_enemy') || r('godot/scripts/enemies/EnemyBase.gd').includes('CombatHelpers.burst'), 'enemy death → kill/loot path');
ok(r('godot/scripts/player/Player.gd').includes('CombatHelpers.swap_weapon'), 'player swap uses helper');
const fmap=JSON.parse(r('tools/port/function_map.json'));
const todo=Object.entries(fmap).filter(([,v])=>v.phase===4 && v.status!=='ported');
ok(todo.length===0, `P4 map todos=0 (got ${todo.length}: ${todo.map(x=>x[0]).slice(0,6)})`);
// weapons still present
for (const w of ['laser','homing','gatling','voidripper','lotus','shock']) ok(fire.includes(w), `weapon ${w}`);
if(fail){ console.log('\nGate P4: FAIL'); process.exit(1);} console.log('\nGate P4: PASS');
