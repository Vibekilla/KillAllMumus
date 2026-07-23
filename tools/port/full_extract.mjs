#!/usr/bin/env node
/**
 * Extract every top-level function + major const data from public/index.html
 * into tools/port/extracted/ for 1:1 Godot port.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const HTML = fs.readFileSync(path.join(ROOT, 'public/index.html'), 'utf8');
const OUT = path.join(ROOT, 'tools/port/extracted');
const FUN = path.join(OUT, 'functions');
fs.mkdirSync(FUN, { recursive: true });

const scriptMatch = HTML.match(/<script>([\s\S]*)<\/script>\s*<\/body>/) || HTML.match(/<script>([\s\S]*)<\/script>/);
if (!scriptMatch) throw new Error('no script');
const SCRIPT = scriptMatch[1];
fs.writeFileSync(path.join(OUT, 'game_script.js'), SCRIPT);

// Top-level function extraction by next-function boundary
const starts = [];
const re = /(?:^|\n)function\s+([A-Za-z_$][\w$]*)\s*\(/g;
let m;
while ((m = re.exec(SCRIPT))) {
  starts.push({ name: m[1], index: m.index + (SCRIPT[m.index] === '\n' ? 1 : 0) });
}
// fix index: match may include leading newline
for (const s of starts) {
  const at = SCRIPT.indexOf('function ' + s.name, s.index > 0 ? s.index - 1 : 0);
  if (at >= 0) s.index = at;
}

const inventory = [];
for (let i = 0; i < starts.length; i++) {
  const { name, index } = starts[i];
  const end = i + 1 < starts.length ? starts[i + 1].index : SCRIPT.length;
  const body = SCRIPT.slice(index, end).replace(/\s+$/, '') + '\n';
  fs.writeFileSync(path.join(FUN, name + '.js'), body);
  inventory.push({ name, bytes: body.length, lines: body.split('\n').length });
}

// Const data blocks
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
  throw new Error('unbalanced');
}

const DATA_NAMES = [
  'STAGES',
  'WEAPONS',
  'WEAPON_ORDER',
  'SPECIALS',
  'MELEE',
  'BOMBS',
  'EMBLEMS',
  'OUTFITS',
  'OUTFIT_COLORS',
  'OUTFIT_EMOJI',
  'RANKS',
  'CONSUMABLES',
  'DEFAULT_BINDS',
  'FIXED_KMAP',
  'BIND_LIST',
  'MOUSE',
];

const dataMeta = {};
for (const name of DATA_NAMES) {
  const rx = new RegExp(`(?:const|let)\\s+${name}\\s*=\\s*([\\[\\{])`);
  const mm = SCRIPT.match(rx);
  if (!mm) {
    dataMeta[name] = null;
    continue;
  }
  const idx = mm.index + mm[0].length - 1;
  try {
    const expr = extractBracket(SCRIPT, idx);
    fs.writeFileSync(path.join(OUT, name + '.js.txt'), expr);
    dataMeta[name] = { bytes: expr.length };
  } catch (e) {
    dataMeta[name] = { error: e.message };
  }
}

// Also capture global init block (before first function after applyLayout)
const firstFn = starts[0]?.index ?? 0;
fs.writeFileSync(path.join(OUT, 'preamble.js'), SCRIPT.slice(0, firstFn));

fs.writeFileSync(
  path.join(OUT, 'full_inventory.json'),
  JSON.stringify(
    {
      functionCount: inventory.length,
      functions: inventory.sort((a, b) => b.lines - a.lines),
      data: dataMeta,
      scriptBytes: SCRIPT.length,
    },
    null,
    2
  )
);

console.log(
  JSON.stringify(
    {
      functions: inventory.length,
      totalLines: inventory.reduce((s, f) => s + f.lines, 0),
      dataOk: Object.values(dataMeta).filter((v) => v && !v.error).length,
    },
    null,
    2
  )
);
