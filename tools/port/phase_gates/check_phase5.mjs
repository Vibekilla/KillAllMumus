#!/usr/bin/env node
/** Phase 5 — Audio structure */
import { createGate, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 5 — Audio structure");

g.ok(exists("godot/scripts/audio/SfxSynth.gd"), "SfxSynth.gd");
g.ok(exists("godot/autoload/AudioBus.gd"), "AudioBus.gd");
g.ok(exists("godot/scripts/audio/MusicBridge.gd"), "MusicBridge.gd");

const sfx = read("godot/scripts/audio/SfxSynth.gd");
const required = [
  "shoot", "hit", "kill", "graze", "item", "power", "extend", "bomb", "hurt", "card", "win",
  "slash", "whip", "thud", "boom", "claw", "warp",
];
// HTML has 16 types; list may be 16+ aliases
let found = 0;
for (const t of required) {
  if (sfx.includes(`"${t}"`) || sfx.includes(`'${t}'`)) found++;
  else g.soft(false, `sfx type ${t}`);
}
g.ok(found >= 14, `sfx types present >= 14 (got ${found})`);

const bus = read("godot/autoload/AudioBus.gd");
g.ok(bus.includes("SfxSynth"), "AudioBus → SfxSynth");

const music = read("godot/scripts/audio/MusicBridge.gd");
g.ok(music.includes("play") || music.includes("YouTube") || music.includes("lofi") || music.includes("JavaScriptBridge"), "MusicBridge web path");

const proj = read("godot/project.godot");
g.ok(proj.includes("MusicBridge=") || proj.includes("AudioBus="), "audio autoloads");

g.finish();
