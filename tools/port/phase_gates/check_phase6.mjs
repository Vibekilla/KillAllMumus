#!/usr/bin/env node
/** Phase 6 — UI overlays & meta structure */
import { createGate, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 6 — UI overlays structure");

const ui = [
  ["godot/scripts/ui/SettingsMenu.gd", "SettingsMenu"],
  ["godot/scripts/ui/PauseMenu.gd", "PauseMenu"],
  ["godot/scripts/ui/DisplayMenu.gd", "DisplayMenu"],
  ["godot/scripts/ui/KeybindsMenu.gd", "KeybindsMenu"],
  ["godot/scripts/ui/HelpCanvas.gd", "HelpCanvas"],
  ["godot/scripts/ui/SoundGate.gd", "SoundGate"],
  ["godot/scripts/ui/EndScreen.gd", "EndScreen"],
  ["godot/scripts/ui/TitleScreen.gd", "TitleScreen"],
  ["godot/scripts/ui/FlowUI.gd", "FlowUI"],
  ["godot/scripts/ui/HudCanvas.gd", "HudCanvas"],
];
for (const [p, name] of ui) g.ok(exists(p), name);

const menus = read("godot/scripts/ui/menu/draw_menus.gd");
for (const f of ["drawOutfits", "drawArsenal", "drawEmblems", "drawNgSelect", "drawLeaderboard"]) {
  g.ok(menus.includes(`func ${f}`), `menus.${f}`);
}

const flow = read("godot/scripts/ui/menu/draw_flow.gd");
for (const f of ["drawIntro", "drawStageClear", "drawShop", "drawDialog"]) {
  g.ok(flow.includes(`func ${f}`), `flow.${f}`);
}

const end = read("godot/scripts/ui/EndScreen.gd");
g.ok(end.includes("GAME OVER") && end.includes("BOBO IS SAVED"), "end screen copy");

const title = read("godot/scripts/ui/TitleScreen.gd");
g.ok(title.includes("drawTitle") || title.includes("title_drawer"), "title canvas drawer");

g.ok(exists("godot/scripts/ui/menu/OverlayTheme.gd"), "OverlayTheme (settings/pause chrome)");

g.finish();
