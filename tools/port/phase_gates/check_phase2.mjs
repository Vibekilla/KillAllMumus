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
g.ok(/not\s+squee/.test(bob) || bob.includes("not squee"), "blink uses GDScript not squee (not JS !)");
g.ok(bob.includes("selected_outfit") || bob.includes("outfit"), "outfit-aware");

const shot = read("godot/scripts/tools/screenshot_playtest.gd");
g.ok(shot.includes("godot_bobina_face_") || shot.includes("bobina_face"), "dual face shots");
g.ok(shot.includes("godot_bobina_pose_") || shot.includes("bobina_pose"), "dual pose shots");
g.ok(shot.includes("blink_open") && shot.includes("blink_closed"), "dual blink open/closed shots");

const fx = read("godot/scripts/render/drawers/drawCombatFx.gd");
g.ok(fx.includes("func poseParams"), "poseParams");
g.ok(fx.includes("func drawPoseProp"), "drawPoseProp");
g.ok(fx.includes("func coffeeHold"), "coffeeHold");

const menus = read("godot/scripts/ui/menu/draw_menus.gd");
g.ok(menus.includes("_draw_posed_figure") || menus.includes("draw_posed"), "outfit posed figure");

const html = read("public/index.html");
g.ok(html.includes("function drawBobina"), "HTML drawBobina still source");
g.ok(html.includes("function drawPosedFigure"), "HTML drawPosedFigure");

g.finish();
