#!/usr/bin/env node
/**
 * Load /godot/ and report console errors / WASM OOB.
 *   node tools/port/check_godot_wasm.mjs [baseUrl]
 */
import { chromium } from "playwright";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const base = process.argv[2] || "http://127.0.0.1:3000";
const outDir = path.join(__dirname, "playtest_out");
fs.mkdirSync(outDir, { recursive: true });

const logs = [];
const browser = await chromium.launch({
  headless: true,
  args: [
    "--use-gl=angle",
    "--use-angle=swiftshader-webgl",
    "--enable-webgl",
    "--ignore-gpu-blocklist",
    "--disable-dev-shm-usage",
    "--js-flags=--max-old-space-size=4096",
  ],
});
const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
page.on("pageerror", (e) => logs.push("PAGEERROR: " + e.message));
page.on("console", (m) => {
  const t = m.text();
  if (m.type() === "error" || /memory access|out of bounds|RuntimeError|Aborted|exception|ERROR/i.test(t)) {
    logs.push(`C[${m.type()}] ${t.slice(0, 500)}`);
  }
});
page.on("crash", () => logs.push("CRASH"));

try {
  const resp = await page.goto(base.replace(/\/$/, "") + "/godot/", {
    waitUntil: "domcontentloaded",
    timeout: 90000,
  });
  logs.push("status=" + (resp && resp.status()));
  let ready = false;
  for (let i = 0; i < 80; i++) {
    await page.waitForTimeout(400);
    if (page.isClosed()) {
      logs.push("closed@" + i);
      break;
    }
    let info;
    try {
      info = await page.evaluate(() => {
        const notice = document.getElementById("status-notice");
        const status = document.getElementById("status");
        const canvas = document.getElementById("canvas");
        return {
          notice: notice ? notice.textContent : null,
          statusGone: !status,
          canvasW: canvas ? canvas.width : 0,
          canvasH: canvas ? canvas.height : 0,
        };
      });
    } catch (e) {
      logs.push("eval@" + i + ": " + e.message);
      break;
    }
    if (i % 10 === 0) logs.push("t" + i + " " + JSON.stringify(info));
    // Default shell canvas is 300×150 before engine starts — wait for real viewport
    if ((info.canvasW >= 640 && info.canvasH >= 360) || info.statusGone) {
      logs.push("READY " + JSON.stringify(info));
      ready = true;
      break;
    }
    if (info.notice && String(info.notice).trim()) {
      logs.push("NOTICE " + info.notice);
      break;
    }
  }
  if (ready) {
    await page.keyboard.press("Enter");
    await page.waitForTimeout(600);
    await page.keyboard.press("KeyZ");
    await page.waitForTimeout(1500);
  }
  await page.screenshot({ path: path.join(outDir, "godot_wasm_diag.png") });
} catch (e) {
  logs.push("OUTER: " + e.message);
}

console.log(logs.join("\n"));
const oob = logs.some((l) => /memory access|out of bounds|RuntimeError/i.test(l));
const crashed = logs.some((l) => /CRASH|closed@/i.test(l));
fs.writeFileSync(path.join(outDir, "godot_wasm_diag.txt"), logs.join("\n"));
await browser.close();
process.exit(oob || crashed ? 2 : 0);
