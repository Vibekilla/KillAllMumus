#!/usr/bin/env node
/**
 * Shared helpers for Phase 0–8 structure gates (PARITY.md).
 * Structure smoke only — dual QA is the product gate.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const ROOT = path.resolve(__dirname, "../../..");

export function createGate(phaseLabel) {
  const fails = [];
  const warns = [];
  console.log(`\n══ Gate ${phaseLabel} (structure smoke) ══\n`);
  return {
    ok(cond, msg) {
      if (cond) console.log("  ✓", msg);
      else {
        console.log("  ✗", msg);
        fails.push(msg);
      }
    },
    soft(cond, msg) {
      if (cond) console.log("  ✓", msg);
      else {
        console.log("  ~", msg, "(warn)");
        warns.push(msg);
      }
    },
    finish() {
      if (warns.length) console.log(`\n  warnings: ${warns.length}`);
      if (fails.length) {
        console.log(`\nGate ${phaseLabel}: FAIL (${fails.length})\n`);
        process.exit(1);
      }
      console.log(`\nGate ${phaseLabel}: PASS\n`);
    },
  };
}

export function read(rel) {
  return fs.readFileSync(path.join(ROOT, rel), "utf8");
}

export function exists(rel) {
  return fs.existsSync(path.join(ROOT, rel));
}

export function walkGd(dir, out = []) {
  const abs = path.isAbsolute(dir) ? dir : path.join(ROOT, dir);
  if (!fs.existsSync(abs)) return out;
  for (const name of fs.readdirSync(abs)) {
    if (name === "_archive" || name === ".godot") continue;
    const p = path.join(abs, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walkGd(p, out);
    else if (name.endsWith(".gd")) out.push(p);
  }
  return out;
}

export function banGrep(patterns) {
  const files = walkGd("godot/scripts").concat(walkGd("godot/autoload"));
  const hits = [];
  for (const f of files) {
    // skip archive and auto-port text dumps
    if (f.includes(`${path.sep}_archive${path.sep}`)) continue;
    if (f.includes(`${path.sep}ported${path.sep}`)) continue;
    const src = fs.readFileSync(f, "utf8");
    for (const { re, msg } of patterns) {
      if (re.test(src)) hits.push(`${msg}: ${path.relative(ROOT, f)}`);
    }
  }
  return hits;
}
