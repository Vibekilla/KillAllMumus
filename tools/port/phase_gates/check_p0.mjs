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

console.log('\nGate P0:', fails.length ? 'FAIL' : 'PASS');
if (fails.length) {
  for (const f of fails) console.error('  ✗', f);
  process.exit(1);
}
