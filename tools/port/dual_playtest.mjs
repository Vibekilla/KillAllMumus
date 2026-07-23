#!/usr/bin/env node
/**
 * Fast dual playtest: HTML (public/ truth) vs Godot screenshots.
 *
 *   npm run port:dual              # both, default quick set
 *   npm run port:dual -- --fast    # fewer frames / shots
 *   npm run port:dual -- --full    # outfits + power + more wait
 *   npm run port:dual -- --html-only
 *   npm run port:dual -- --godot-only
 *
 * Out: tools/port/playtest_out/{html,godot,index.html}
 *
 * Until cutover: live stays html-legacy; Godot at /godot/ or ?test.
 * End goal: full Godot client (Steam desktop export) with zero public/ runtime.
 */
import { chromium } from "playwright";
import { spawn } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import http from "http";
import { createReadStream, statSync } from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const outDir = path.join(root, "tools/port/playtest_out");
const htmlDir = path.join(outDir, "html");
const godotDir = path.join(outDir, "godot");
const GODOT = process.env.GODOT || path.join(process.env.HOME || "", ".local/godot/godot");

const argv = process.argv.slice(2);
const has = (f) => argv.includes(f);
const htmlOnly = has("--html-only");
const godotOnly = has("--godot-only");
const full = has("--full");
const fast = has("--fast") || !full;

function ensureDir(d) {
  fs.mkdirSync(d, { recursive: true });
}

function mime(p) {
  if (p.endsWith(".html")) return "text/html; charset=utf-8";
  if (p.endsWith(".js")) return "application/javascript";
  if (p.endsWith(".css")) return "text/css";
  if (p.endsWith(".png")) return "image/png";
  if (p.endsWith(".jpg") || p.endsWith(".jpeg")) return "image/jpeg";
  if (p.endsWith(".webp")) return "image/webp";
  if (p.endsWith(".gif")) return "image/gif";
  if (p.endsWith(".wasm")) return "application/wasm";
  return "application/octet-stream";
}

function servePublic() {
  const pub = path.join(root, "public");
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let urlPath = decodeURIComponent((req.url || "/").split("?")[0]);
      if (urlPath === "/") urlPath = "/index.html";
      const file = path.join(pub, urlPath.replace(/^\//, ""));
      if (!file.startsWith(pub) || !fs.existsSync(file) || statSync(file).isDirectory()) {
        res.writeHead(404);
        res.end("not found");
        return;
      }
      res.writeHead(200, { "Content-Type": mime(file) });
      createReadStream(file).pipe(res);
    });
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      resolve({ server, base: `http://127.0.0.1:${port}` });
    });
  });
}

