/**
 * Bobina.moe public mini-profile helper.
 * GET https://bobina.moe/api/user/<bc_id>/mini
 * CDN-cached ~2 min; we cache in-process the same window.
 */
const ISSUER = process.env.BOBINA_ISSUER || 'https://bobina.moe';
const CACHE_TTL_MS = 120_000;

/** @type {Map<string, { at: number, data: object|null }>} */
const cache = new Map();

/**
 * @param {string} bcId
 * @returns {Promise<{ id: string, username: string|null, displayName: string|null, image: string|null, profileUrl: string|null }|null>}
 */
async function fetchMini(bcId) {
  if (!bcId || typeof bcId !== 'string') return null;
  const key = bcId.trim();
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.data;

  try {
    const r = await fetch(`${ISSUER}/api/user/${encodeURIComponent(key)}/mini`, {
      headers: { Accept: 'application/json' },
    });
    if (r.status === 404) {
      cache.set(key, { at: Date.now(), data: null });
      return null;
    }
    if (!r.ok) {
      // Don't cache hard failures long — short negative so leaderboard still works offline
      return hit?.data ?? null;
    }
    const raw = await r.json();
    const username = raw.username || null;
    const data = {
      id: raw.id || key,
      username,
      displayName: raw.displayName || raw.name || username,
      image: raw.image || raw.picture || null,
      profileUrl: username ? `${ISSUER}/${username}` : null,
    };
    cache.set(key, { at: Date.now(), data });
    return data;
  } catch (e) {
    console.warn('bobina mini failed', key, e.message);
    return hit?.data ?? null;
  }
}

/** Resolve display fields for a linked player (fresh username preferred). */
async function resolveLinkedDisplay(bcId, fallback = {}) {
  const mini = await fetchMini(bcId);
  if (!mini) {
    return {
      bcId,
      bobinaUsername: fallback.bobinaUsername || fallback.cached_username || null,
      avatar: fallback.avatar || fallback.cached_avatar || null,
      displayName: fallback.bobinaUsername
        ? `@${fallback.bobinaUsername}`
        : fallback.name || 'Anonymous Mumu Slayer',
      profileUrl: fallback.bobinaUsername
        ? `${ISSUER}/${fallback.bobinaUsername}`
        : null,
      deleted: true,
    };
  }
  return {
    bcId: mini.id,
    bobinaUsername: mini.username,
    avatar: mini.image,
    displayName: mini.username ? `@${mini.username}` : mini.displayName || 'Bobina player',
    profileUrl: mini.profileUrl,
    deleted: false,
  };
}

function bustCache(bcId) {
  if (bcId) cache.delete(bcId);
}

module.exports = {
  fetchMini,
  resolveLinkedDisplay,
  bustCache,
  ISSUER,
};
