#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
let fail=0; const ok=(c,m)=>{if(c)console.log('  ✓',m);else{console.log('  ✗',m);fail++;}};
const r=p=>fs.readFileSync(path.join(ROOT,p),'utf8');
const hud=r('godot/scripts/ui/menu/draw_hud.gd');
const hc=r('godot/scripts/ui/HudCanvas.gd');
console.log('Gate P7: HUD panel / ambience / toasts\n');
for (const f of ['draw_panel','draw_stage_bg','draw_stage_bg_fx','draw_boss_ambience','draw_emblem_toasts','draw_phase_veil','draw_slowmo_fx','draw_hell_portal','draw_pause_overlay'])
  ok(hud.includes(`func ${f}`), `draw_hud.${f}`);
ok(hc.includes('draw_panel') && hc.includes('draw_stage_bg'), 'HudCanvas wires panel+bg');
ok(r('godot/autoload/ProgressStore.gd').includes('emblem_toasts'), 'emblem toast queue');
ok(r('godot/scenes/main/Main.tscn').includes('HudCanvas'), 'Main has HudCanvas');
ok(r('godot/scripts/ui/HUD.gd').includes('visible = false')||r('godot/scripts/ui/HUD.gd').includes('superseded')||r('godot/scripts/ui/HUD.gd').includes('HudCanvas'), 'label HUD cedes');
const fmap=JSON.parse(r('tools/port/function_map.json'));
const todo=Object.entries(fmap).filter(([,v])=>v.phase===7&&v.status!=='ported');
ok(todo.length===0, `P7 map todos=0 (got ${todo.length})`);
if(fail){console.log('\nGate P7: FAIL');process.exit(1);} console.log('\nGate P7: PASS');
