#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
let fail=0; const ok=(c,m)=>{if(c)console.log('  ✓',m);else{console.log('  ✗',m);fail++;}};
const r=p=>fs.readFileSync(path.join(ROOT,p),'utf8');
const it=r('godot/scripts/systems/ItemSystem.gd');
const fx=r('godot/scripts/render/FxLayer.gd');
const di=r('godot/scripts/render/drawers/drawItem.gd');
console.log('Gate P5: loot/items/FX/kills\n');
for (const f of ['drop_item','drop_loot','drop_weapon','kill_enemy','collect_item','tick','kill_extend','check_extend_score','chain_lightning','nade_boom','enemy_explode','spawn_bubbles','spawn_stardust','add_burn','elite_hearts'])
  ok(it.includes(`func ${f}`), `ItemSystem.${f}`);
ok(di.includes('func drawItem'), 'drawItem');
ok(r('godot/scripts/render/drawers/drawBobo.gd').includes('func drawBobo'), 'drawBobo');
ok(r('godot/scripts/render/drawers/drawMech.gd').includes('func drawMech'), 'drawMech');
ok(fx.includes('ItemSystem.tick') && fx.includes('drawItem'), 'FxLayer items tick+draw');
ok(fx.includes('_draw_floater') && fx.includes('_draw_burn'), 'floaters+burns draw');
ok(r('godot/scripts/enemies/EnemyBase.gd').includes('ItemSystem.kill_enemy'), 'enemy kill path');
ok(r('godot/scripts/combat/Bullet.gd').includes('ItemSystem.nade_boom'), 'nade boom');
ok(r('godot/project.godot').includes('ItemSystem='), 'ItemSystem autoload');
const fmap=JSON.parse(r('tools/port/function_map.json'));
const todo=Object.entries(fmap).filter(([,v])=>v.phase===5&&v.status!=='ported');
ok(todo.length===0, `P5 map todos=0 (got ${todo.length})`);
if(fail){console.log('\nGate P5: FAIL');process.exit(1);} console.log('\nGate P5: PASS');
