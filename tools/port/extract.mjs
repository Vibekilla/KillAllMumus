#!/usr/bin/env node
/**
 * Extract structured data + function inventory from public/index.html
 * Usage: node tools/port/extract.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import vm from 'vm';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const HTML = fs.readFileSync(path.join(ROOT, 'public/index.html'), 'utf8');
const OUT = path.join(ROOT, 'tools/port/extracted');
const DATA = path.join(ROOT, 'godot/data');
fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(DATA, { recursive: true });

function extractBracket(src, startIdx) {
  const open = src[startIdx];
  const close = open === '[' ? ']' : '}';
  let depth = 0;
  for (let i = startIdx; i < src.length; i++) {
    const c = src[i];
    if (c === '"' || c === "'" || c === '`') {
      const q = c;
      i++;
      while (i < src.length) {
        if (src[i] === '\\') {
          i += 2;
          continue;
        }
        if (src[i] === q) break;
        i++;
      }
      continue;
    }
    if (c === open) depth++;
    else if (c === close) {
      depth--;
      if (depth === 0) return src.slice(startIdx, i + 1);
    }
  }
  throw new Error('unbalanced at ' + startIdx);
}

function extractConst(name) {
  const re = new RegExp(`const ${name}\\s*=\\s*([\\[\\{])`);
  const m = HTML.match(re);
  if (!m) return null;
  const idx = m.index + m[0].length - 1;
  return extractBracket(HTML, idx);
}

function evalExpr(expr) {
  // Strip JS methods that won't eval in isolation by wrapping in sandbox carefully
  const code = `"use strict";\n(${expr})`;
  try {
    return vm.runInNewContext(code, {}, { timeout: 5000 });
  } catch (e) {
    // Try as module-like with function stubs for datetime etc
    try {
      return vm.runInNewContext(
        `"use strict";\nconst datetime=()=>'now';\n(${expr})`,
        {},
        { timeout: 5000 }
      );
    } catch (e2) {
      console.warn('eval failed', e2.message.slice(0, 120));
      return null;
    }
  }
}

// --- Function inventory ---
const funcs = [];
const funcRe = /function\s+([A-Za-z_$][\w$]*)\s*\(/g;
let fm;
while ((fm = funcRe.exec(HTML))) {
  const name = fm[1];
  const line = HTML.slice(0, fm.index).split('\n').length;
  funcs.push({ name, line, index: fm.index });
}
// line ranges
for (let i = 0; i < funcs.length; i++) {
  const end = i + 1 < funcs.length ? funcs[i + 1].line : HTML.split('\n').length;
  funcs[i].endLine = end - 1;
  funcs[i].approxLines = funcs[i].endLine - funcs[i].line + 1;
}
fs.writeFileSync(path.join(OUT, 'inventory.json'), JSON.stringify({ count: funcs.length, functions: funcs }, null, 2));

// --- Named consts ---
const constNames = [
  'OUTFITS',
  'OUTFIT_EMOJI',
  'OUTFIT_COLORS',
  'STAGES',
  'RANKS',
  'WEAPONS',
  'WEAPON_ORDER',
  'SPECIALS',
  'MELEE',
  'BOMBS',
  'EMBLEMS',
  'CONSUMABLES',
  'OUTFIT_POSES',
];

const extracted = {};
for (const name of constNames) {
  const raw = extractConst(name);
  if (!raw) {
    console.warn('missing const', name);
    continue;
  }
  fs.writeFileSync(path.join(OUT, `${name}.js.txt`), raw);
  const val = evalExpr(raw);
  if (val != null) {
    extracted[name] = val;
    fs.writeFileSync(path.join(OUT, `${name}.json`), JSON.stringify(val, null, 2));
  } else {
    console.warn('could not eval', name);
  }
}

// Balance constants via regex
const balance = {};
for (const [k, re] of [
  ['MAX_LIVES', /const MAX_LIVES\s*=\s*(\d+)/],
  ['MAX_BOMBS', /const MAX_BOMBS\s*=\s*(\d+)/],
  ['KILL_EXTEND', /const KILL_EXTEND\s*=\s*(\d+)/],
  ['MAX_NG', /const MAX_NG\s*=\s*(\d+)/],
  ['YT_ID', /const YT_ID\s*=\s*'([^']+)'/],
]) {
  const m = HTML.match(re);
  if (m) balance[k] = isNaN(m[1]) ? m[1] : Number(m[1]);
}
const ext = HTML.match(/const EXTEND_SCORES\s*=\s*(\[[^\]]+\])/);
if (ext) balance.EXTEND_SCORES = evalExpr(ext[1]);
fs.writeFileSync(path.join(OUT, 'balance.json'), JSON.stringify(balance, null, 2));
fs.writeFileSync(path.join(DATA, 'balance.json'), JSON.stringify(balance, null, 2));

// Write godot/data copies
function writeData(file, data) {
  fs.writeFileSync(path.join(DATA, file), JSON.stringify(data, null, 2));
}

if (extracted.STAGES) writeData('stages.json', { stages: extracted.STAGES });
if (extracted.WEAPONS) writeData('weapons.json', extracted.WEAPONS);
if (extracted.SPECIALS) writeData('specials.json', extracted.SPECIALS);
if (extracted.MELEE) writeData('melee.json', extracted.MELEE);
if (extracted.BOMBS) writeData('bombs.json', extracted.BOMBS);
if (extracted.EMBLEMS) writeData('emblems.json', extracted.EMBLEMS);
if (extracted.CONSUMABLES) writeData('consumables.json', extracted.CONSUMABLES);
if (extracted.RANKS) writeData('ranks.json', extracted.RANKS);
if (extracted.WEAPON_ORDER) writeData('weapon_order.json', extracted.WEAPON_ORDER);

if (extracted.OUTFITS) {
  const outfits = extracted.OUTFITS.map((o) => ({
    ...o,
    emoji: extracted.OUTFIT_EMOJI?.[o.key],
    colors: extracted.OUTFIT_COLORS?.[o.key],
  }));
  writeData('outfits.json', {
    outfits,
    poses: extracted.OUTFIT_POSES || [],
    emoji: extracted.OUTFIT_EMOJI || {},
    colors: extracted.OUTFIT_COLORS || {},
  });
}

// Function map stub for verify
const map = {};
for (const f of funcs) {
  map[f.name] = {
    htmlLine: f.line,
    htmlEnd: f.endLine,
    godot: null,
    status: 'todo',
  };
}
// Known scaffold mappings
const known = {
  applyLayout: 'godot/scripts/main/Main.gd',
  loop: 'godot/scripts/main/Main.gd',
  simStep: 'godot/scripts/main/Main.gd',
  fire: 'godot/scripts/player/Player.gd',
  useSpecial: 'godot/scripts/systems/SpecialSystem.gd',
  doMeleeSwipe: 'godot/scripts/systems/MeleeSystem.gd',
  doBomb: 'godot/scripts/player/Player.gd',
  spawnBoss: 'godot/scripts/enemies/bosses/BossController.gd',
  drawBobina: 'godot/scripts/player/BobinaRenderer.gd',
  drawBoss: 'godot/scripts/enemies/bosses/BossDrawer.gd',
  drawMumu: 'godot/scripts/enemies/MumuDrawer.gd',
  loadStage: 'godot/scripts/stages/StageController.gd',
  drawShop: 'godot/scripts/ui/ShopUI.gd',
  drawLeaderboard: 'godot/scripts/ui/LeaderboardUI.gd',
  drawArsenal: 'godot/scripts/ui/ArsenalUI.gd',
  drawEmblems: 'godot/scripts/ui/EmblemsUI.gd',
  drawOutfits: 'godot/scripts/ui/OutfitsUI.gd',
  drawNgSelect: 'godot/scripts/ui/NgSelectUI.gd',
  sfx: 'godot/autoload/AudioBus.gd',
  submitScore: 'godot/autoload/ApiClient.gd',
};
for (const [k, v] of Object.entries(known)) {
  if (map[k]) {
    map[k].godot = v;
    map[k].status = 'mapped';
  }
}
fs.writeFileSync(path.join(ROOT, 'tools/port/function_map.json'), JSON.stringify(map, null, 2));

const todo = Object.values(map).filter((x) => x.status === 'todo').length;
const mapped = Object.values(map).filter((x) => x.status === 'mapped').length;
console.log(
  JSON.stringify(
    {
      functions: funcs.length,
      mapped,
      todo,
      stages: extracted.STAGES?.length,
      emblems: extracted.EMBLEMS?.length,
      outfits: extracted.OUTFITS?.length,
      weapons: extracted.WEAPONS ? Object.keys(extracted.WEAPONS).length : 0,
      specials: extracted.SPECIALS?.length,
      melee: extracted.MELEE?.length,
      consumables: extracted.CONSUMABLES?.length,
    },
    null,
    2
  )
);
