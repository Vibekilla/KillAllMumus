#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
let fail = 0;
const ok = (c, m) => { if (c) console.log('  ✓', m); else { console.log('  ✗', m); fail++; } };
const r = p => fs.readFileSync(path.join(ROOT, p), 'utf8');

console.log('Gate P8: progress / emblems meta / inventory / consumables\n');

const ps = r('godot/autoload/ProgressStore.gd');
const em = r('godot/scripts/systems/EmblemSystem.gd');
const cs = r('godot/scripts/systems/ConsumableSystem.gd');
const mh = r('godot/scripts/ui/menu/MenuHelpers.gd');
const pl = r('godot/scripts/player/Player.gd');
const gs = r('godot/autoload/GameState.gd');
const proj = r('godot/project.godot');
const shop = r('godot/scripts/systems/ShopSystem.gd');
const settings = r('godot/scripts/ui/SettingsMenu.gd');

// ProgressStore HTML APIs
for (const f of [
  'func has_emblem', 'func unlock_emblem', 'func save_emblems',
  'func save_estats', 'func save_heads', 'func save_consum', 'func save_shop_unlocks',
  'func content_unlocked', 'func lock_cost', 'func reset_inventory',
  'func on_game_cleared', 'func compute_emblems', 'func outfit_unlocked',
]) {
  ok(ps.includes(f), `ProgressStore.${f.replace('func ', '')}`);
}

ok(ps.includes('win_cabal_unlock'), 'ProgressStore.win_cabal_unlock');
ok(ps.includes('speedrun_hell'), 'on_game_cleared speedrun_hell');
ok(ps.includes('STARTER_ARSENAL') || ps.includes('bulltears'), 'starter arsenal includes items');
ok(ps.includes('honeycombs'), 'estats.honeycombs tracked');

// EmblemSystem tick
ok(em.includes('func tick_play'), 'EmblemSystem.tick_play');
ok(em.includes('full_power') && em.includes('life_8') && em.includes('max_lives'), 'emblemTick full set');
ok(em.includes('weapon_all') && em.includes('bride'), 'emblemTick weapon_all+bride');
ok(em.includes('func compute_emblems'), 'EmblemSystem.compute_emblems');

// ConsumableSystem 1:1
ok(cs.includes('func cycle'), 'ConsumableSystem.cycle');
ok(cs.includes('func consume_selected') || cs.includes('func use_selected'), 'ConsumableSystem.consume');
ok(cs.includes('HOLD_FRAMES') || cs.includes('48'), 'hold-to-use 0.8s');
ok(cs.includes('COOLDOWN_FRAMES') || cs.includes('180'), '3s cooldown');
ok(cs.includes('is_full') || cs.includes('Already maxed'), 'full-check skip waste');
ok(cs.includes('honeycomb_100'), 'honeycomb_100 emblem');
ok(cs.includes('arsenal_i') || cs.includes('arsenal'), 'cycle uses arsenalI slots');

// MenuHelpers delegates
ok(mh.includes('content_unlocked') && mh.includes('lock_cost'), 'MenuHelpers content/lock');
ok(mh.includes('reset_inventory'), 'MenuHelpers.reset_inventory');

// Player wiring
ok(pl.includes('item_switch'), 'Player item_switch');
ok(pl.includes('consumables.tick') || pl.includes('consumables.cycle'), 'Player consumable tick/cycle');
ok(pl.includes('vial_hits') || pl.includes('vial_t'), 'Player Unholy Vial fields');

// Inputs
ok(proj.includes('item_switch=') && proj.includes('item_use='), 'project.godot item_switch + item_use');

// GameState end_run hooks
ok(gs.includes('compute_emblems') && gs.includes('save_estats'), 'end_run compute+saveEstats');
ok(gs.includes('on_game_cleared'), 'end_run on_game_cleared');

// Shop uses lockCost / contentUnlocked
ok(shop.includes('lock_cost') && shop.includes('content_unlocked'), 'ShopSystem lock/content');

// Settings reset path
ok(settings.includes('reset_inventory'), 'SettingsMenu reset_inventory');

// EndScreen cabal toast
ok(r('godot/scripts/ui/EndScreen.gd').includes('win_cabal_unlock'), 'EndScreen cabal unlock');

const fmap = JSON.parse(r('tools/port/function_map.json'));
const todo = Object.entries(fmap).filter(([, v]) => v.phase === 8 && v.status !== 'ported');
ok(todo.length === 0, `P8 map todos=0 (got ${todo.length}: ${todo.map(x => x[0]).slice(0, 8)})`);

if (fail) { console.log('\nGate P8: FAIL'); process.exit(1); }
console.log('\nGate P8: PASS');
