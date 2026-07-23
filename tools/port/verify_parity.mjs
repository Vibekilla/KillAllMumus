#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const map = JSON.parse(fs.readFileSync(path.join(ROOT, 'tools/port/function_map.json'), 'utf8'));

// Gameplay-critical functions must be mapped
const CRITICAL = [
  'update',
  'draw',
  'fire',
  'useSpecial',
  'doMeleeSwipe',
  'doBomb',
  'doDash',
  'loadStage',
  'spawnBoss',
  'updateBoss',
  'bossSpecial',
  'drawBobina',
  'drawBoss',
  'drawMumu',
  'drawShop',
  'hitPlayer',
  'collectItem',
  'spawnLil',
  'spawnElite',
  'spawnBig',
  'onBossDefeated',
  'drawLeaderboard',
  'drawArsenal',
  'drawEmblems',
  'drawOutfits',
  'drawNgSelect',
];

const missing = [];
for (const name of CRITICAL) {
  const e = map[name];
  if (!e || e.status === 'todo' || !e.godot) missing.push(name);
  else if (e.godot && !fs.existsSync(path.join(ROOT, e.godot))) missing.push(name + ' (file missing: ' + e.godot + ')');
}

const dataChecks = {
  'godot/data/stages.json': (j) => (j.stages || j).length >= 7,
  'godot/data/emblems.json': (j) => (Array.isArray(j) ? j : j.emblems || []).length >= 40,
  'godot/data/outfits.json': (j) => (j.outfits || j).length >= 28,
  'godot/data/weapons.json': (j) => Object.keys(j).length >= 10,
  'godot/data/specials.json': (j) => j.length >= 10,
  'godot/data/melee.json': (j) => j.length >= 5,
  'godot/data/consumables.json': (j) => j.length >= 10,
};

const dataFail = [];
for (const [file, check] of Object.entries(dataChecks)) {
  const p = path.join(ROOT, file);
  if (!fs.existsSync(p)) {
    dataFail.push(file + ' missing');
    continue;
  }
  const j = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (!check(j)) dataFail.push(file + ' incomplete');
}

const total = Object.keys(map).length;
const mapped = Object.values(map).filter((x) => x.status === 'mapped' && x.godot).length;

console.log(
  JSON.stringify(
    {
      totalFunctions: total,
      mapped,
      unmapped: total - mapped,
      criticalMissing: missing,
      dataFail,
      pass: missing.length === 0 && dataFail.length === 0,
    },
    null,
    2
  )
);

if (missing.length || dataFail.length) process.exit(1);
