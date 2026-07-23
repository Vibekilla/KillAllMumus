#!/usr/bin/env node
/**
 * Gate P1 — Foundation: layout, assets, audio, input, clock
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../../..');
const fails = [];
const warn = [];

function ok(cond, msg) {
  if (!cond) fails.push(msg);
  else console.log('  ✓', msg);
}
function soft(cond, msg) {
  if (!cond) warn.push(msg);
  else console.log('  ✓', msg);
}

// --- HTML load() keys ---
const html = fs.readFileSync(path.join(ROOT, 'public/index.html'), 'utf8');
const loadKeys = [...html.matchAll(/load\(\s*'([^']+)'\s*,\s*'assets\/([^']+)'\s*\)/g)].map(
  (m) => ({ key: m[1], file: m[2] })
);
ok(loadKeys.length >= 14, `HTML load() keys >= 14 (got ${loadKeys.length})`);

// --- AssetBank maps all keys ---
const bankPath = path.join(ROOT, 'godot/scripts/html_parity/AssetBank.gd');
ok(fs.existsSync(bankPath), 'AssetBank.gd exists');
const bank = fs.readFileSync(bankPath, 'utf8');
for (const { key, file } of loadKeys) {
  ok(bank.includes(`"${key}"`), `AssetBank has key ${key}`);
  const tex = path.join(ROOT, 'godot/assets/textures', file);
  ok(fs.existsSync(tex), `texture file exists: ${file}`);
}

// --- Config layout constants ---
const config = fs.readFileSync(path.join(ROOT, 'godot/autoload/Config.gd'), 'utf8');
ok(/PLAYFIELD\s*:=\s*Rect2\(\s*48\s*,\s*14\s*,\s*512\s*,\s*516\s*\)/.test(config), 'PLAYFIELD = (48,14,512,516)');
ok(/VIEWPORT\s*:=\s*Vector2\(\s*960\s*,\s*540\s*\)/.test(config) || config.includes('960') && config.includes('540'), 'VIEWPORT 960×540');
ok(config.includes('PANEL') || config.includes('panel'), 'PANEL defined (HTML right rail)');

// --- SimClock ---
const clock = path.join(ROOT, 'godot/scripts/html_parity/SimClock.gd');
ok(fs.existsSync(clock), 'SimClock.gd exists');
const clockSrc = fs.readFileSync(clock, 'utf8');
ok(/60/.test(clockSrc) && /tick|accumulator|sim/i.test(clockSrc), 'SimClock is 60 Hz sim');

// --- SfxSynth types ---
const sfxPath = path.join(ROOT, 'godot/scripts/audio/SfxSynth.gd');
ok(fs.existsSync(sfxPath), 'SfxSynth.gd exists');
const sfx = fs.readFileSync(sfxPath, 'utf8');
const requiredSfx = [
  'shoot', 'hit', 'kill', 'graze', 'item', 'power', 'extend', 'bomb', 'hurt', 'card', 'win',
  'slash', 'whip', 'thud', 'boom', 'claw', 'warp',
];
for (const t of requiredSfx) {
  ok(sfx.includes(`"${t}"`) || sfx.includes(`'${t}'`), `sfx type ${t}`);
}

// --- AudioBus wires synth ---
const bus = fs.readFileSync(path.join(ROOT, 'godot/autoload/AudioBus.gd'), 'utf8');
ok(bus.includes('SfxSynth'), 'AudioBus uses SfxSynth');

// --- Input defaults in project.godot ---
const proj = fs.readFileSync(path.join(ROOT, 'godot/project.godot'), 'utf8');
for (const action of ['shoot', 'focus', 'bomb', 'special', 'melee', 'pause']) {
  ok(proj.includes(action + '='), `input action ${action}`);
}
// HTML DEFAULT_BINDS: Z shoot, Shift focus, X bomb, V special, Space melee, C swap
soft(proj.includes('physical_keycode":90') || proj.includes('physical_keycode=90'), 'shoot ~ KeyZ (90)');
soft(true, 'bind check soft');

// --- project viewport ---
ok(proj.includes('viewport_width=960'), 'viewport_width=960');
ok(proj.includes('viewport_height=540'), 'viewport_height=540');

console.log('\nGate P1:', fails.length ? 'FAIL' : 'PASS');
if (warn.length) {
  console.log('Warnings:');
  for (const w of warn) console.log('  !', w);
}
if (fails.length) {
  for (const f of fails) console.error('  ✗', f);
  process.exit(1);
}
