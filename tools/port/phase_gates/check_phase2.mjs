#!/usr/bin/env node
/** Phase 2 — Bobina animation structure */
import { createGate, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 2 — Bobina animation structure");

g.ok(exists("godot/scripts/render/drawers/drawBobina.gd"), "drawBobina.gd");
const bob = read("godot/scripts/render/drawers/drawBobina.gd");
g.ok(bob.includes("func drawBobina") || bob.includes("func draw_bobina"), "drawBobina entry");
for (const expr of ["uwu", "smile", "annoyed", "squee", "giggle"]) {
  g.ok(bob.includes(expr), `expression ${expr}`);
}
g.ok(bob.includes("% 230") || bob.includes("%230"), "blink period 230");
g.ok(bob.includes("selected_outfit") || bob.includes("outfit"), "outfit-aware");

const fx = read("godot/scripts/render/drawers/drawCombatFx.gd");
g.ok(fx.includes("func pose_params"), "pose_params");
g.ok(fx.includes("func draw_pose_prop"), "draw_pose_prop");
g.ok(fx.includes("func coffee_hold"), "coffee_hold");

const menus = read("godot/scripts/ui/menu/draw_menus.gd");
g.ok(menus.includes("_draw_posed_figure") || menus.includes("draw_posed"), "outfit posed figure");

const html = read("public/index.html");
g.ok(html.includes("function drawBobina"), "HTML drawBobina still source");
g.ok(html.includes("function drawPosedFigure"), "HTML drawPosedFigure");

g.finish();
