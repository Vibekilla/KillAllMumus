#!/usr/bin/env node
/** Phase 4 — Mechanics structure */
import { createGate, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 4 — Mechanics structure");

g.ok(exists("godot/scripts/combat/CombatHelpers.gd"), "CombatHelpers.gd");
g.ok(exists("godot/scripts/combat/FireSystem.gd"), "FireSystem.gd");
g.ok(exists("godot/scripts/systems/MeleeSystem.gd"), "MeleeSystem.gd");
g.ok(exists("godot/scripts/systems/SpecialSystem.gd"), "SpecialSystem.gd");
g.ok(exists("godot/scripts/systems/ItemSystem.gd"), "ItemSystem.gd");
g.ok(exists("godot/scripts/systems/EmblemSystem.gd"), "EmblemSystem.gd");
g.ok(exists("godot/scripts/systems/ConsumableSystem.gd"), "ConsumableSystem.gd");
g.ok(exists("godot/scripts/stages/StageFlow.gd"), "StageFlow.gd");
g.ok(exists("godot/autoload/ProgressStore.gd"), "ProgressStore.gd");
g.ok(exists("godot/autoload/GameState.gd"), "GameState.gd");

const ch = read("godot/scripts/combat/CombatHelpers.gd");
for (const f of ["threat_mul", "score_mult", "shot_level", "add_power", "burst"]) {
  g.ok(ch.includes(`func ${f}`), `CombatHelpers.${f}`);
}

const gs = read("godot/autoload/GameState.gd");
g.ok(gs.includes("0.00085"), "power bleed 0.00085");

const fire = read("godot/scripts/combat/FireSystem.gd");
for (const w of ["laser", "homing", "gatling", "voidripper", "lotus", "shock"]) {
  g.ok(fire.includes(w), `FireSystem weapon ${w}`);
}

const sf = read("godot/scripts/stages/StageFlow.gd");
for (const f of ["spawn_clear_gate", "enter_shop", "on_boss_defeated", "advance_screen"]) {
  g.ok(sf.includes(`func ${f}`), `StageFlow.${f}`);
}

const ps = read("godot/autoload/ProgressStore.gd");
for (const f of ["outfit_unlocked", "unlock_emblem", "reset_inventory", "on_game_cleared"]) {
  g.ok(ps.includes(`func ${f}`), `ProgressStore.${f}`);
}

const proj = read("godot/project.godot");
g.ok(proj.includes("CombatHelpers="), "CombatHelpers autoload");
g.ok(proj.includes("StageFlow="), "StageFlow autoload");

g.finish();
