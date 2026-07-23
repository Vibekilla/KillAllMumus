#!/usr/bin/env node
/**
 * Public-first element inventory for true 1:1 HTML → Godot conversion.
 * Source of truth: public/index.html (+ public/assets).
 * Emits tools/port/ELEMENT_INVENTORY.json listing every draw*, IMG load, and icon
 * glyph, then maps each to a Godot path when known.
 *
 * Usage: node tools/port/inventory_public.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const htmlPath = path.join(root, "public/index.html");
const html = fs.readFileSync(htmlPath, "utf8");

const MAP = {
  drawBobina: "godot/scripts/render/drawers/drawBobina.gd",
  drawApe: "godot/scripts/render/drawers/drawApe.gd",
  drawRobotnik: "godot/scripts/render/drawers/drawRobotnik.gd",
  drawMumina: "godot/scripts/render/drawers/drawMumina.gd",
  drawLily: "godot/scripts/render/drawers/drawLily.gd",
  drawPolice: "godot/scripts/render/drawers/drawPolice.gd",
  drawBogdanoff: "godot/scripts/render/drawers/drawBogdanoff.gd",
  drawWynn: "godot/scripts/render/drawers/drawWynn.gd",
  drawDevil: "godot/scripts/render/drawers/drawDevil.gd",
  drawBoss: "godot/scripts/render/drawers/drawBoss.gd",
  drawPortraitBust: "godot/scripts/render/drawers/drawPortraitBust.gd",
  drawMumu: "godot/scripts/render/drawers/drawMumu.gd",
  drawElite: "godot/scripts/render/drawers/drawElite.gd",
  drawBullet: "godot/scripts/render/drawers/drawBullet.gd",
  drawPShot: "godot/scripts/render/drawers/drawPShot.gd",
  drawItem: "godot/scripts/render/drawers/drawItem.gd",
  drawFx: "godot/scripts/render/drawers/drawFx.gd",
  drawMeleeFx: "godot/scripts/render/drawers/drawMeleeFx.gd",
  drawMeleeWeapon: "godot/scripts/render/drawers/drawMeleeFx.gd + drawCombatFx.gd",
  drawStageBg: "godot/scripts/render/drawers/drawStageBg.gd",
  drawStageBgFx: "godot/scripts/render/drawers/drawStageBg.gd",
  drawBossAmbience: "godot/scripts/ui/menu/draw_hud.gd",
  drawTitle: "godot/scripts/render/drawers/drawTitle.gd",
  drawTitleBtn: "godot/scripts/render/drawers/drawTitle.gd",
  drawPanel: "godot/scripts/ui/menu/draw_hud.gd",
  drawPanelTouch: "godot/scripts/ui/menu/draw_hud.gd",
  drawPanelPortrait: "godot/scripts/ui/menu/draw_hud.gd",
  drawDialog: "godot/scripts/ui/menu/draw_flow.gd",
  drawShop: "godot/scripts/ui/menu/draw_flow.gd",
  drawIntro: "godot/scripts/ui/menu/draw_flow.gd",
  drawStageClear: "godot/scripts/ui/menu/draw_flow.gd",
  drawClearGate: "godot/scripts/ui/menu/draw_flow.gd",
  drawHoneyBadger: "godot/scripts/render/drawers/drawHoneyBadger.gd",
  drawBobo: "godot/scripts/render/drawers/drawBobo.gd",
  drawMech: "godot/scripts/render/drawers/drawMech.gd",
  drawPowerAura: "godot/scripts/render/drawers/drawCombatFx.gd",
  drawPowerRadiance: "godot/scripts/render/drawers/drawCombatFx.gd",
  drawDashComet: "godot/scripts/render/drawers/drawCombatFx.gd",
  drawOptions: "godot/scripts/render/drawers/drawCombatFx.gd",
  drawPoseProp: "godot/scripts/render/drawers/drawCombatFx.gd",
  drawHeart: "godot/scripts/ui/menu/draw_hud.gd",
  drawBurns: "godot/scripts/render/FxLayer.gd",
  drawFloater: "godot/scripts/render/FxLayer.gd",
  drawEmote: "godot/scripts/render/FxLayer.gd",
  drawStunStars: "godot/scripts/enemies/EnemyBase.gd",
  drawHellPortal: "godot/scripts/ui/menu/draw_hud.gd",
  drawPhaseVeil: "godot/scripts/ui/menu/draw_hud.gd",
  drawSlowmoFx: "godot/scripts/ui/menu/draw_hud.gd",
  drawPause: "godot/scripts/ui/menu/draw_hud.gd",
  drawGameOver: "godot/scripts/ui/EndScreen.gd",
  drawWin: "godot/scripts/ui/EndScreen.gd",
  drawLeaderboard: "godot/scripts/ui/menu/draw_menus.gd",
  drawEmblems: "godot/scripts/ui/menu/draw_menus.gd",
  drawOutfits: "godot/scripts/ui/menu/draw_menus.gd",
  drawOutfitFigure: "godot/scripts/ui/menu/draw_menus.gd",
  drawNgSelect: "godot/scripts/ui/menu/draw_menus.gd",
  drawArsenal: "godot/scripts/ui/menu/draw_menus.gd",
  drawShareBtn: "godot/scripts/ui/EndScreen.gd",
  drawMenuBtn: "godot/scripts/ui/menu/MenuHelpers.gd",
  drawEmblemToasts: "godot/scripts/ui/menu/draw_hud.gd",
  drawDebugLayer: "godot/scripts/ui/menu/draw_debug.gd",
  drawMaidDance: "godot/scripts/ui/EndScreen.gd",
  drawPosedFigure: "godot/scripts/render/drawers/drawCombatFx.gd",
  draw: "godot/scripts/main/Main.gd + FxLayer.gd + HudCanvas.gd + TitleScreen.gd (HTML draw() dispatch)",
  fire: "godot/scripts/combat/FireSystem.gd + drawers/fire.gd",
  limb: "godot/scripts/render/drawers/limb.gd",
  circle: "godot/scripts/render/drawers/circle.gd",
  pOrb: "godot/scripts/render/drawers/pOrb.gd + drawBobina",
  CanvasCompat: "godot/scripts/render/CanvasCompat.gd",
};

const funcs = [...html.matchAll(/function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/g)].map((m) => m[1]);
const drawFns = [...new Set(funcs.filter((f) => f.startsWith("draw") || ["limb", "circle", "pOrb", "fire"].includes(f)))].sort();
const loads = [...html.matchAll(/load\('([^']+)','([^']+)'\)/g)].map((m) => ({ key: m[1], src: m[2] }));
const icons = [...new Set([...html.matchAll(/icon:\s*'([^']+)'/g)].map((m) => m[1]))].sort();

function exists(rel) {
  if (!rel) return false;
  const first = rel.split(" + ")[0].trim();
  return fs.existsSync(path.join(root, first));
}

const drawEntries = drawFns.map((name) => {
  const mapped = MAP[name] || null;
  const onDisk = exists(mapped);
  return {
    html: name,
    godot: mapped,
    status: onDisk ? "mapped" : mapped ? "mapped_missing_file" : "UNMAPPED",
  };
});

const assetEntries = loads.map((L) => {
  const pub = path.join(root, "public", L.src);
  const tex = path.join(root, "godot/assets/textures", path.basename(L.src));
  return {
    key: L.key,
    public: L.src,
    public_ok: fs.existsSync(pub),
    godot_texture: fs.existsSync(tex) || fs.existsSync(path.join(root, "godot/assets/textures", L.src.replace("assets/", ""))),
  };
});

const inv = {
  generated: new Date().toISOString(),
  policy: "public/index.html is source of truth. No approximate stubs. Map every draw* before claiming parity.",
  draw_functions: drawEntries,
  img_loads: assetEntries,
  icon_glyphs: icons,
  summary: {
    draw_total: drawEntries.length,
    draw_mapped: drawEntries.filter((d) => d.status === "mapped").length,
    draw_unmapped: drawEntries.filter((d) => d.status !== "mapped").length,
    assets_total: assetEntries.length,
    assets_ok: assetEntries.filter((a) => a.public_ok && a.godot_texture).length,
    icons: icons.length,
  },
};

const outJson = path.join(root, "tools/port/ELEMENT_INVENTORY.json");
fs.writeFileSync(outJson, JSON.stringify(inv, null, 2) + "\n");

const unmapped = drawEntries.filter((d) => d.status !== "mapped");
console.log("ELEMENT_INVENTORY written:", outJson);
console.log(JSON.stringify(inv.summary, null, 2));
if (unmapped.length) {
  console.log("UNMAPPED / missing:");
  for (const u of unmapped) console.log(" ", u.html, "→", u.godot, u.status);
  process.exitCode = 1;
} else {
  console.log("All draw* functions mapped to on-disk Godot files.");
}
