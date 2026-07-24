#!/usr/bin/env node
/**
 * Fast dual playtest: HTML (public/ truth) vs Godot screenshots.
 *
 *   npm run port:dual              # both, default quick set
 *   npm run port:dual -- --fast    # fewer frames / shots
 *   npm run port:dual -- --full    # outfits + power + more wait
 *   npm run port:dual -- --html-only
 *   npm run port:dual -- --godot-only
 *   npm run port:dual -- --full --shots aura,items,elites,bosses
 *   npm run port:dual -- --full --godot-only --shots aura
 *
 * Shot groups (comma-separated, case-insensitive):
 *   core       title + menus + flow + ends (default always-on without --shots)
 *   wardrobe   28 outfit menu skins + anim ticks (expensive)
 *   faces      play-scale + HUD-mini expression matrix
 *   anims      breath / pose / blink duals
 *   combat     weapons + melee + specials + power6 (alias expands)
 *   weapons | melee | specials | aura | items | elites | bosses
 *
 * Aliases: outfit→wardrobe, weapon→weapons, special→specials, boss→bosses,
 *          elite→elites, item→items, shield/focus/dash/…→aura, menus/flow→core
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

/** Groups that require --full (or explicit --shots) when no filter is set. */
const FULL_ONLY = new Set([
  "wardrobe", "faces", "anims", "combat", "weapons", "melee", "specials",
  "aura", "items", "elites", "bosses", "mumus", "mechanics", "pickups", "power6",
]);

const SHOT_ALIASES = {
  outfit: "wardrobe", outfits: "wardrobe", wardrobe: "wardrobe",
  weapon: "weapons", weapons: "weapons", wep: "weapons",
  special: "specials", specials: "specials",
  melee: "melee",
  aura: "aura", shield: "aura", focus: "aura", rapid: "aura", vial: "aura",
  phase: "aura", dash: "aura", bomb: "aura", power: "aura",
  item: "items", items: "items",
  elite: "elites", elites: "elites",
  boss: "bosses", bosses: "bosses",
  mumu: "mumus", mumus: "mumus", lil: "mumus",
  mechanics: "mechanics", bleed: "mechanics", graze: "mechanics",
  pickups: "pickups", magnet: "pickups", vacuum: "pickups", loot: "pickups",
  face: "faces", faces: "faces",
  anim: "anims", anims: "anims", breath: "anims", pose: "anims", blink: "anims",
  menus: "core", menu: "core", flow: "core", ends: "core", title: "core", core: "core",
  combat: "combat", play: "core", power6: "power6",
};

function parseShotsArg(args) {
  let raw = null;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--shots" && args[i + 1] && !args[i + 1].startsWith("-")) {
      raw = args[i + 1];
      break;
    }
    if (a.startsWith("--shots=")) {
      raw = a.slice("--shots=".length);
      break;
    }
  }
  if (!raw || !String(raw).trim()) return null;
  const out = new Set();
  for (const part of String(raw).split(",")) {
    const s = part.trim().toLowerCase();
    if (!s) continue;
    const canon = SHOT_ALIASES[s] || s;
    out.add(canon);
    if (canon === "combat" || s === "combat") {
      out.add("weapons");
      out.add("melee");
      out.add("specials");
      out.add("power6");
    }
  }
  return out.size ? out : null;
}

/** null = no filter (default matrix). Set = only these groups. */
const shotSet = parseShotsArg(argv);
const shotFilterActive = shotSet != null;

/**
 * Whether to capture a shot group.
 * - No --shots: core always; full-only groups when --full.
 * - With --shots: only listed groups (aliases expanded). Explicit filter
 *   ignores "fast" for the selected groups so --shots aura works with --full.
 */
function want(group) {
  const g = SHOT_ALIASES[group] || group;
  if (!shotFilterActive) {
    if (FULL_ONLY.has(g)) return !fast;
    return true; // core + always-on
  }
  return shotSet.has(g);
}

function wantAny(...groups) {
  return groups.some((g) => want(g));
}

