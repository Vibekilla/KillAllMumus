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
g.ok(shot.includes("bobina_breath_") || shot.includes("breath_"), "dual breath ticks");
g.ok(shot.includes("menu_outfit_") || shot.includes("godot_menu_outfit_"), "dual full wardrobe via outfits menu");
g.ok(shot.includes("menu_outfit_anim_") || shot.includes("outfit_anim_"), "dual continuous outfit anims in menu");
const menus = read("godot/scripts/ui/menu/draw_menus.gd");
g.ok(menus.includes("fig_scale = 4.7") || menus.includes("fig_scale=4.7"), "outfit menu fig_scale 4.7 (HTML)");
g.ok(menus.includes("create_radial_gradient") || menus.includes("radial"), "outfit menu spotlight gradient");
g.ok(menus.includes("clip()"), "outfit menu stage clip like HTML");
g.ok(menus.includes("_draw_posed_figure") || menus.includes("draw_posed"), "outfit posed figure");
g.ok(shot.includes("godot_gif_talk") || shot.includes("gif_talk"), "dual talk GIF");
g.ok(shot.includes("godot_gif_confused") || shot.includes("gif_confused"), "dual confused GIF");
g.ok(shot.includes("outfit_pose = 5") || shot.includes("pose_i in [2, 3, 5]"), "dual coffee / This Is Fine pose");

const bank = read("godot/scripts/html_parity/AssetBank.gd");
g.ok(bank.includes("sim_tick") || bank.includes("sim_time"), "AssetBank GIF driven by SimClock");
g.ok(bank.includes("get_anim_tex") || bank.includes("ANIM"), "AssetBank anim frame API");

const fx = read("godot/scripts/render/drawers/drawCombatFx.gd");
g.ok(fx.includes("func poseParams"), "poseParams");
g.ok(fx.includes("func drawPoseProp"), "drawPoseProp");
g.ok(fx.includes("func coffeeHold"), "coffeeHold");

const html = read("public/index.html");
g.ok(html.includes("function drawBobina"), "HTML drawBobina still source");
g.ok(html.includes("function drawPosedFigure"), "HTML drawPosedFigure");

g.finish();
