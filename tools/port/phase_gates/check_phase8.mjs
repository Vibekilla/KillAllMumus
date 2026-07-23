#!/usr/bin/env node
/**
 * Phase 8 — Cutover readiness structure only.
 * Does NOT flip USE_GODOT. Fails if live is already on godot without sign-off is soft.
 */
import { createGate, read, exists } from "./gate_lib.mjs";
import { execSync } from "child_process";

const g = createGate("Phase 8 — Cutover readiness structure");

g.ok(exists("public_godot/index.html") || exists("godot/export_presets.cfg"), "web export target present");
g.ok(exists("godot/export_presets.cfg"), "export_presets.cfg");
const presets = read("godot/export_presets.cfg");
g.ok(/platform="Web"/.test(presets) || /Web/.test(presets), "Web export preset");

g.ok(exists("scripts/patch-godot-music.sh"), "patch-godot-music.sh");
g.ok(exists("scripts/promote-to-live.sh"), "promote-to-live.sh");

const parity = read("godot/PARITY.md");
g.ok(/USE_GODOT=1/.test(parity), "PARITY documents USE_GODOT flip");
g.ok(/Phase 7/.test(parity) && /blocked|Only after|before any Phase 8/i.test(parity), "Phase 8 blocked on Phase 7 in docs");

// Soft: export artifacts
g.soft(exists("public_godot/index.pck") || exists("public_godot/index.wasm"), "public_godot wasm/pck (refresh after export)");

try {
  const health = execSync("curl -sS --max-time 3 http://127.0.0.1:3000/api/health", { encoding: "utf8" });
  const j = JSON.parse(health);
  // Until Phase 7 sign-off, client must stay html-legacy
  if (j.client === "godot" || j.useGodotEnv === true) {
    g.soft(false, "WARNING: live USE_GODOT appears on — only valid after Phase 7 sign-off");
  } else {
    g.ok(true, "live still html-legacy (expected pre–Phase 8)");
  }
} catch {
  g.soft(false, "api health unreachable (offline ok)");
}

g.finish();
