#!/usr/bin/env node
/**
 * Sync the pixel-perfect HTML client into public_godot/ so any "Godot web"
 * path can still serve the exact public/ game until the GDScript port is complete.
 *
 * Also keeps godot/assets in sync with public assets.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const PUB = path.join(ROOT, 'public');
const OUT = path.join(ROOT, 'public_godot');
const GTEX = path.join(ROOT, 'godot/assets/textures');
const GHTML = path.join(ROOT, 'godot/assets/html');

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(GTEX, { recursive: true });
fs.mkdirSync(GHTML, { recursive: true });

function cp(src, dest) {
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
}

function cpDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const name of fs.readdirSync(src)) {
    const s = path.join(src, name);
    const d = path.join(dest, name);
    if (fs.statSync(s).isDirectory()) cpDir(s, d);
    else cp(s, d);
  }
}

// Exact game client → public_godot (overwrites wasm build intentionally for parity mode)
const KEEP_WASM = process.env.KEEP_GODOT_WASM === '1';
if (!KEEP_WASM) {
  // Clear previous export except we fully replace with HTML client
  for (const name of fs.readdirSync(OUT)) {
    fs.rmSync(path.join(OUT, name), { recursive: true, force: true });
  }
  cp(path.join(PUB, 'index.html'), path.join(OUT, 'index.html'));
  for (const f of ['favicon.png', 'favicon-32.png', 'apple-touch-icon.png', 'og.png', 'share-over.png', 'share-win.png']) {
    const p = path.join(PUB, f);
    if (fs.existsSync(p)) cp(p, path.join(OUT, f));
  }
  cpDir(path.join(PUB, 'assets'), path.join(OUT, 'assets'));
  // Marker so health can distinguish
  fs.writeFileSync(
    path.join(OUT, 'CLIENT_MODE.json'),
    JSON.stringify(
      {
        mode: 'html-exact',
        note: 'Pixel-identical copy of public/ until GDScript 1:1 port completes',
        source: 'public/index.html',
        syncedAt: new Date().toISOString(),
      },
      null,
      2
    )
  );
}

// Always mirror assets into Godot project
cpDir(path.join(PUB, 'assets'), GTEX);
for (const f of ['favicon.png', 'favicon-32.png', 'apple-touch-icon.png', 'og.png', 'share-over.png', 'share-win.png']) {
  const p = path.join(PUB, f);
  if (fs.existsSync(p)) cp(p, path.join(GTEX, f));
}
cp(path.join(PUB, 'index.html'), path.join(GHTML, 'index.reference.html'));

// Extract fresh script for port tooling
execSync('node tools/port/full_extract.mjs', { cwd: ROOT, stdio: 'inherit' });
cp(path.join(ROOT, 'tools/port/extracted/game_script.js'), path.join(GHTML, 'game_script.reference.js'));


// Extract full GIF frame sequences for Godot AnimatedTexture parity (no placeholders)
import { execSync } from 'child_process';
function extractGifs() {
  const gifs = [
    { name: 'confused', src: path.join(PUB, 'assets/confused.gif'), fps: 15 },
    { name: 'leekspin', src: path.join(PUB, 'assets/leekspin.gif'), fps: 10 },
    { name: 'talk', src: path.join(PUB, 'assets/talk.gif'), fps: 24 },
  ];
  const root = path.join(ROOT, 'godot/assets/textures/gif_frames');
  fs.mkdirSync(root, { recursive: true });
  const meta = {};
  for (const g of gifs) {
    const dir = path.join(root, g.name);
    fs.mkdirSync(dir, { recursive: true });
    // clear old
    for (const f of fs.readdirSync(dir)) fs.unlinkSync(path.join(dir, f));
    execSync(`ffmpeg -y -i "${g.src}" -vsync 0 "${dir}/%04d.png"`, { stdio: 'pipe' });
    const frames = fs.readdirSync(dir).filter(f => f.endsWith('.png')).sort();
    meta[g.name] = {
      fps: g.fps,
      loop: true,
      src: 'assets/' + g.name + (g.name==='leekspin'?'.gif':'.gif'),
      frame_count: frames.length,
      frames: frames.map(f => `res://assets/textures/gif_frames/${g.name}/${f}`),
    };
  }
  // leekspin alias
  if (meta.leekspin) {
    // fps from duration
  }
  fs.writeFileSync(path.join(root, 'meta.json'), JSON.stringify(meta, null, 2));
  console.log('gif frames', Object.fromEntries(Object.entries(meta).map(([k,v]) => [k, v.frame_count])));
}
extractGifs();

console.log(
  JSON.stringify(
    {
      public_godot: KEEP_WASM ? 'kept-wasm' : 'html-exact',
      assets: fs.readdirSync(path.join(OUT, 'assets')).length,
      godotTextures: fs.readdirSync(GTEX).filter((x) => !x.endsWith('.import')).length,
    },
    null,
    2
  )
);
