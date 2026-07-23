#!/usr/bin/env node
/** Phase 1 — Performance foundation: WorldDraw, CanvasCompat, SimClock, cache hooks */
import { createGate, read, exists } from "./gate_lib.mjs";

const g = createGate("Phase 1 — Performance structure");

g.ok(exists("godot/scripts/html_parity/WorldDraw.gd"), "WorldDraw.gd");
g.ok(exists("godot/scripts/render/CanvasCompat.gd"), "CanvasCompat.gd");
g.ok(exists("godot/scripts/html_parity/SimClock.gd"), "SimClock.gd");
g.ok(exists("godot/autoload/FontBank.gd"), "FontBank.gd");
g.ok(exists("godot/scripts/html_parity/AssetBank.gd") || exists("godot/autoload/AssetBank.gd") || read("godot/project.godot").includes("AssetBank="), "AssetBank autoload");

const world = read("godot/scripts/html_parity/WorldDraw.gd");
g.ok(world.includes("CanvasCompat") || world.includes("ctx.bind"), "WorldDraw uses CanvasCompat");
g.ok(world.includes("queue_redraw") || world.includes("_draw"), "WorldDraw draws");
g.ok(world.includes("_last_tick") || world.includes("SimClock"), "WorldDraw tick-throttled redraw path");

const clock = read("godot/scripts/html_parity/SimClock.gd");
g.ok(/60/.test(clock), "SimClock 60 Hz");

const bob = read("godot/scripts/player/BobinaSprite.gd");
// Entity sprite must not own the full HTML drawBobina body (WorldDraw / menus do)
g.ok(bob.length < 8000 && !bob.includes("func drawBobina"), "BobinaSprite is not full drawBobina module");

// Performance cache module (Phase 1.1–1.2)
g.ok(exists("godot/scripts/render/BobinaDrawCache.gd"), "BobinaDrawCache.gd");
g.ok(exists("godot/scripts/render/BobinaBakeHost.gd"), "BobinaBakeHost.gd");
g.ok(read("godot/scripts/ui/TitleScreen.gd").includes("BobinaDrawCache"), "TitleScreen wires cache");
g.ok(read("godot/scripts/ui/menu/draw_menus.gd").includes("bobina_cache"), "draw_menus uses bobina_cache");
g.ok(world.includes("bobina_cache") && world.includes("get_play_texture"), "WorldDraw in-game Bobina cache");
g.ok(world.includes("% 3") || world.includes("% 3") || world.includes("%3"), "WorldDraw non-combat throttle");
g.ok(exists("godot/scripts/render/StageBgDrawCache.gd"), "StageBgDrawCache.gd");
g.ok(exists("godot/scripts/render/StageBgBakeHost.gd"), "StageBgBakeHost.gd");
g.ok(world.includes("stage_bg_cache") && world.includes("get_texture"), "WorldDraw stage bg cache blit");
g.ok(exists("godot/scripts/tools/fps_probe.gd"), "fps_probe.gd for Phase 1.4");

const proj = read("godot/project.godot");
g.ok(proj.includes("viewport_width=960") && proj.includes("viewport_height=540"), "viewport 960×540");

g.finish();
