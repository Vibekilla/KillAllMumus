#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
let fail=0; const ok=(c,m)=>{if(c)console.log('  ✓',m);else{console.log('  ✗',m);fail++;}};
const r=p=>fs.readFileSync(path.join(ROOT,p),'utf8');
const sf=r('godot/scripts/stages/StageFlow.gd');
const df=r('godot/scripts/ui/menu/draw_flow.gd');
const fu=r('godot/scripts/ui/FlowUI.gd');
console.log('Gate P6: stage flow / shop / portal\n');
for (const f of ['spawn_clear_gate','enter_portal','enter_shop','leave_shop','on_boss_defeated','advance_screen','start_dialog','twin_swap'])
  ok(sf.includes(`func ${f}`), `StageFlow.${f}`);
for (const f of ['draw_intro','draw_stage_clear','draw_clear_gate','draw_shop','draw_dialog'])
  ok(df.includes(`func ${f}`), `draw_flow.${f}`);
ok(fu.includes('StageFlow') && fu.includes('draw_shop'), 'FlowUI host');
ok(r('godot/scripts/stages/StageController.gd').includes('spawn_clear_gate'), 'boss → portal');
ok(r('godot/project.godot').includes('StageFlow='), 'StageFlow autoload');
ok(r('godot/scripts/ui/ShopUI.gd').includes('Superseded')||r('godot/scripts/ui/ShopUI.gd').includes('visible = false'), 'ShopUI cedes to canvas');
const fmap=JSON.parse(r('tools/port/function_map.json'));
const todo=Object.entries(fmap).filter(([,v])=>v.phase===6&&v.status!=='ported');
ok(todo.length===0, `P6 map todos=0 (got ${todo.length}: ${todo.map(x=>x[0]).slice(0,8)})`);
if(fail){console.log('\nGate P6: FAIL');process.exit(1);} console.log('\nGate P6: PASS');