async function captureHtml() {
  ensureDir(htmlDir);
  const { server, base } = await servePublic();
  console.log("[HTML] serving", base);
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 960, height: 540 },
    deviceScaleFactor: 1,
  });
  // Faster than networkidle — game is single HTML
  await page.goto(base + "/", { waitUntil: "domcontentloaded", timeout: 30000 });
  try {
    const mute = page.locator("#sg-mute");
    if (await mute.count()) await mute.click({ timeout: 1500 });
  } catch (_) {}
  await page.waitForTimeout(fast ? 400 : 800);
  await page.screenshot({ path: path.join(htmlDir, "html_title.png") });
  console.log("[HTML] title");

  // Canvas menu states via title buttons — HTML drawTitle layout (desktop):
  // outfit oy=304 bh=28; mode ry=344; row3 ny=384 (ARSENAL/EMBLEMS/SETTINGS bw=150 gap=10)
  const canvas = page.locator("canvas#c, canvas").first();
  const box = await canvas.boundingBox();
  async function clickCanvas(nx, ny) {
    if (!box) return;
    await page.mouse.click(box.x + nx, box.y + ny);
    await page.waitForTimeout(fast ? 400 : 700);
  }
  // OUTFIT button center
  await clickCanvas(480, 318);
  await page.screenshot({ path: path.join(htmlDir, "html_menu_outfits.png") });
  console.log("[HTML] menu_outfits");
  await page.keyboard.press("KeyZ"); // back
  await page.waitForTimeout(fast ? 300 : 500);

  // ARSENAL — row3 sx0≈245, first tab center x≈320, y≈398
  await clickCanvas(320, 398);
  await page.screenshot({ path: path.join(htmlDir, "html_menu_arsenal.png") });
  console.log("[HTML] menu_arsenal");
  await page.keyboard.press("KeyZ");
  await page.waitForTimeout(fast ? 300 : 500);

  // EMBLEMS — second tab center x≈480
  await clickCanvas(480, 398);
  await page.screenshot({ path: path.join(htmlDir, "html_menu_emblems.png") });
  console.log("[HTML] menu_emblems");
  await page.keyboard.press("KeyZ");
  await page.waitForTimeout(fast ? 300 : 500);

  // LEADERBOARD — mode row right button ~ x=601 y=358
  await clickCanvas(601, 358);
  await page.screenshot({ path: path.join(htmlDir, "html_menu_leaderboard.png") });
  console.log("[HTML] menu_leaderboard");
  await page.keyboard.press("KeyZ");
  await page.waitForTimeout(fast ? 300 : 500);

  // Start pill center ~ y=444
  await clickCanvas(480, 444);
  await page.waitForTimeout(fast ? 200 : 400);
  await page.keyboard.press("KeyZ");
  await page.waitForTimeout(fast ? 600 : 1200);
  await page.keyboard.press("KeyZ");
  await page.waitForTimeout(fast ? 900 : 1800);
  await page.screenshot({ path: path.join(htmlDir, "html_play.png") });
  console.log("[HTML] play");

  if (!fast) {
    if (box) {
      await page.mouse.move(box.x + box.width * 0.45, box.y + box.height * 0.55);
      await page.keyboard.down("KeyZ");
      await page.waitForTimeout(800);
      await page.keyboard.up("KeyZ");
    }
    await page.screenshot({ path: path.join(htmlDir, "html_play_firing.png") });
    console.log("[HTML] play_firing");
  }

  await browser.close();
  server.close();
}

function runGodotScreenshots() {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(GODOT)) {
      reject(new Error("GODOT not found: " + GODOT));
      return;
    }
    ensureDir(godotDir);
    const godotProj = path.join(root, "godot");
    const useXvfb = !process.env.NO_XVFB && fs.existsSync("/usr/bin/xvfb-run");
    console.log("[GODOT] shots", useXvfb ? "(xvfb)" : "(headless)");
    const env = { ...process.env, PLAYTEST_FAST: fast ? "1" : "0", PLAYTEST_FULL: full ? "1" : "0" };
    const bin = useXvfb ? "xvfb-run" : GODOT;
    const gArgs = useXvfb
      ? ["-a", "-s", "-screen 0 960x540x24", GODOT, "--path", godotProj, "--script", "res://scripts/tools/screenshot_playtest.gd"]
      : ["--path", godotProj, "--headless", "--script", "res://scripts/tools/screenshot_playtest.gd"];
    const child = spawn(bin, gArgs, { cwd: root, env });
    let out = "";
    child.stdout.on("data", (d) => {
      out += d.toString();
      process.stdout.write(d);
    });
    child.stderr.on("data", (d) => process.stderr.write(d));
    child.on("close", (code) => {
      const candidates = [];
      const m = out.match(/\[SHOT\] done dir=(.+)/);
      if (m) candidates.push(m[1].trim());
      const home = process.env.HOME || "";
      candidates.push(
        path.join(home, ".local/share/godot/app_userdata/Kill All Mumus/playtest_shots"),
        path.join(home, ".local/share/godot/app_userdata/KillAllMumus/playtest_shots")
      );
      let copied = 0;
      for (const c of candidates) {
        if (!fs.existsSync(c)) continue;
        for (const f of fs.readdirSync(c)) {
          if (f.endsWith(".png")) {
            fs.copyFileSync(path.join(c, f), path.join(godotDir, f));
            copied++;
          }
        }
        console.log("[GODOT] copied", copied, "from", c);
        break;
      }
      if (code !== 0 && copied === 0) reject(new Error("Godot exit " + code));
      else resolve();
    });
  });
}

