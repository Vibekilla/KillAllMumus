#!/usr/bin/env node
/**
 * Run structure gates Phase 0–8 (PARITY.md).
 * Dual QA remains the product gate — these checks only guard scaffolding.
 */
import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const phases = [0, 1, 2, 3, 4, 5, 6, 7, 8];
let failed = 0;

console.log("port:gates — structure smoke for Phases 0–8 (not dual QA)\n");

for (const p of phases) {
  const script = path.join(__dirname, `check_phase${p}.mjs`);
  const r = spawnSync(process.execPath, [script], { stdio: "inherit" });
  if (r.status !== 0) failed++;
}

if (failed) {
  console.log(`\nport:gates FAIL — ${failed} phase gate(s) failed`);
  process.exit(1);
}
console.log("\nport:gates PASS — all Phase 0–8 structure checks ok");
console.log("Next: npm run port:dual -- --full  (product gate)");
