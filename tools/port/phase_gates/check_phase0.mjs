#!/usr/bin/env node
/** Phase 0 — Foundation: policy, HTML truth, bans, docs, live html-legacy */
import fs from "fs";
import path from "path";
import { execSync } from "child_process";
import { createGate, ROOT, read, exists, banGrep } from "./gate_lib.mjs";

const g = createGate("Phase 0 — Foundation");

g.ok(exists("public/index.html"), "public/index.html source of truth");
g.ok(exists("public/assets"), "public/assets/");
const assets = fs.readdirSync(path.join(ROOT, "public/assets"));
g.ok(assets.length >= 15, `public/assets count >= 15 (got ${assets.length})`);

const html = read("public/index.html");
g.ok(html.includes("function drawBobina"), "HTML drawBobina");
g.ok(/id=["']c["']/.test(html), "HTML canvas #c");

// Docs mandate phases 0–8
const parity = read("godot/PARITY.md");
g.ok(/Phase 0/.test(parity) && /Phase 7/.test(parity) && /Phase 8/.test(parity), "PARITY.md phases 0–8");
g.ok(/Source of truth/.test(parity) && /dual QA/i.test(parity), "PARITY dual QA as product gate");
g.ok(exists("godot/MIGRATION_CHECKLIST.md"), "MIGRATION_CHECKLIST.md");
g.ok(exists("godot/README.md"), "godot/README.md");

// Bans in live scripts (not _archive)
const hits = banGrep([
  { re: /_draw_fast\b/, msg: "ban _draw_fast" },
  { re: /_draw_mini_bobina\b/, msg: "ban _draw_mini_bobina" },
  { re: /Fast path:\s*native/i, msg: "ban Fast path: native entity art" },
]);
g.ok(hits.length === 0, hits.length ? hits.join("; ") : "no banned art shortcuts in live scripts");

// Inventory / map harness (soft if extract not re-run)
g.soft(exists("tools/port/function_map.json"), "function_map.json present");
g.soft(exists("tools/port/dual_playtest.mjs"), "dual_playtest.mjs present");

// Live health best-effort
try {
  const health = execSync("curl -sS --max-time 3 http://127.0.0.1:3000/api/health", { encoding: "utf8" });
  const j = JSON.parse(health);
  g.ok(j.ok === true, "api health ok");
  g.ok(j.client === "html-legacy" || j.useGodotEnv === false, `live not cut over (client=${j.client})`);
} catch (e) {
  g.soft(false, "api health unreachable (ok offline): " + e.message);
}

g.finish();
