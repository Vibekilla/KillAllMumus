/**
 * Cloud progress for Bobina-linked players.
 * Merges local device state with server so emblems, arsenal, stats, shop, etc.
 * survive across browsers/devices.
 */

const PROGRESS_VERSION = 1;

/** Empty canonical progress blob. */
function emptyProgress() {
  return {
    v: PROGRESS_VERSION,
    emblems: {},
    estats: {
      kills: 0,
      graze: 0,
      best: 0,
      clears: 0,
      dashes: 0,
      specials: 0,
      bombs: 0,
      bosses: 0,
    },
    arsenal: { w: ['laser'], s: ['mech', 'bearzooka'], m: ['katana'], i: ['honeycomb', 'bulltears', 'bullsouls'] },
    heads: 0,
    shopUnlocks: {},
    consum: {},
    ngUnlocked: 0,
    hellCleared: false,
    difficulty: 0,
    ngPlus: 0,
    outfit: 'og',
    pose: 0,
    face: 0,
    handle: '',
    binds: null,
    settings: {
      musicVol: null,
      sfxVol: null,
      follow: null,
      mspeed: null,
      speedrun: false,
      autofire: true,
      ui: null,
    },
  };
}

function asObj(v) {
  return v && typeof v === 'object' && !Array.isArray(v) ? v : {};
}

function maxNum(a, b) {
  const x = Number(a) || 0;
  const y = Number(b) || 0;
  return x > y ? x : y;
}

function unionBoolMap(a, b) {
  const out = { ...asObj(a) };
  for (const [k, v] of Object.entries(asObj(b))) {
    if (v) out[k] = true;
  }
  return out;
}

function maxNumMap(a, b) {
  const out = { ...asObj(a) };
  for (const [k, v] of Object.entries(asObj(b))) {
    out[k] = maxNum(out[k], v);
  }
  return out;
}

function unionArray(a, b, cap) {
  const seen = new Set();
  const out = [];
  for (const x of [...(Array.isArray(a) ? a : []), ...(Array.isArray(b) ? b : [])]) {
    if (x == null || seen.has(x)) continue;
    seen.add(x);
    out.push(x);
    if (cap && out.length >= cap) break;
  }
  return out;
}

/**
 * Merge two progress blobs. Unlocks / stats take the max; loadouts union.
 * Preference fields prefer `preferred` when both set (usually the newer client snapshot).
 */
function mergeProgress(server, client, { preferClientPrefs = true } = {}) {
  const s = { ...emptyProgress(), ...asObj(server) };
  const c = { ...emptyProgress(), ...asObj(client) };
  const pref = preferClientPrefs ? c : s;
  const other = preferClientPrefs ? s : c;

  const estatsKeys = new Set([
    ...Object.keys(asObj(s.estats)),
    ...Object.keys(asObj(c.estats)),
  ]);
  const estats = {};
  for (const k of estatsKeys) {
    estats[k] = maxNum(s.estats?.[k], c.estats?.[k]);
  }

  const sAr = asObj(s.arsenal);
  const cAr = asObj(c.arsenal);

  return {
    v: PROGRESS_VERSION,
    emblems: unionBoolMap(s.emblems, c.emblems),
    estats,
    arsenal: {
      w: unionArray(sAr.w, cAr.w, 5),
      s: unionArray(sAr.s, cAr.s, 5),
      m: unionArray(sAr.m, cAr.m, 2),
      i: unionArray(sAr.i, cAr.i, 3),
    },
    heads: maxNum(s.heads, c.heads),
    shopUnlocks: unionBoolMap(s.shopUnlocks, c.shopUnlocks),
    consum: maxNumMap(s.consum, c.consum),
    ngUnlocked: Math.min(100, maxNum(s.ngUnlocked, c.ngUnlocked)),
    hellCleared: !!(s.hellCleared || c.hellCleared),
    difficulty: Math.max(0, Math.min(2, Number(pref.difficulty ?? other.difficulty) || 0)),
    ngPlus: Math.min(
      100,
      maxNum(s.ngPlus, c.ngPlus) // level selection can be max unlocked-aware client-side
    ),
    outfit: pref.outfit || other.outfit || 'og',
    pose: Number(pref.pose ?? other.pose) || 0,
    face: Number(pref.face ?? other.face) || 0,
    handle: String(pref.handle || other.handle || '').replace(/^@+/, '').slice(0, 32),
    binds: pref.binds && typeof pref.binds === 'object' ? pref.binds : other.binds,
    settings: {
      musicVol: pickNum(pref.settings?.musicVol, other.settings?.musicVol),
      sfxVol: pickNum(pref.settings?.sfxVol, other.settings?.sfxVol),
      follow: pickNum(pref.settings?.follow, other.settings?.follow),
      mspeed: pickNum(pref.settings?.mspeed, other.settings?.mspeed),
      speedrun: !!(pref.settings?.speedrun || other.settings?.speedrun),
      autofire:
        pref.settings?.autofire != null
          ? !!pref.settings.autofire
          : other.settings?.autofire != null
            ? !!other.settings.autofire
            : true,
      ui: pref.settings?.ui || other.settings?.ui || null,
    },
  };
}

function pickNum(a, b) {
  if (a != null && !Number.isNaN(Number(a))) return Number(a);
  if (b != null && !Number.isNaN(Number(b))) return Number(b);
  return null;
}

/** Sanitize client payload size / shape. */
function sanitizeProgress(raw) {
  const base = emptyProgress();
  const p = asObj(raw);
  const merged = mergeProgress(base, p, { preferClientPrefs: true });
  // Cap JSON size ~200KB
  const json = JSON.stringify(merged);
  if (json.length > 200_000) {
    throw new Error('progress payload too large');
  }
  return merged;
}

async function ensureProgressColumn(pool) {
  await pool.query(`
    ALTER TABLE players
      ADD COLUMN IF NOT EXISTS progress JSONB NOT NULL DEFAULT '{}'::jsonb,
      ADD COLUMN IF NOT EXISTS progress_updated_at TIMESTAMPTZ;
  `);
}

async function getProgress(pool, bcId) {
  const r = await pool.query(
    `SELECT progress, progress_updated_at FROM players WHERE bc_id = $1`,
    [bcId]
  );
  if (!r.rows.length) return { progress: emptyProgress(), updatedAt: null };
  const row = r.rows[0];
  const prog =
    row.progress && Object.keys(row.progress).length
      ? mergeProgress(emptyProgress(), row.progress)
      : emptyProgress();
  return {
    progress: prog,
    updatedAt: row.progress_updated_at,
  };
}

/**
 * Merge client progress into server and store.
 * Returns the merged blob.
 */
async function putProgress(pool, bcId, clientProgress) {
  const clean = sanitizeProgress(clientProgress);
  const current = await getProgress(pool, bcId);
  const merged = mergeProgress(current.progress, clean, { preferClientPrefs: true });

  await pool.query(
    `UPDATE players SET
       progress = $2::jsonb,
       progress_updated_at = NOW(),
       high_score = GREATEST(high_score, $3),
       kills = GREATEST(kills, $4),
       updated_at = NOW()
     WHERE bc_id = $1`,
    [
      bcId,
      JSON.stringify(merged),
      Number(merged.estats?.best) || 0,
      Number(merged.estats?.kills) || 0,
    ]
  );

  return { progress: merged, updatedAt: new Date().toISOString() };
}

module.exports = {
  PROGRESS_VERSION,
  emptyProgress,
  mergeProgress,
  sanitizeProgress,
  ensureProgressColumn,
  getProgress,
  putProgress,
};
