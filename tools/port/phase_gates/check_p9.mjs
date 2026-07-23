#!/usr/bin/env node
import fs from 'fs'; import path from 'path'; import { fileURLToPath } from 'url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
let fail = 0;
const ok = (c, m) => { if (c) console.log('  ✓', m); else { console.log('  ✗', m); fail++; } };
const r = p => fs.readFileSync(path.join(ROOT, p), 'utf8');

console.log('Gate P9: cloud progress / residual combat / cutover readiness (live stays html-legacy)\n');

const ps = r('godot/autoload/ProgressStore.gd');
const api = r('godot/autoload/ApiClient.gd');
const ch = r('godot/scripts/combat/CombatHelpers.gd');
const boss = r('godot/scripts/enemies/bosses/BossController.gd');
const pl = r('godot/scripts/player/Player.gd');
const p2 = r('godot/scripts/ui/menu/P2Meta.gd');
const ms = r('godot/scripts/systems/MeleeSystem.gd');
const cs = r('godot/scripts/systems/ConsumableSystem.gd');
const server = r('server.js');

// Cloud snapshot + merge
for (const f of [
  'func build_progress_snapshot', 'func apply_progress_snapshot',
  'func cloud_linked', 'func schedule_cloud_save', 'func cloud_pull_and_merge',
  'func save_ng_prefs', 'func cabal_unlocked', 'func emblem_count', 'func emblem_def',
]) {
  ok(ps.includes(f), `ProgressStore.${f.replace('func ', '')}`);
}
ok(api.includes('func pull_progress') && api.includes('func put_progress'), 'ApiClient pull/put progress');
ok(api.includes('func is_authenticated') || api.includes('authenticated'), 'ApiClient auth');

// Combat residuals
ok(ch.includes('func dash_land_explosion'), 'dash_land_explosion');
ok(ch.includes('func clear_wave_mobs'), 'clear_wave_mobs');
ok(ch.includes('func bullet_cancel_all') && ch.includes('func bullet_cancel_near'), 'bullet cancel');
ok(ch.includes('func boss_dmg_mul') && ch.includes('func boss_wep_mul'), 'boss mul');
ok(ch.includes('func rgb_hue') || ch.includes('func _rgb_hue'), 'rgb_hue');
ok(ch.includes('func shot_level_cap') && ch.includes('func power_gain_mul') && ch.includes('func diff_score_mul'), 'power/score helpers');
ok(ch.includes('func body_ctr'), 'body_ctr');
ok(pl.includes('dash_land_explosion'), 'Player wires dash land FX');

// Wynn hell sequence
ok(boss.includes('func start_wynn_hell'), 'start_wynn_hell');
ok(boss.includes('func _update_wynn_hell') || boss.includes('update_wynn_hell'), 'update_wynn_hell');
ok(boss.includes('hell_scale') || boss.includes('hell_t'), 'wynn hell state fields');

// Melee / consum / meta
ok(ms.includes('func melee_charge_fx') || ms.includes('meleeChargeFx'), 'melee_charge_fx');
ok(cs.includes('func consum_by_id') && cs.includes('func sel_consum_obj'), 'consum by id / sel');
ok(p2.includes('func hide_name_entry'), 'hide_name_entry');
ok(p2.includes('func arsenal_count'), 'arsenal_count');
ok(p2.includes('func melee_idx_list'), 'melee_idx_list');
ok(p2.includes('func joy_reset'), 'joy_reset');
ok(p2.includes('func apply_arsenal_to_run'), 'apply_arsenal_to_run');

// Live MUST remain html-legacy until explicit cutover
ok(server.includes("USE_GODOT === '1'") || server.includes('USE_GODOT'), 'server USE_GODOT opt-in only');
ok(server.includes('html-legacy'), 'server reports html-legacy');
const useGodotDefault = /const useGodot\s*=\s*true/.test(server) || /USE_GODOT\s*=\s*['"]1['"]/.test(server);
ok(!useGodotDefault, 'USE_GODOT not hard-coded on by default');

// function map clear
const fmap = JSON.parse(r('tools/port/function_map.json'));
const todo = Object.entries(fmap).filter(([, v]) => v.phase === 9 && v.status !== 'ported');
ok(todo.length === 0, `P9 map todos=0 (got ${todo.length}: ${todo.map(x => x[0]).slice(0, 10)})`);

// Overall residual todos across all phases (report only — hard-fail only if P9 fails)
const allTodo = Object.entries(fmap).filter(([, v]) => v.status !== 'ported');
console.log(`\n  · residual non-ported (any phase): ${allTodo.length}`);
if (allTodo.length) {
  const by = {};
  for (const [k, v] of allTodo) {
    by[v.phase] = (by[v.phase] || 0) + 1;
  }
  console.log('  · by phase:', JSON.stringify(by));
}

if (fail) { console.log('\nGate P9: FAIL'); process.exit(1); }
console.log('\nGate P9: PASS');
console.log('  note: live cutover still requires explicit USE_GODOT=1 after export QA');