/** Combat / field captures need a live play session. */
function needPlaySession() {
  return wantAny("weapons", "melee", "specials", "aura", "items", "elites", "bosses", "mumus", "mechanics", "pickups", "power6", "combat", "faces");
}

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
      // Dual-only: expose state bridge inside the same script scope as `let state`
      if (urlPath === "/index.html" || file.endsWith("index.html")) {
        let html = fs.readFileSync(file, "utf8");
        if (!html.includes("window.__kamDual")) {
          // Full dual API closes over HTML lets (state, run, player, items, enemies, boss, …)
          const dualBridge = [
            "window.__kamDual={",
            "setState:function(s){state=s;},",
            "setScore:function(k,sc){totalKills=k;sessionScore=sc;},",
            "setClear:function(info){clearInfo=info||{stage:0,killsThisStage:0,total:totalKills||0,emblems:[]};},",
            "setPaused:function(p){paused=!!p;},",
            "setPower:function(v){if(run)run.power=v;},",
            "setOutfit:function(o,pose,face){if(o!=null)outfitPreview=o;if(pose!=null)outfitPose=pose|0;if(face!=null)victoryFace=face|0;},",
            "setEnd:function(w){endWon=!!w;endHandled=false;justSavedScore=false;nameEntryOpen=false;try{var n=document.getElementById('nameEntry');if(n)n.classList.remove('on');}catch(e){}},",
            "setWeapon:function(k){if(!run)return;if(!run.weapons.includes(k))run.weapons.push(k);run.weapon=k;},",
            "setMelee:function(idx){if(player)player.melee=idx|0;if(run){if(!run.melees)run.melees=[];if(!run.melees.includes(idx|0))run.melees.push(idx|0);}},",
            "setSpecial:function(k){if(!run)return;if(!run.specials)run.specials=[];if(!run.specials.includes(k))run.specials.push(k);run.armed=run.specials.indexOf(k);run.special=100;try{useSpecial();}catch(e){}},",
            "fireBurst:function(n){if(!run||!player)return;var i=n||8;while(i--){try{fire();}catch(e){break;}}},",
            "clearField:function(){enemies=[];bullets=[];pshots=[];items=[];fx=[];meleeFx=[];particles=[];boss=null;dialog=null;},",
            "setAura:function(cfg){if(!player||!run)return;cfg=cfg||{};",
            "emblemToasts=[];flashMsg=null;newEmblems=[];",
            "if(cfg.power!=null)run.power=cfg.power;",
            "player.focus=!!cfg.focus;",
            "player.iframe=cfg.iframe!=null?cfg.iframe:120;",
            "player.shieldT=cfg.shieldT||0;player.rapidT=cfg.rapidT||0;",
            "player.vialT=cfg.vialT||0;player.vialHits=cfg.vialHits||0;",
            "player.phaseT=cfg.phaseT||0;player.dash=cfg.dash||0;",
            "player.dashAng=cfg.dashAng!=null?cfg.dashAng:-Math.PI/2;",
            "player.bombFx=cfg.bombFx||0;player.slashDash=!!cfg.slashDash;",
            "player.face=-Math.PI/2;player.aim=-Math.PI/2;",
            "if(cfg.trail){player.trail=cfg.trail.slice();}else if(cfg.dash){",
            "player.trail=[];for(var i=0;i<8;i++)player.trail.push({x:player.x,y:player.y+i*6});}",
            "else player.trail=[];",
            "},",
            "dropItemsGrid:function(types){",
            "items=[];var list=types||['power','fullpower','point','life','bomb','shield','rapid','skull','weapon'];",
            "var col=3;for(var i=0;i<list.length;i++){",
            "var tx=PF.x+80+(i%col)*140, ty=PF.y+100+Math.floor(i/col)*100;",
            "items.push({x:tx,y:ty,vx:0,vy:0,type:list[i],t:0,homing:false,val:list[i]==='skull'?10:undefined,wep:list[i]==='weapon'?'laser':undefined});",
            "}},",
            "spawnElitesGrid:function(kinds){",
            "enemies=[];var list=kinds||['cheer','ape','badnik','pup','scammer','voideye','goon'];",
            "for(var i=0;i<list.length;i++){",
            "var ex=PF.x+80+(i%4)*100, ey=PF.y+120+Math.floor(i/4)*140;",
            "enemies.push({kind:'elite',elite:list[i],x:ex,y:ey,vx:0,vy:0,r:26,hp:9999,t:0,flash:0,hover:ey,bcol:'#7ed957',icy:false});",
            "}},",
            "spawnBossPortrait:function(stageIdx){",
            "if(!run)return null;run.stageIdx=stageIdx|0;",
            "enemies=[];bullets=[];pshots=[];dialog=null;fx=[];particles=[];emblemToasts=[];flashMsg=null;newEmblems=[];",
            "try{spawnBoss();}catch(e){return null;}",
            // Visible body, pinned center pose (no roam/attack/dialog chrome)
            "if(boss){var bx=PF.x+PF.w/2,by=PF.y+140;",
            "boss.intro=0;boss.introDlg=false;boss.x=bx;boss.y=by;boss.tx=bx;boss.ty=by;boss.mtx=bx;boss.mty=by;",
            "boss.dead=false;boss.specialT=0;boss.stun=9999;boss.flash=0;boss.dash=false;",
            "boss.face=Math.PI/2;boss.px=bx;boss.py=by;}",
            "if(player){player.face=-Math.PI/2;player.aim=-Math.PI/2;}",
            "dialog=null;bullets=[];pshots=[];enemies=[];",
            "return boss&&boss.data?boss.data.portrait:null;",
            "}",
            "};function showNameEntry(){",
          ].join("");
          html = html.replace(/function showNameEntry\(\)\{/, dualBridge);
        }
        res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        res.end(html);
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
  const canvas = page.locator("canvas#c, canvas").first();
  const box = await canvas.boundingBox();
  async function clickCanvas(nx, ny) {
    if (!box) return;
    await page.mouse.click(box.x + nx, box.y + ny);
    await page.waitForTimeout(fast ? 400 : 700);
  }
  async function ensurePlay() {
    await page.evaluate(() => {
      if (typeof newRun === "function") newRun();
      else if (typeof startRun === "function") startRun();
      if (window.__kamDual) {
        window.__kamDual.setState("play");
        if (window.__kamDual.setPower) window.__kamDual.setPower(4);
      }
      if (typeof draw === "function") draw();
    });
    await page.waitForTimeout(fast ? 350 : 600);
  }

  if (want("core")) {
    await page.screenshot({ path: path.join(htmlDir, "html_title.png") });
    console.log("[HTML] title");
  }

  // Canvas menu states via title buttons — HTML drawTitle layout (desktop):
  // outfit oy=304 bh=28; mode ry=344; row3 ny=384 (ARSENAL/EMBLEMS/SETTINGS bw=150 gap=10)
  if (want("core") || want("wardrobe")) {
    // OUTFIT button center
    await clickCanvas(480, 318);
    if (want("core")) {
      await page.screenshot({ path: path.join(htmlDir, "html_menu_outfits.png") });
      console.log("[HTML] menu_outfits");
    }
    // Phase 2: outfit menu wardrobe dual — same surface as Godot (drawOutfits ×4.7 stage)
    if (want("wardrobe")) {
      const wardrobe = [
        "og","maid","nanosuit","badger","viking","ourbit","bullbina","monke",
        "pickle","emblem","labrat","neko","kigurumi","cheese","business","jester",
        "samurai","bride","angel","golden","succubus","voidling","honeybee","banana",
        "squirrely","honeypot","empress","cabal",
      ];
      for (const key of wardrobe) {
        await page.evaluate((k) => {
          if (window.__kamDual && window.__kamDual.setOutfit) window.__kamDual.setOutfit(k, 0, 2);
          if (window.__kamDual) window.__kamDual.setState("outfits");
        }, key);
        await page.waitForTimeout(120);
        await page.screenshot({ path: path.join(htmlDir, `html_menu_outfit_${key}.png`) });
      }
      // continuous anim skins @ two ticks via pose face fixed, rely on browser draw loop
      for (const key of ["angel","succubus","voidling","honeypot","bride","empress","cabal"]) {
        await page.evaluate((k) => {
          if (window.__kamDual && window.__kamDual.setOutfit) window.__kamDual.setOutfit(k, 0, 2);
          if (window.__kamDual) window.__kamDual.setState("outfits");
        }, key);
        await page.waitForTimeout(80);
        await page.screenshot({ path: path.join(htmlDir, `html_menu_outfit_anim_${key}_a.png`) });
        await page.waitForTimeout(350);
        await page.screenshot({ path: path.join(htmlDir, `html_menu_outfit_anim_${key}_b.png`) });
      }
      console.log("[HTML] menu_outfits wardrobe", wardrobe.length);
    }
    await page.keyboard.press("KeyZ"); // back
    await page.waitForTimeout(fast ? 300 : 500);
  }

  if (want("core")) {
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

    // SETTINGS — HTML is a DOM overlay (#settings), not a canvas state
    try {
      await page.evaluate(() => {
        if (typeof openSettings === "function") openSettings();
        else {
          const el = document.getElementById("settings");
          if (el) el.classList.add("on");
        }
      });
      await page.waitForTimeout(fast ? 300 : 500);
      await page.screenshot({ path: path.join(htmlDir, "html_menu_settings.png") });
      console.log("[HTML] menu_settings");
      await page.evaluate(() => {
        const el = document.getElementById("settings");
        if (el) el.classList.remove("on");
        if (typeof closeSettings === "function") closeSettings();
      });
    } catch (e) {
      console.log("[HTML] settings skip", e.message || e);
    }

    // NG+ select via canvas state
    try {
      await page.evaluate(() => {
        if (window.__kamDual) window.__kamDual.setState("ngselect");
        if (typeof draw === "function") draw();
      });
      await page.waitForTimeout(fast ? 350 : 600);
      await page.screenshot({ path: path.join(htmlDir, "html_menu_ngselect.png") });
      console.log("[HTML] menu_ngselect");
      await page.evaluate(() => {
        if (window.__kamDual) window.__kamDual.setState("title");
        if (typeof draw === "function") draw();
      });
    } catch (e) {
      console.log("[HTML] ngselect skip", e.message || e);
    }

    // Start pill center ~ y=444 → intro then play
    await clickCanvas(480, 444);
    await page.waitForTimeout(fast ? 250 : 400);
    // Intro screen (PRESS Z to begin)
    await page.screenshot({ path: path.join(htmlDir, "html_flow_intro.png") });
    console.log("[HTML] flow_intro");
    await page.keyboard.press("KeyZ");
    await page.waitForTimeout(fast ? 600 : 1200);
    await page.keyboard.press("KeyZ");
    await page.waitForTimeout(fast ? 900 : 1800);
    await page.screenshot({ path: path.join(htmlDir, "html_play.png") });
    console.log("[HTML] play");
  } else if (needPlaySession()) {
    // Sliced dual: skip menus/flow tax, jump straight into a run
    await ensurePlay();
    console.log("[HTML] play (sliced — skipped core menus)");
  }

  if (want("core")) {
    // Pause overlay (HTML #pausescreen when state=play && paused)
    try {
      await page.evaluate(() => {
        if (window.__kamDual && window.__kamDual.setPaused) window.__kamDual.setPaused(true);
        const ps = document.getElementById("pausescreen");
        if (ps) {
          ps.classList.add("on");
          if (typeof syncPauseUI === "function") syncPauseUI();
        }
        if (typeof draw === "function") draw();
      });
      await page.waitForTimeout(fast ? 300 : 500);
      await page.screenshot({ path: path.join(htmlDir, "html_flow_pause.png") });
      console.log("[HTML] flow_pause");
      await page.evaluate(() => {
        if (window.__kamDual && window.__kamDual.setPaused) window.__kamDual.setPaused(false);
        const ps = document.getElementById("pausescreen");
        if (ps) ps.classList.remove("on");
      });
    } catch (e) {
      console.log("[HTML] pause skip", e.message || e);
    }

    // Force shop / stageclear / ends via __kamDual (closes over let state)
    try {
      await page.evaluate(() => {
        if (typeof enterShop === "function") enterShop();
        else if (window.__kamDual) window.__kamDual.setState("shop");
        if (typeof draw === "function") draw();
      });
      await page.waitForTimeout(fast ? 400 : 700);
      await page.screenshot({ path: path.join(htmlDir, "html_flow_shop.png") });
      console.log("[HTML] flow_shop");
      await page.evaluate(() => {
        if (typeof leaveShop === "function") leaveShop();
        else if (window.__kamDual) window.__kamDual.setState("play");
        if (typeof draw === "function") draw();
      });
      await page.waitForTimeout(200);
    } catch (e) {
      console.log("[HTML] shop eval skip", e.message || e);
    }
    // Stage clear needs clearInfo populated — bare setState throws on clearInfo.stage
    try {
      const stSc = await page.evaluate(() => {
        if (!window.__kamDual) return "no-dual";
        window.__kamDual.setScore(39, 13300);
        window.__kamDual.setClear({
          stage: 0,
          killsThisStage: 39,
          total: 39,
          emblems: [],
        });
        window.__kamDual.setState("stageclear");
        if (typeof draw === "function") draw();
        if (typeof manageGifOverlays === "function") manageGifOverlays();
        return typeof state !== "undefined" ? state : "?";
      });
      console.log("[HTML] flow_stageclear state=", stSc);
      await page.waitForTimeout(fast ? 500 : 800);
      await page.screenshot({ path: path.join(htmlDir, "html_flow_stageclear.png") });
      console.log("[HTML] flow_stageclear");
    } catch (e) {
      console.log("[HTML] stageclear eval skip", e.message || e);
    }

    async function forceEnd(stateName, kills, score, won) {
      await page.evaluate(
        ({ stateName, kills, score, won }) => {
          if (!window.__kamDual) return "no-dual";
          window.__kamDual.setScore(kills, score);
          window.__kamDual.setEnd(won);
          window.__kamDual.setState(stateName);
          try {
            if (typeof endHandled !== "undefined") endHandled = true;
            if (typeof nameEntryOpen !== "undefined") nameEntryOpen = false;
            const ne = document.getElementById("nameEntry");
            if (ne) ne.classList.remove("on");
          } catch (_) {}
          if (typeof draw === "function") draw();
          return typeof state !== "undefined" ? state : "?";
        },
        { stateName, kills, score, won }
      );
      await page.waitForTimeout(fast ? 450 : 700);
    }
    try {
      const st1 = await forceEnd("gameover", 420, 125000, false);
      console.log("[HTML] end_gameover state=", st1);
      await page.screenshot({ path: path.join(htmlDir, "html_end_gameover.png") });
      console.log("[HTML] end_gameover");
      const st2 = await forceEnd("win", 9001, 2500000, true);
      console.log("[HTML] end_win state=", st2);
      await page.screenshot({ path: path.join(htmlDir, "html_end_win.png") });
      console.log("[HTML] end_win");
    } catch (e) {
      console.log("[HTML] end screens eval skip", e.message || e);
    }
  }

  // Phase 3 combat / field duals (each group independently selectable via --shots)
  if (wantAny("power6", "weapons", "melee", "specials", "aura", "items", "elites", "bosses", "mumus", "mechanics", "pickups")) {
    try {
      await ensurePlay();
      if (want("power6")) {
        await page.evaluate(() => {
          if (window.__kamDual) {
            window.__kamDual.setState("play");
            if (window.__kamDual.setPower) window.__kamDual.setPower(6);
          }
          if (typeof draw === "function") draw();
        });
        await page.waitForTimeout(fast ? 400 : 700);
        if (box) {
          await page.mouse.move(box.x + box.width * 0.45, box.y + box.height * 0.55);
          await page.keyboard.down("KeyZ");
          await page.waitForTimeout(fast ? 400 : 800);
          await page.keyboard.up("KeyZ");
        }
        await page.screenshot({ path: path.join(htmlDir, "html_play_firing.png") });
        console.log("[HTML] play_firing");
      }
      if (want("weapons")) {
        const weps = ["laser","homing","wave","scatter","gatling","grenade","voidripper","lotus","shock","spread"];
        for (const w of weps) {
          await page.evaluate((k) => {
            if (window.__kamDual) {
              window.__kamDual.setState("play");
              if (window.__kamDual.clearField) window.__kamDual.clearField();
              if (window.__kamDual.setPower) window.__kamDual.setPower(6);
              if (window.__kamDual.setWeapon) window.__kamDual.setWeapon(k);
              if (typeof player !== "undefined" && player) {
                player.face = -Math.PI / 2; player.aim = -Math.PI / 2;
                player.x = PF.x + PF.w / 2; player.y = PF.y + PF.h - 120;
              }
              if (window.__kamDual.fireBurst) window.__kamDual.fireBurst(10);
            }
          }, w);
          await page.waitForTimeout(fast ? 200 : 350);
          await page.screenshot({ path: path.join(htmlDir, `html_wep_${w}.png`) });
        }
        console.log("[HTML] weapons", weps.length);
      }
      if (want("melee")) {
        const meleeKeys = ["katana","lash","scythe","hammer","claws"];
        for (let i = 0; i < meleeKeys.length; i++) {
          await page.evaluate((idx) => {
            if (window.__kamDual) {
              if (window.__kamDual.clearField) window.__kamDual.clearField();
              if (window.__kamDual.setPower) window.__kamDual.setPower(6);
            }
            if (typeof player !== "undefined" && player) {
              player.face = -Math.PI / 2; player.aim = -Math.PI / 2;
              player.x = PF.x + PF.w / 2; player.y = PF.y + PF.h - 120;
            }
            if (window.__kamDual && window.__kamDual.setMelee) window.__kamDual.setMelee(idx);
            if (typeof doMeleeSwipe === "function" && typeof player !== "undefined" && player) {
              try { doMeleeSwipe(true); } catch (e) {}
            } else if (typeof player !== "undefined" && player) {
              try { player.meleeCharge = 1; } catch (e) {}
            }
          }, i);
          await page.waitForTimeout(fast ? 180 : 280);
          await page.screenshot({ path: path.join(htmlDir, `html_melee_${meleeKeys[i]}.png`) });
        }
        console.log("[HTML] melee", meleeKeys.length);
      }
      if (want("specials")) {
        const specs = ["laser","mech","bearzooka","vault","stampede","badger","sixth","revenge","kiss","kraken","void"];
        for (const s of specs) {
          await page.evaluate((k) => {
            if (window.__kamDual) {
              if (window.__kamDual.clearField) window.__kamDual.clearField();
              if (window.__kamDual.setPower) window.__kamDual.setPower(6);
              if (typeof player !== "undefined" && player) {
                player.face = -Math.PI / 2; player.aim = -Math.PI / 2;
                player.x = PF.x + PF.w / 2; player.y = PF.y + PF.h - 120;
              }
              window.__kamDual.setSpecial(k);
            }
          }, s);
          await page.waitForTimeout(fast ? 220 : 400);
          await page.screenshot({ path: path.join(htmlDir, `html_special_${s}.png`) });
        }
        console.log("[HTML] specials", specs.length);
      }
      if (want("aura")) {
        await page.evaluate(() => {
          if (window.__kamDual) {
            window.__kamDual.setState("play");
            if (window.__kamDual.clearField) window.__kamDual.clearField();
          }
          if (typeof player !== "undefined" && player) {
            player.x = PF.x + PF.w / 2;
            player.y = PF.y + PF.h - 120;
          }
        });
        for (const pwr of [1, 3, 6]) {
          await page.evaluate((v) => {
            if (window.__kamDual && window.__kamDual.setAura) {
              window.__kamDual.setAura({ power: v, focus: false, iframe: 9999, shieldT: 0, rapidT: 0, vialT: 0, vialHits: 0, phaseT: 0, dash: 0, bombFx: 0 });
            }
          }, pwr);
          await page.waitForTimeout(fast ? 120 : 200);
          await page.screenshot({ path: path.join(htmlDir, `html_aura_power_${pwr}.png`) });
        }
        const auraShots = [
          ["focus", { power: 4, focus: true, iframe: 40 }],
          ["shield", { power: 4, shieldT: 120, iframe: 9999 }],
          ["rapid", { power: 4, rapidT: 120, iframe: 9999 }],
          ["vial", { power: 4, vialT: 120, vialHits: 3, iframe: 9999 }],
          ["phase", { power: 4, phaseT: 120, iframe: 9999 }],
          ["dash", { power: 4, dash: 12, dashAng: -Math.PI / 2, iframe: 9999 }],
          ["bomb", { power: 4, bombFx: 30, iframe: 9999 }],
        ];
        for (const [name, cfg] of auraShots) {
          await page.evaluate((c) => {
            if (window.__kamDual && window.__kamDual.setAura) window.__kamDual.setAura(c);
          }, cfg);
          await page.waitForTimeout(fast ? 100 : 160);
          await page.screenshot({ path: path.join(htmlDir, `html_aura_${name}.png`) });
        }
        console.log("[HTML] auras", 3 + auraShots.length);
      }
      if (want("items")) {
        await page.evaluate(() => {
          if (window.__kamDual) {
            window.__kamDual.setState("play");
            if (window.__kamDual.clearField) window.__kamDual.clearField();
            if (window.__kamDual.setAura) window.__kamDual.setAura({ power: 1, iframe: 9999 });
            if (window.__kamDual.dropItemsGrid) window.__kamDual.dropItemsGrid();
          }
        });
        await page.waitForTimeout(fast ? 120 : 200);
        await page.screenshot({ path: path.join(htmlDir, "html_items_grid.png") });
        console.log("[HTML] items_grid");
      }
      if (want("elites")) {
        await page.evaluate(() => {
          if (window.__kamDual) {
            window.__kamDual.clearField && window.__kamDual.clearField();
            window.__kamDual.spawnElitesGrid && window.__kamDual.spawnElitesGrid();
            window.__kamDual.setAura && window.__kamDual.setAura({ power: 1, iframe: 9999 });
          }
        });
        await page.waitForTimeout(fast ? 140 : 220);
        await page.screenshot({ path: path.join(htmlDir, "html_elites_grid.png") });
        console.log("[HTML] elites_grid");
      }
      if (want("mumus")) {
        await page.evaluate(() => {
          if (window.__kamDual) {
            window.__kamDual.clearField && window.__kamDual.clearField();
            window.__kamDual.setState && window.__kamDual.setState("play");
            if (typeof player !== "undefined" && player) {
              player.x = PF.x + PF.w / 2; player.y = PF.y + PF.h - 60;
              player.face = -Math.PI / 2; player.aim = -Math.PI / 2;
            }
            // Spawn a small grid of lil/big/icy mumus for dual art
            if (typeof spawnLil === "function" || typeof enemies !== "undefined") {
              enemies = [];
              const kinds = [
                { kind: "lil", icy: false }, { kind: "lil", icy: true }, { kind: "big", icy: false },
                { kind: "big", icy: true }, { kind: "lil", icy: false }, { kind: "lil", icy: false },
              ];
              for (let i = 0; i < kinds.length; i++) {
                const k = kinds[i];
                const x = PF.x + 100 + (i % 3) * 120;
                const y = PF.y + 130 + Math.floor(i / 3) * 130;
                const r = k.kind === "big" ? 22 : 15;
                enemies.push({
                  x, y, r, kind: k.kind, icy: k.icy, t: 40 + i * 8, flash: 0, hp: 999, maxhp: 999,
                  vx: 0, vy: 0, stun: 9999, charm: 0, dead: false,
                });
              }
            }
            if (window.__kamDual.setAura) window.__kamDual.setAura({ power: 1, iframe: 9999 });
          }
        });
        await page.waitForTimeout(fast ? 140 : 220);
        await page.screenshot({ path: path.join(htmlDir, "html_mumus_grid.png") });
        console.log("[HTML] mumus_grid");
      }
      if (want("bosses")) {
        for (let si = 0; si < 7; si++) {
          const portrait = await page.evaluate((idx) => {
            if (!window.__kamDual || !window.__kamDual.spawnBossPortrait) return null;
            window.__kamDual.setState("play");
            return window.__kamDual.spawnBossPortrait(idx);
          }, si);
          // re-pin boss for a few frames so roam does not drift the dual still
          for (let k = 0; k < 6; k++) {
            await page.evaluate(() => {
              if (typeof boss !== "undefined" && boss) {
                const bx = PF.x + PF.w / 2, by = PF.y + 140;
                boss.x = bx; boss.y = by; boss.mtx = bx; boss.mty = by;
                boss.stun = 9999; boss.specialT = 0; boss.dash = false;
                boss.face = Math.PI / 2; bullets = []; pshots = []; dialog = null;
              }
            });
            await page.waitForTimeout(fast ? 40 : 60);
          }
          const tag = portrait || `boss${si}`;
          await page.screenshot({ path: path.join(htmlDir, `html_boss_${tag}.png`) });
          // First boss: also capture intro dialog dual (HTML truth)
          if (si === 0) {
            await page.evaluate(() => {
              if (typeof boss === "undefined" || !boss) return;
              const bd = boss.data || {};
              const lines = (bd.intro && bd.intro.length)
                ? bd.intro.slice()
                : [{ w: 0, t: "You will not leave this jungle, little bear." }, { w: 1, t: "Watch me." }];
              if (typeof startDialog === "function") startDialog(lines, bd);
              else dialog = { boss: bd, queue: lines, i: 0, timer: 9999 };
              if (dialog) { dialog.timer = 9999; dialog.i = 0; }
              const bx = PF.x + PF.w / 2, by = PF.y + 200;
              boss.x = bx; boss.y = by; boss.mtx = bx; boss.mty = by;
              boss.stun = 9999; boss.face = Math.PI / 2;
              if (player) { player.x = bx; player.y = PF.y + 70; player.aim = Math.PI / 2; }
              bullets = []; pshots = []; enemies = [];
            });
            await page.waitForTimeout(fast ? 160 : 240);
            await page.screenshot({ path: path.join(htmlDir, "html_boss_dialog.png") });
            console.log("[HTML] boss_dialog");
          }
        }
        console.log("[HTML] bosses 7");
      }
    } catch (e) {
      console.log("[HTML] phase3 combat skip", e.message || e);
    }
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
    console.log(
      "[GODOT] shots",
      useXvfb ? "(xvfb)" : "(headless)",
      shotFilterActive ? `filter=${[...shotSet].join(",")}` : "filter=all"
    );
    const env = {
      ...process.env,
      PLAYTEST_FAST: fast ? "1" : "0",
      PLAYTEST_FULL: full ? "1" : "0",
      PLAYTEST_SHOTS: shotFilterActive ? [...shotSet].join(",") : "",
    };
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
  const pairs = [];
  if (want("core")) {
    pairs.push(
      ["html_title.png", "godot_title.png", "Title"],
      ["html_menu_outfits.png", "godot_menu_outfits.png", "Outfits"],
      ["html_menu_arsenal.png", "godot_menu_arsenal.png", "Arsenal"],
      ["html_menu_emblems.png", "godot_menu_emblems.png", "Emblems"],
      ["html_menu_leaderboard.png", "godot_menu_leaderboard.png", "Leaderboard"],
      ["html_menu_settings.png", "godot_menu_settings.png", "Settings"],
      ["html_menu_ngselect.png", "godot_menu_ngselect.png", "New Game+"],
      ["html_flow_intro.png", "godot_flow_intro.png", "Intro"],
      ["html_play.png", "godot_play.png", "Play"],
      ["html_flow_pause.png", "godot_flow_pause.png", "Pause"],
      ["html_flow_shop.png", "godot_flow_shop.png", "Shop"],
      ["html_flow_stageclear.png", "godot_flow_stageclear.png", "Stage clear"],
      ["html_end_gameover.png", "godot_end_gameover.png", "Game over"],
      ["html_end_win.png", "godot_end_win.png", "Win"],
    );
  }
  if (want("power6")) pairs.push(["html_play_firing.png", "godot_play_power6.png", "Combat"]);
  if (want("weapons")) {
    for (const w of ["laser","homing","wave","scatter","gatling","grenade","voidripper","lotus","shock","spread"]) {
      const h = `html_wep_${w}.png`, g = `godot_wep_${w}.png`;
      if (godotShots.includes(g) || htmlShots.includes(h)) pairs.push([h, g, `Weapon · ${w}`]);
    }
  }
  if (want("melee")) {
    for (const m of ["katana","lash","scythe","hammer","claws"]) {
      const h = `html_melee_${m}.png`, g = `godot_melee_${m}.png`;
      if (godotShots.includes(g) || htmlShots.includes(h)) pairs.push([h, g, `Melee · ${m}`]);
    }
  }
  if (want("specials")) {
    for (const s of ["laser","mech","bearzooka","vault","stampede","badger","sixth","revenge","kiss","kraken","void"]) {
      const h = `html_special_${s}.png`, g = `godot_special_${s}.png`;
      if (godotShots.includes(g) || htmlShots.includes(h)) pairs.push([h, g, `Special · ${s}`]);
    }
  }
  if (want("aura")) {
    for (const pwr of [1, 3, 6]) {
      const h = `html_aura_power_${pwr}.png`, g = `godot_aura_power_${pwr}.png`;
      if (godotShots.includes(g) || htmlShots.includes(h)) pairs.push([h, g, `Aura · power ${pwr}`]);
    }
    for (const a of ["focus", "shield", "rapid", "vial", "phase", "dash", "bomb"]) {
      const h = `html_aura_${a}.png`, g = `godot_aura_${a}.png`;
      if (godotShots.includes(g) || htmlShots.includes(h)) pairs.push([h, g, `Aura · ${a}`]);
    }
  }
  if (want("items")) {
    if (godotShots.includes("godot_items_grid.png") || htmlShots.includes("html_items_grid.png")) {
      pairs.push(["html_items_grid.png", "godot_items_grid.png", "Items grid"]);
    }
  }
  if (want("elites")) {
    if (godotShots.includes("godot_elites_grid.png") || htmlShots.includes("html_elites_grid.png")) {
      pairs.push(["html_elites_grid.png", "godot_elites_grid.png", "Elites grid"]);
    }
  }
  if (want("mumus")) {
    if (godotShots.includes("godot_mumus_grid.png") || htmlShots.includes("html_mumus_grid.png")) {
      pairs.push(["html_mumus_grid.png", "godot_mumus_grid.png", "Mumus grid (lil/big/icy)"]);
    }
  }
  if (want("mechanics")) {
    if (godotShots.includes("godot_mechanics_bleed_graze.png")) {
      pairs.push(["", "godot_mechanics_bleed_graze.png", "Mechanics · power bleed + graze"]);
    }
  }
  if (want("pickups") || want("mechanics")) {
    if (godotShots.includes("godot_pickups_vacuum.png")) {
      pairs.push(["", "godot_pickups_vacuum.png", "Pickups · collect-line vacuum"]);
    }
  }
  if (want("bosses")) {
    for (const f of godotShots.filter((x) => x.startsWith("godot_boss_") && !x.includes("dialog") && !x.includes("live"))) {
      const key = f.replace("godot_boss_", "").replace(".png", "");
      pairs.push([`html_boss_${key}.png`, f, `Boss · ${key}`]);
    }
    for (const f of htmlShots.filter((x) => x.startsWith("html_boss_") && !x.includes("dialog"))) {
      const key = f.replace("html_boss_", "").replace(".png", "");
      const g = `godot_boss_${key}.png`;
      if (!pairs.some((p) => p[0] === f)) pairs.push([f, g, `Boss · ${key}`]);
    }
    if (godotShots.includes("godot_boss_dialog.png") || htmlShots.includes("html_boss_dialog.png")) {
      pairs.push(["html_boss_dialog.png", "godot_boss_dialog.png", "Boss · intro dialog"]);
    }
    if (godotShots.includes("godot_boss_ape_live.png")) {
      pairs.push(["html_boss_ape.png", "godot_boss_ape_live.png", "Boss · ape live ambience"]);
    }
  }
  if (want("wardrobe")) {
    for (const f of godotShots.filter((x) => x.startsWith("godot_menu_outfit_") && !x.includes("anim"))) {
      const key = f.replace("godot_menu_outfit_", "").replace(".png", "");
      const h = `html_menu_outfit_${key}.png`;
      if (htmlShots.includes(h) || godotShots.includes(f)) pairs.push([h, f, `Outfit menu · ${key}`]);
    }
  }

  let rows = "";
  for (const [h, g, label] of pairs) {
    const hasH = htmlShots.includes(h);
    const hasG = godotShots.includes(g);
    rows += `<tr><th colspan="2">${label}</th></tr><tr>
      <td><div class="cap">HTML (source of truth)</div>${hasH ? `<img src="html/${h}" width="480"/>` : "<em>missing</em>"}</td>
      <td><div class="cap">Godot port</div>${hasG ? `<img src="godot/${g}" width="480"/>` : "<em>missing</em>"}</td></tr>`;
  }
  // Extra Godot-only rows: only when their group is wanted (or no filter)
  const extraGodot = godotShots.filter((f) => {
    if (f.includes("bobina_") || f.includes("gif_")) return want("anims") || want("faces");
    if (f.includes("menu_outfit_anim_")) return want("wardrobe");
    if (f.includes("play_face_") || f.includes("hud_face_")) return want("faces");
    return false;
  });
  for (const g of extraGodot) {
    rows += `<tr><th colspan="2">${g}</th></tr><tr><td colspan="2"><img src="godot/${g}" width="480"/></td></tr>`;
  }
  const modeLabel = shotFilterActive
    ? `full=${!fast} shots=${[...shotSet].join(",")}`
    : `mode=${fast ? "fast" : "full"} shots=all`;
  fs.writeFileSync(
    path.join(outDir, "index.html"),
    `<!DOCTYPE html><html><head><meta charset="utf-8"/><title>Dual playtest</title>
<style>body{font-family:system-ui;background:#12081a;color:#f0e6f5;margin:16px}
table{border-collapse:collapse}td,th{border:1px solid #4a3058;padding:8px;vertical-align:top}
img{background:#000;max-width:100%}.cap{color:#ff9ecb;margin-bottom:4px}code{color:#ffe08a}</style></head><body>
<h1>HTML vs Godot dual playtest</h1>
<p>Generated ${new Date().toISOString()} · ${modeLabel}</p>
<p>HTML ${htmlShots.length} shots · Godot ${godotShots.length} shots · pairs ${pairs.length} · open this file after each port pass.</p>
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
  console.log(
    "[DUAL] start",
    fast ? "fast" : "full",
    htmlOnly ? "html-only" : godotOnly ? "godot-only" : "both",
    shotFilterActive ? `shots=${[...shotSet].join(",")}` : "shots=all"
  );
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
