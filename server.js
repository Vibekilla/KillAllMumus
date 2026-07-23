/**
 * Bobina: Kill All Mumus — production server
 * Express static game + Postgres-backed leaderboard
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const { Pool } = require('pg');

let sharp = null;
try {
  sharp = require('sharp');
} catch (e) {
  console.error('sharp unavailable:', e.message);
}

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOSTNAME || '127.0.0.1';
const GROUP = process.env.ARTIFACT_GROUP || 'web_development';
const PUBLIC_ORIGIN = process.env.PUBLIC_ORIGIN || 'https://killallmumus.com';
const BASE = process.env.PUBLIC_BASE || '';

if (!process.env.DATABASE_URL && !process.env.PGPASSWORD) {
  console.error('FATAL: DATABASE_URL (or PG* vars) required');
  process.exit(1);
}

const pool = new Pool(
  process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL, max: 10 }
    : {
        host: process.env.PGHOST || '127.0.0.1',
        port: Number(process.env.PGPORT) || 5433,
        user: process.env.PGUSER || 'killallmumus',
        password: process.env.PGPASSWORD,
        database: process.env.PGDATABASE || 'killallmumus',
        max: 10,
      }
);

app.use(express.json({ limit: '32kb' }));

function clean(s, max) {
  return String(s == null ? '' : s)
    .replace(/[<>\n\r\t"']/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}
const esc = (s) =>
  String(s).replace(
    /[&<>"']/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
  );

async function dbQuery(sql, params) {
  const r = await pool.query(sql, params || []);
  return r.rows || [];
}
async function dbExec(sql, params) {
  await pool.query(sql, params || []);
}

// Keep in sync with the client OUTFITS list (public/index.html).
const OUTFIT_KEYS = [
  'og', 'maid', 'nanosuit', 'badger', 'viking', 'ourbit', 'bullbina', 'monke',
  'pickle', 'emblem', 'labrat', 'neko', 'kigurumi', 'cheese', 'business',
  'jester', 'samurai', 'bride', 'angel', 'golden', 'succubus', 'voidling',
  'honeybee', 'banana', 'squirrely', 'honeypot', 'empress', 'cabal',
];

async function topScores(limit) {
  const n = Math.max(1, Math.min(200, Number(limit) || 100));
  const rows = await dbQuery(
    `SELECT name, handle, score, kills, rank, mode, won, outfit
     FROM bobina_scores
     ORDER BY score DESC
     LIMIT $1`,
    [n]
  );
  // pg returns BIGINT as string — coerce for the game client
  return rows.map((r) => ({
    ...r,
    score: Number(r.score),
    kills: Number(r.kills),
    won: Number(r.won),
  }));
}

app.get('/api/scores', async (req, res) => {
  try {
    res.json(await topScores(100));
  } catch (e) {
    console.error('GET /api/scores', e.message);
    res.json([]);
  }
});

// simple per-IP throttle
const lastPost = {};
app.post('/api/scores', async (req, res) => {
  try {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'x';
    const now = Date.now();
    if (lastPost[ip] && now - lastPost[ip] < 2500) {
      return res.status(429).json({ ok: false, error: 'slow down' });
    }
    lastPost[ip] = now;
    let { name, handle, score, kills, rank, mode, won, outfit } = req.body || {};
    handle = clean(handle, 16).replace(/^@+/, '');
    name = clean(name, 16) || (handle ? '@' + handle : 'Anon');
    score = Math.max(0, Math.min(999999999999, parseInt(score, 10) || 0));
    kills = Math.max(0, Math.min(100000, parseInt(kills, 10) || 0));
    rank = clean(rank, 3);
    mode = /^(NORMAL|HARD|HELL)(\+\d{1,2})?$/.test(mode) ? mode : 'NORMAL';
    won = won ? 1 : 0;
    outfit = OUTFIT_KEYS.includes(outfit) ? outfit : 'og';
    const BLOCKED = [
      'test', 'testuser', 'tester', 'testing', 'admin', 'anon', 'anonymous',
      'null', 'undefined',
    ];
    if (handle && BLOCKED.includes(handle.toLowerCase())) {
      return res.json({ ok: true, updated: false, scores: await topScores(100) });
    }
    // dedup by X handle — keep only the player's best run
    if (handle) {
      const rows = await dbQuery(
        'SELECT MAX(score) AS best FROM bobina_scores WHERE handle = $1',
        [handle]
      );
      const best = rows[0] && rows[0].best != null ? Number(rows[0].best) : -1;
      if (score <= best) {
        return res.json({ ok: true, updated: false, scores: await topScores(100) });
      }
      await dbExec('DELETE FROM bobina_scores WHERE handle = $1', [handle]);
    }
    await dbExec(
      `INSERT INTO bobina_scores (name, handle, score, kills, rank, mode, won, outfit)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [name, handle, score, kills, rank, mode, won, outfit]
    );
    res.json({ ok: true, updated: true, scores: await topScores(100) });
  } catch (e) {
    console.error('POST /api/scores', e.message);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Themed share page that unfurls on X/social
app.get('/share/:type', (req, res) => {
  const won = req.params.type === 'win';
  const score = clean(req.query.s, 12) || '0';
  const kills = clean(req.query.k, 8) || '0';
  const rank = clean(req.query.r, 3) || 'D';
  const handle = clean(req.query.h, 16).replace(/^@+/, '');
  const q = `s=${encodeURIComponent(score)}&k=${encodeURIComponent(kills)}&r=${encodeURIComponent(rank)}${handle ? '&h=' + encodeURIComponent(handle) : ''}`;
  const img = `${PUBLIC_ORIGIN}${BASE}/share-img/${won ? 'win' : 'over'}.png?${q}`;
  const who = handle ? `@${esc(handle)}` : 'A challenger';
  const title = won
    ? 'BOBO IS SAVED! — Bobina: Kill All Mumus!!'
    : 'Down but not out — Bobina: Kill All Mumus!!';
  const desc = won
    ? `${who} exterminated ${esc(kills)} Mumus (Rank ${esc(rank)}, ${esc(score)} pts) and saved Bobo! Can you beat it?`
    : `${who} took down ${esc(kills)} Mumus (Rank ${esc(rank)}, ${esc(score)} pts) before the horde won. Think you can do better?`;
  res.type('html').send(`<!DOCTYPE html><html><head><meta charset="utf-8">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${desc}">
<meta property="og:image" content="${img}">
<meta property="og:url" content="${PUBLIC_ORIGIN}${BASE}/">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${desc}">
<meta name="twitter:image" content="${img}">
<meta http-equiv="refresh" content="0; url=${BASE || '/'}">
<title>${esc(title)}</title></head>
<body style="background:#12060c;color:#fff;font-family:sans-serif;text-align:center;padding-top:80px">
Loading Bobina: Kill All Mumus!! … <a style="color:#ff7ab5" href="${BASE || '/'}">Play now</a></body></html>`);
});

function shareSvg({ won, score, kills, rank, handle }) {
  const who = handle ? '@' + esc(handle) : 'A CHALLENGER';
  const g1 = won ? '#2a1030' : '#1a0810',
    g2 = won ? '#4a1828' : '#3a1020';
  const accent = won ? '#ffe08a' : '#ff6b8a';
  const status = won ? 'BOBO IS SAVED!' : 'DOWN BUT NOT OUT';
  const stat = (cx, label, val, fs) => `
    <rect x="${cx - 150}" y="300" width="300" height="152" rx="16" fill="#ffffff" fill-opacity="0.06" stroke="${accent}" stroke-opacity="0.4" stroke-width="2"/>
    <text x="${cx}" y="350" text-anchor="middle" font-family="Arial, sans-serif" font-weight="700" font-size="26" fill="#c8b0d0" letter-spacing="4">${label}</text>
    <text x="${cx}" y="424" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="${fs}" fill="#ffffff">${esc(val)}</text>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
    <defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${g1}"/><stop offset="1" stop-color="${g2}"/></linearGradient></defs>
    <rect width="1200" height="630" fill="url(#bg)"/>
    <rect x="16" y="16" width="1168" height="598" rx="26" fill="none" stroke="${accent}" stroke-opacity="0.35" stroke-width="4"/>
    <text x="600" y="98" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="50" fill="#ff5b8d">BOBINA: KILL ALL MUMUS!!</text>
    <text x="600" y="176" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="64" fill="${accent}">${status}</text>
    <text x="600" y="228" text-anchor="middle" font-family="Arial, sans-serif" font-size="30" fill="#e8cfe0">${who} vs the Mumu horde</text>
    ${stat(255, 'MUMUS', kills, 56)}
    ${stat(600, 'RANK', rank, 62)}
    ${stat(945, 'SCORE', score, String(score).length > 6 ? 44 : 56)}
    <text x="600" y="560" text-anchor="middle" font-family="Arial, sans-serif" font-weight="700" font-size="26" fill="#9a8ba8">#KillAllMumus   ·   $EMBLEM   ·   bobina.moe</text>
  </svg>`;
}

app.get('/share-img/:type.png', async (req, res) => {
  try {
    const won = req.params.type === 'win';
    const score = clean(req.query.s, 12) || '0';
    const kills = clean(req.query.k, 8) || '0';
    const rank = clean(req.query.r, 3) || 'D';
    const handle = clean(req.query.h, 16).replace(/^@+/, '');
    res.set('Cache-Control', 'public, max-age=86400');
    if (!sharp) {
      return res.redirect(`${BASE}/${won ? 'share-win.png' : 'share-over.png'}`);
    }
    const svg = shareSvg({ won, score, kills, rank, handle });
    const png = await sharp(Buffer.from(svg))
      .png({ compressionLevel: 9, palette: true, quality: 72, effort: 7 })
      .toBuffer();
    res.type('png').send(png);
  } catch (e) {
    res.status(500).send('err');
  }
});

app.get('/api/health', async (req, res) => {
  try {
    const r = await pool.query('SELECT COUNT(*)::int AS n FROM bobina_scores');
    res.json({
      ok: true,
      group: GROUP,
      sharp: !!sharp,
      db: 'postgres',
      scores: r.rows[0].n,
    });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.use(express.static(path.join(__dirname, 'public')));

const server = app.listen(PORT, HOST, () => {
  console.log(`bobina-blaster listening on http://${HOST}:${PORT}`);
});

async function shutdown(signal) {
  console.log(`${signal} received, shutting down…`);
  server.close();
  try {
    await pool.end();
  } catch (_) {
    /* ignore */
  }
  process.exit(0);
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
