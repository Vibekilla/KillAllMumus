#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../../..');
let fail = 0;
const ok = (c, m) => { if (c) console.log('  ✓', m); else { console.log('  ✗', m); fail++; } };
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');
const html = read('public/index.html');
const p2 = read('godot/scripts/ui/menu/P2Meta.gd');
const end = read('godot/scripts/ui/EndScreen.gd');
const title = read('godot/scripts/ui/TitleScreen.gd');
const menus = read('godot/scripts/ui/menu/draw_menus.gd');
const proj = read('godot/project.godot');

console.log('Gate P2: full canvas menus + meta 1:1\n');

// Drawers
for (const fn of ['drawTitle','drawOutfits','drawEmblems','drawNgSelect','drawArsenal','drawLeaderboard']) {
  ok(html.includes(`function ${fn}`), `HTML ${fn}`);
}
ok(menus.includes('func draw_outfits') && menus.includes('func draw_arsenal'), 'canvas menu drawers');
ok(title.includes('menus.draw_outfits') || title.includes('draw_outfits'), 'title host menus');

// Meta helpers
const metaFns = [
  'tweet_result','submit_score','toggle_arsenal','new_run','move_arsenal','apply_diff',
  'save_arsenal','armed_spec','add_weapon','add_special','add_melee','add_bomb','diff_name',
  'init_player','fetch_lb','lb_is_mine','unequip_arsenal','ars_item_by_key','em_page_count',
  'show_name_entry_or_submit','do_save_score','open_shoutouts'
];
for (const f of metaFns) ok(p2.includes(`func ${f}`), `P2Meta.${f}`);
ok(proj.includes('P2Meta='), 'P2Meta autoload');

// End screens canvas
ok(end.includes('_draw_win') && end.includes('_draw_game_over'), 'canvas win/gameover');
ok(end.includes('_draw_share_btn') && end.includes('tweet_result'), 'share → tweet');
ok(end.includes('name_entry') || end.includes('NameEntry') || end.includes('handle_edit'), 'name entry');
ok(end.includes('BOBO IS SAVED') && end.includes('GAME OVER'), 'end copy 1:1');

// Shoutouts
ok(title.includes('SHOUTOUTS') && title.includes('open_shoutouts'), 'shoutouts overlay');

// Run start parity
const gs = read('godot/autoload/GameState.gd');
ok(gs.includes('lives = 6') && gs.includes('power = 1.0'), 'newRun lives/power parity');

// Live legacy
ok(/html-legacy|CLIENT_MODE/.test(read('server.js')), 'server client-mode aware');

// function_map all phase 2 ported
const fmap = JSON.parse(read('tools/port/function_map.json'));
const p2todo = Object.entries(fmap).filter(([,v]) => v.phase===2 && v.status!=='ported');
ok(p2todo.length === 0, `function_map P2 todos=0 (got ${p2todo.length}: ${p2todo.map(x=>x[0]).slice(0,8).join(',')})`);

if (fail) { console.log(`\nGate P2: FAIL (${fail})`); process.exit(1); }
console.log('\nGate P2: PASS');
