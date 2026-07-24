#!/usr/bin/env node
/** Phase 3 — Exhaustive visual systems structure (files + drawers wired) */
import fs from "fs";
import path from "path";
import { createGate, ROOT, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 3 — Visual systems structure");

// Data tables
for (const f of [
  "godot/data/weapons.json",
  "godot/data/specials.json",
  "godot/data/melee.json",
  "godot/data/outfits.json",
  "godot/data/emblems.json",
  "godot/data/stages.json",
  "godot/data/consumables.json",
]) {
  g.ok(exists(f), f);
}

const weapons = JSON.parse(read("godot/data/weapons.json"));
const wkeys = Object.keys(weapons.weapons || weapons);
g.ok(wkeys.length >= 10, `weapons >= 10 (got ${wkeys.length})`);
for (const w of ["laser", "homing", "gatling", "voidripper", "lotus", "shock", "spread", "wave", "scatter", "grenade"]) {
  g.soft(wkeys.includes(w) || JSON.stringify(weapons).includes(w), `weapon key ${w}`);
}

const specials = JSON.parse(read("godot/data/specials.json"));
const slist = Array.isArray(specials) ? specials : specials.specials || [];
g.ok(slist.length >= 10, `specials >= 10 (got ${slist.length})`);

const melee = JSON.parse(read("godot/data/melee.json"));
const mlist = Array.isArray(melee) ? melee : melee.melee || [];
g.ok(mlist.length >= 5, `melee >= 5 (got ${mlist.length})`);

// Drawers
const drawers = [
  "drawBobina.gd",
  "drawMumu.gd",
  "drawElite.gd",
  "drawPShot.gd",
  "drawBullet.gd",
  "drawCombatFx.gd",
  "drawItem.gd",
  "drawBoss.gd",
  "drawHoneyBadger.gd",
  "drawTitle.gd",
];
for (const d of drawers) {
  g.ok(exists(`godot/scripts/render/drawers/${d}`), `drawer ${d}`);
}

const world = read("godot/scripts/html_parity/WorldDraw.gd");
g.ok(world.includes("ported") || world.includes("PortedDraw") || world.includes("drawBobina"), "WorldDraw presents entities");
g.ok(world.includes("combat_fx") || world.includes("drawCombatFx"), "WorldDraw combat FX");

const fx = read("godot/scripts/render/drawers/drawCombatFx.gd");
for (const f of ["drawPowerAura", "drawDashComet", "drawPowerRadiance", "drawMeleeWeapon"]) {
  g.ok(fx.includes(`func ${f}`), `drawCombatFx.${f}`);
}

// AssetBank keys vs HTML load()
const bankPath = exists("godot/scripts/html_parity/AssetBank.gd")
  ? "godot/scripts/html_parity/AssetBank.gd"
  : "godot/autoload/AssetBank.gd";
if (exists(bankPath)) {
  const bank = read(bankPath);
  const html = read("public/index.html");
  const loadKeys = [...html.matchAll(/load\(\s*'([^']+)'\s*,\s*'assets\/([^']+)'\s*\)/g)];
  g.ok(loadKeys.length >= 12, `HTML load keys >= 12 (got ${loadKeys.length})`);
  for (const m of loadKeys.slice(0, 20)) {
    g.ok(bank.includes(`"${m[1]}"`), `AssetBank key ${m[1]}`);
    g.soft(fs.existsSync(path.join(ROOT, "godot/assets/textures", m[2])), `texture ${m[2]}`);
  }
}


// Phase 3 dual harness (product gate still port:dual --full)
const shotGd = exists("godot/scripts/tools/screenshot_playtest.gd")
  ? read("godot/scripts/tools/screenshot_playtest.gd")
  : "";
g.ok(shotGd.includes("godot_wep_") || shotGd.includes("wep_"), "dual weapon shots in playtest");
g.ok(shotGd.includes("godot_melee_") || shotGd.includes("melee_"), "dual melee shots in playtest");
g.ok(shotGd.includes("godot_special_") || shotGd.includes("special_"), "dual special shots in playtest");
g.ok(shotGd.includes("godot_aura_") || shotGd.includes("aura_power"), "dual aura shots in playtest");
g.ok(shotGd.includes("godot_items_grid") || shotGd.includes("items_grid"), "dual items grid in playtest");
g.ok(shotGd.includes("godot_elites_grid") || shotGd.includes("elites_grid"), "dual elites grid in playtest");
g.ok(shotGd.includes("godot_boss_") || shotGd.includes("BossScene"), "dual boss shots in playtest");
g.ok(world.includes("swipe_fx") || world.includes("melee.swipe") || world.includes("swipe_fx"), "WorldDraw merges MeleeSystem swipe_fx");
g.ok(world.includes("trail") && world.includes("power"), "WorldDraw passes trail+power for aura/dash dual");
const dual = read("tools/port/dual_playtest.mjs");
g.ok(dual.includes("setWeapon") || dual.includes("html_wep_"), "dual HTML weapon path");
g.ok(dual.includes("setMelee") || dual.includes("html_melee_"), "dual HTML melee path");
g.ok(dual.includes("setSpecial") || dual.includes("html_special_"), "dual HTML special path");
g.ok(dual.includes("setAura") || dual.includes("html_aura_"), "dual HTML aura path");
g.ok(dual.includes("dropItemsGrid") || dual.includes("html_items_grid"), "dual HTML items path");
g.ok(dual.includes("spawnElitesGrid") || dual.includes("html_elites_grid"), "dual HTML elites path");
g.ok(dual.includes("spawnBossPortrait") || dual.includes("html_boss_"), "dual HTML boss path");
g.ok(dual.includes("PLAYTEST_SHOTS") && dual.includes("--shots"), "dual --shots filter CLI");
g.ok(shotGd.includes("PLAYTEST_SHOTS") && shotGd.includes("_want"), "playtest honors PLAYTEST_SHOTS");

g.finish();

