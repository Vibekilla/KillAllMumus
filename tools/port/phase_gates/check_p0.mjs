#!/usr/bin/env node
/**
 * Gate P0 — Safety & harness
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../../..');
const fails = [];

function ok(cond, msg) {
  if (!cond) fails.push(msg);
  else console.log('  ✓', msg);
}

// 1. Inventory
const invPath = path.join(ROOT, 'tools/port/extracted/full_inventory.json');
ok(fs.existsSync(invPath), 'full_inventory.json exists');
const inv = JSON.parse(fs.readFileSync(invPath, 'utf8'));
ok(inv.functionCount >= 290, `functionCount >= 290 (got ${inv.functionCount})`);

// 2. Function map covers all
const mapPath = path.join(ROOT, 'tools/port/function_map.json');
ok(fs.existsSync(mapPath), 'function_map.json exists');
const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));
const mapNames = Object.keys(map);
ok(mapNames.length >= 290, `function_map entries >= 290 (got ${mapNames.length})`);
const invNames = new Set(inv.functions.map((f) => f.name));
const missing = [...invNames].filter((n) => !map[n]);
ok(missing.length === 0, `all inventory names mapped (missing ${missing.length})`);
const noPhase = mapNames.filter((n) => map[n].phase == null);
ok(noPhase.length === 0, 'every entry has phase');

// 3. Source of truth present
ok(fs.existsSync(path.join(ROOT, 'public/index.html')), 'public/index.html exists');
const assets = fs.readdirSync(path.join(ROOT, 'public/assets'));
ok(assets.length >= 17, `public/assets count >= 17 (got ${assets.length})`);

// 4. Live health (best-effort)
try {
  const health = execSync('curl -sS --max-time 3 http://127.0.0.1:3000/api/health', {
    encoding: 'utf8',
  });
  const j = JSON.parse(health);
  ok(j.ok === true, 'api health ok');
  ok(j.client === 'html-legacy', `client is html-legacy (got ${j.client})`);
} catch (e) {
  fails.push('api health unreachable: ' + e.message);
}

// 5. Canvas marker in HTML
const html = fs.readFileSync(path.join(ROOT, 'public/index.html'), 'utf8');
ok(html.includes('id="c"') || html.includes("id='c'"), 'HTML has canvas #c');
ok(html.includes('function drawBobina'), 'HTML has drawBobina');

// 6. Full-port ban list — no visual shortcuts / game wrappers in play path
const banRoots = [
  path.join(ROOT, 'godot/scripts'),
  path.join(ROOT, 'godot/autoload'),
];
const banPatterns = [
  { re: /_draw_fast\b/, msg: 'ban _draw_fast' },
  { re: /_draw_mini_bobina\b/, msg: 'ban _draw_mini_bobina' },
  { re: /Fast path:\s*native/i, msg: 'ban Fast path: native entity art' },
];
function walkGd(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walkGd(p, out);
    else if (name.endsWith('.gd')) out.push(p);
  }
  return out;
}
const gdFiles = banRoots.flatMap((r) => walkGd(r));
for (const { re, msg } of banPatterns) {
  const hits = [];
  for (const f of gdFiles) {
    const src = fs.readFileSync(f, 'utf8');
    if (re.test(src)) hits.push(path.relative(ROOT, f));
  }
  ok(hits.length === 0, `${msg}${hits.length ? ' in ' + hits.slice(0, 5).join(', ') : ''}`);
}
// Gameplay must not iframe HTML index
const shellCandidates = [
  path.join(ROOT, 'src'),
  path.join(ROOT, 'deploy'),
  path.join(ROOT, 'godot'),
].filter((d) => fs.existsSync(d));
let iframeHits = [];
function walkText(dir, out = [], depth = 0) {
  if (depth > 6 || !fs.existsSync(dir)) return out;
  for (const name of fs.readdirSync(dir)) {
    if (name === 'node_modules' || name === '.godot' || name === 'playtest_out') continue;
    const p = path.join(dir, name);
    let st;
    try { st = fs.statSync(p); } catch { continue; }
    if (st.isDirectory()) walkText(p, out, depth + 1);
    else if (/\.(gd|ts|tsx|js|mjs|html)$/.test(name)) out.push(p);
  }
  return out;
}
for (const f of shellCandidates.flatMap((d) => walkText(d))) {
  const src = fs.readFileSync(f, 'utf8');
  // iframe loading the live game HTML as the product (not YT music)
  if (/iframe[^>]+(?:index\.html|public\/index)/i.test(src) || /src=["']\/?(?:index\.html)["']/.test(src) && /iframe/i.test(src)) {
    iframeHits.push(path.relative(ROOT, f));
  }
}
ok(iframeHits.length === 0, `no gameplay iframe of index.html${iframeHits.length ? ': ' + iframeHits.join(', ') : ''}`);

// WorldDraw orchestrator present (modular single-pass)
ok(fs.existsSync(path.join(ROOT, 'godot/scripts/html_parity/WorldDraw.gd')), 'WorldDraw.gd exists');
const wd = fs.readFileSync(path.join(ROOT, 'godot/scripts/html_parity/WorldDraw.gd'), 'utf8');
ok(wd.includes('draw_bobina') || wd.includes('drawBobina'), 'WorldDraw calls full drawBobina path');
ok(wd.includes('draw_mumu') || wd.includes('draw_elite'), 'WorldDraw draws mumus via full drawers');

// Trebuchet MS shipped
const fontDir = path.join(ROOT, 'godot/assets/fonts');
const hasTreb =
  fs.existsSync(path.join(fontDir, 'TrebuchetMS.ttf')) ||
  fs.existsSync(path.join(fontDir, 'trebuc.ttf'));
ok(hasTreb, 'Trebuchet MS font file present under godot/assets/fonts');
const fontBank = fs.readFileSync(path.join(ROOT, 'godot/autoload/FontBank.gd'), 'utf8');
ok(/TrebuchetMS|trebuc/.test(fontBank), 'FontBank loads Trebuchet MS');

console.log('\nGate P0:', fails.length ? 'FAIL' : 'PASS');
if (fails.length) {
  for (const f of fails) console.error('  ✗', f);
  process.exit(1);
}
