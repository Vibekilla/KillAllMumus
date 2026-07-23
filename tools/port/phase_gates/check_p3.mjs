#!/usr/bin/env node
/**
 * Gate P3 — combat entity/visual drawers wired through WorldDraw (modular full drawers).
 * Entity nodes are sim/collision only; presentation is the single WorldDraw pass.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
let fail = 0;
const ok = (c, m) => {
  if (c) console.log('  ✓', m);
  else {
    console.log('  ✗', m);
    fail++;
  }
};
const r = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');

const fx = r('godot/scripts/render/drawers/drawCombatFx.gd');
const world = r('godot/scripts/html_parity/WorldDraw.gd');
const bob = r('godot/scripts/player/BobinaSprite.gd');
const bullet = r('godot/scripts/combat/Bullet.gd');
const enemy = r('godot/scripts/enemies/EnemyBase.gd');

console.log('Gate P3: combat entity/visual drawers (WorldDraw single-pass)\n');

for (const f of [
  'draw_melee_weapon',
  'draw_power_aura',
  'draw_dash_comet',
  'pose_params',
  'draw_pose_prop',
  'draw_power_radiance',
  'draw_options',
  'coffee_hold',
]) {
  ok(fx.includes(`func ${f}`), `drawCombatFx.${f}`);
}

// Full drawers live in modular modules; WorldDraw orchestrates them
ok(world.includes('draw_power_aura') && world.includes('draw_options'), 'WorldDraw wires aura+options');
ok(world.includes('draw_dash_comet'), 'WorldDraw dash comet');
ok(world.includes('draw_bobina') || world.includes('drawBobina'), 'WorldDraw full drawBobina');
ok(world.includes('draw_pshot') || world.includes('draw_bullet'), 'WorldDraw full bullet/pshot drawers');
ok(world.includes('draw_mumu') || world.includes('draw_elite'), 'WorldDraw full mumu/elite drawers');
ok(world.includes('draw_melee_fx'), 'WorldDraw melee FX');

// Entities must NOT own presentation
ok(/\bfunc _draw\b[\s\S]{0,120}\bpass\b/.test(bob) || bob.includes('WorldDraw'), 'BobinaSprite presentation deferred to WorldDraw');
ok(bullet.includes('WorldDraw') || /\bfunc _draw\b[\s\S]{0,80}\bpass\b/.test(bullet), 'Bullet presentation deferred to WorldDraw');
ok(enemy.includes('WorldDraw') || /\bfunc _draw\b[\s\S]{0,80}\bpass\b/.test(enemy), 'EnemyBase presentation deferred to WorldDraw');

ok(r('godot/scripts/player/Player.gd').includes('trail'), 'player dash trail');

const fmap = JSON.parse(r('tools/port/function_map.json'));
const todo = Object.entries(fmap).filter(([, v]) => v.phase === 3 && v.status !== 'ported');
ok(todo.length === 0, `P3 map todos=0 (got ${todo.length})`);

if (fail) {
  console.log('\nGate P3: FAIL');
  process.exit(1);
}
console.log('\nGate P3: PASS');