function writeIndex() {
  const htmlShots = fs.existsSync(htmlDir) ? fs.readdirSync(htmlDir).filter((f) => f.endsWith(".png")) : [];
  const godotShots = fs.existsSync(godotDir) ? fs.readdirSync(godotDir).filter((f) => f.endsWith(".png")) : [];
  const pairs = [
    ["html_title.png", "godot_title.png", "Title"],
    ["html_menu_outfits.png", "godot_menu_outfits.png", "Outfits"],
    ["html_menu_arsenal.png", "godot_menu_arsenal.png", "Arsenal"],
    ["html_menu_emblems.png", "godot_menu_emblems.png", "Emblems"],
    ["html_menu_leaderboard.png", "godot_menu_leaderboard.png", "Leaderboard"],
    ["html_play.png", "godot_play.png", "Play"],
  ];
  if (!fast) pairs.push(["html_play_firing.png", "godot_play_power6.png", "Combat"]);
  let rows = "";
  for (const [h, g, label] of pairs) {
    const hasH = htmlShots.includes(h);
    const hasG = godotShots.includes(g);
    rows += `<tr><th colspan="2">${label}</th></tr><tr>
      <td><div class="cap">HTML (source of truth)</div>${hasH ? `<img src="html/${h}" width="480"/>` : "<em>missing</em>"}</td>
      <td><div class="cap">Godot port</div>${hasG ? `<img src="godot/${g}" width="480"/>` : "<em>missing</em>"}</td></tr>`;
  }
  for (const g of godotShots.filter((f) => f.includes("outfit_") && !f.includes("menu"))) {
    rows += `<tr><th colspan="2">${g}</th></tr><tr><td colspan="2"><img src="godot/${g}" width="480"/></td></tr>`;
  }
  fs.writeFileSync(
    path.join(outDir, "index.html"),
    `<!DOCTYPE html><html><head><meta charset="utf-8"/><title>Dual playtest</title>
<style>body{font-family:system-ui;background:#12081a;color:#f0e6f5;margin:16px}
table{border-collapse:collapse}td,th{border:1px solid #4a3058;padding:8px;vertical-align:top}
img{background:#000;max-width:100%}.cap{color:#ff9ecb;margin-bottom:4px}code{color:#ffe08a}</style></head><body>
<h1>HTML vs Godot dual playtest</h1>
<p>Generated ${new Date().toISOString()} · mode=${fast ? "fast" : "full"}</p>
<p>HTML ${htmlShots.length} shots · Godot ${godotShots.length} shots · open this file after each port pass.</p>
<p>Cutover still requires <code>USE_GODOT=1</code> only after full parity. Steam target: desktop export of Godot only.</p>
<table>${rows}</table></body></html>`
  );
  console.log("[REPORT]", path.join(outDir, "index.html"));
}

async function main() {
  ensureDir(outDir);
  ensureDir(htmlDir);
  ensureDir(godotDir);
  const t0 = Date.now();
  // Parallel HTML + Godot when both requested
  const jobs = [];
  if (!godotOnly) jobs.push(captureHtml().catch((e) => { console.error("[HTML]", e); process.exitCode = 1; }));
  if (!htmlOnly) jobs.push(runGodotScreenshots().catch((e) => { console.error("[GODOT]", e); process.exitCode = 1; }));
  await Promise.all(jobs);
  writeIndex();
  console.log("[DUAL] done in", ((Date.now() - t0) / 1000).toFixed(1), "s → tools/port/playtest_out/index.html");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
