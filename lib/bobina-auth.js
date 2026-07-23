/**
 * Bobina.moe OIDC (Authorization Code + PKCE, ES256 ID tokens).
 * Scopes: openid profile social
 */
const crypto = require('crypto');
const { createRemoteJWKSet, jwtVerify } = require('jose');
const { fetchMini, bustCache } = require('./bobina-profile');
const { claimScoresForPlayer } = require('./db');

const ISSUER = process.env.BOBINA_ISSUER || 'https://bobina.moe';
const DISCOVERY =
  process.env.BOBINA_DISCOVERY ||
  `${ISSUER}/.well-known/openid-configuration`;

const SCOPES = 'openid profile social';
const SESSION_COOKIE = 'kam_session';
const SESSION_DAYS = 30;
const SESSION_MS = SESSION_DAYS * 864e5;

let cachedDiscovery = null;
let cachedJwks = null;

function configured() {
  return Boolean(process.env.BOBINA_CLIENT_ID && process.env.BOBINA_CLIENT_SECRET);
}

function redirectUri(req) {
  if (process.env.BOBINA_REDIRECT_URI) return process.env.BOBINA_REDIRECT_URI;
  const proto = (req.headers['x-forwarded-proto'] || req.protocol || 'https').split(',')[0].trim();
  const host = (req.headers['x-forwarded-host'] || req.headers.host || 'killallmumus.com').split(',')[0].trim();
  return `${proto}://${host}/auth/bobina/callback`;
}

function isHttps(req) {
  const xf = String(req.headers['x-forwarded-proto'] || '')
    .split(',')[0]
    .trim()
    .toLowerCase();
  return xf === 'https' || req.secure === true || process.env.NODE_ENV === 'production';
}

function setSessionCookie(res, req, sid) {
  res.cookie(SESSION_COOKIE, sid, {
    httpOnly: true,
    secure: isHttps(req),
    sameSite: 'lax',
    path: '/',
    maxAge: SESSION_MS,
  });
}

async function discovery() {
  if (cachedDiscovery) return cachedDiscovery;
  const r = await fetch(DISCOVERY, { headers: { Accept: 'application/json' } });
  if (!r.ok) throw new Error(`OIDC discovery failed: ${r.status}`);
  cachedDiscovery = await r.json();
  return cachedDiscovery;
}

async function jwks() {
  if (cachedJwks) return cachedJwks;
  const d = await discovery();
  cachedJwks = createRemoteJWKSet(new URL(d.jwks_uri));
  return cachedJwks;
}

function b64url(buf) {
  return Buffer.from(buf)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function pkcePair() {
  const verifier = b64url(crypto.randomBytes(32));
  const challenge = b64url(crypto.createHash('sha256').update(verifier).digest());
  return { verifier, challenge };
}

function newId() {
  return b64url(crypto.randomBytes(24));
}

function cleanHandle(s) {
  return String(s == null ? '' : s)
    .replace(/^@+/, '')
    .replace(/[^A-Za-z0-9_]/g, '')
    .slice(0, 32);
}

/**
 * Upsert player from OIDC claims + mini profile, claim scores, return summary.
 */
async function resolvePlayerAccount(pool, claims, claimHandle) {
  const bcId = claims.sub;
  if (!bcId || typeof bcId !== 'string') {
    throw new Error('No subject (bc_id) in token');
  }

  bustCache(bcId);
  const mini = await fetchMini(bcId);
  const bobinaUsername =
    mini?.username || claims.username || claims.preferred_username || null;
  const avatar = mini?.image || claims.picture || null;
  const xId = claims.x_id != null ? String(claims.x_id) : null;
  const xUsername = claims.x_username
    ? cleanHandle(claims.x_username)
    : null;

  await pool.query(
    `INSERT INTO players (bc_id, cached_username, cached_avatar, cached_x_id, cached_x_username, updated_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (bc_id) DO UPDATE SET
       cached_username = COALESCE(EXCLUDED.cached_username, players.cached_username),
       cached_avatar = COALESCE(EXCLUDED.cached_avatar, players.cached_avatar),
       cached_x_id = COALESCE(EXCLUDED.cached_x_id, players.cached_x_id),
       cached_x_username = COALESCE(EXCLUDED.cached_x_username, players.cached_x_username),
       updated_at = NOW()`,
    [bcId, bobinaUsername, avatar, xId, xUsername]
  );

  const claim = await claimScoresForPlayer(pool, {
    bcId,
    bobinaUsername,
    avatar,
    xId,
    xUsername,
    claimHandle: claimHandle || xUsername || bobinaUsername,
  });

  console.log('[bobina] resolved account', {
    bcId,
    bobinaUsername,
    xUsername,
    xId,
    claimHandle,
    claim,
  });

  return {
    bcId,
    bobinaUsername,
    avatar,
    xId,
    xUsername,
    claim,
    profileUrl: bobinaUsername ? `${ISSUER}/${bobinaUsername}` : null,
  };
}

/**
 * Re-resolve + re-claim for an existing session player (post-login safety net).
 */
async function syncPlayer(pool, player) {
  bustCache(player.bc_id);
  const mini = await fetchMini(player.bc_id);
  const bobinaUsername = mini?.username || player.cached_username || null;
  const avatar = mini?.image || player.cached_avatar || null;
  const xUsername = player.cached_x_username || null;
  const xId = player.cached_x_id || null;

  await pool.query(
    `UPDATE players SET
       cached_username = COALESCE($2, cached_username),
       cached_avatar = COALESCE($3, cached_avatar),
       updated_at = NOW()
     WHERE bc_id = $1`,
    [player.bc_id, bobinaUsername, avatar]
  );

  const claim = await claimScoresForPlayer(pool, {
    bcId: player.bc_id,
    bobinaUsername,
    avatar,
    xId,
    xUsername,
    claimHandle: xUsername || bobinaUsername,
  });

  const scores = await pool.query(
    `SELECT id, name, handle, score, kills, rank, mode, won, outfit, bc_id, bobina_username
     FROM bobina_scores WHERE bc_id = $1 ORDER BY score DESC LIMIT 5`,
    [player.bc_id]
  );

  return {
    bcId: player.bc_id,
    username: bobinaUsername,
    avatar,
    xId,
    xUsername,
    claim,
    scores: scores.rows.map((r) => ({
      id: Number(r.id),
      name: r.name,
      handle: r.handle,
      score: Number(r.score),
      kills: Number(r.kills),
      bcId: r.bc_id,
      bobinaUsername: r.bobina_username,
    })),
    profileUrl: bobinaUsername ? `${ISSUER}/${bobinaUsername}` : null,
  };
}

function mountBobinaAuth(app, pool) {
  app.get('/auth/bobina/status', async (_req, res) => {
    res.json({
      configured: configured(),
      issuer: ISSUER,
      scopes: SCOPES,
      loginPath: '/auth/bobina',
    });
  });

  app.get('/auth/bobina', async (req, res) => {
    try {
      if (!configured()) {
        return res.status(503).type('html').send(missingCredsHtml());
      }
      const d = await discovery();
      const state = newId();
      const nonce = newId();
      const { verifier, challenge } = pkcePair();
      const claimHandle = cleanHandle(req.query.claim_handle || req.query.handle || '');
      await pool.query(
        `INSERT INTO oauth_states (state, code_verifier, nonce, claim_handle) VALUES ($1, $2, $3, $4)`,
        [state, verifier, nonce, claimHandle || null]
      );
      const url = new URL(d.authorization_endpoint);
      url.searchParams.set('response_type', 'code');
      url.searchParams.set('client_id', process.env.BOBINA_CLIENT_ID);
      url.searchParams.set('redirect_uri', redirectUri(req));
      url.searchParams.set('scope', SCOPES);
      url.searchParams.set('state', state);
      url.searchParams.set('nonce', nonce);
      url.searchParams.set('code_challenge', challenge);
      url.searchParams.set('code_challenge_method', 'S256');
      res.redirect(url.toString());
    } catch (e) {
      console.error('GET /auth/bobina', e);
      res.status(500).send('Bobina login failed to start');
    }
  });

  app.get('/auth/bobina/callback', async (req, res) => {
    try {
      if (!configured()) {
        return res.status(503).send('Bobina OAuth is not configured on this server');
      }
      const { code, state, error, error_description: errDesc } = req.query;
      if (error) {
        return res.status(400).send(`Bobina auth error: ${error} ${errDesc || ''}`);
      }
      if (!code || !state) return res.status(400).send('Missing code/state');

      const st = await pool.query(
        `DELETE FROM oauth_states WHERE state = $1
         RETURNING code_verifier, nonce, claim_handle`,
        [String(state)]
      );
      if (!st.rows.length) return res.status(400).send('Invalid or expired state');
      const { code_verifier: verifier, nonce, claim_handle: claimHandle } = st.rows[0];

      const d = await discovery();
      const body = new URLSearchParams({
        grant_type: 'authorization_code',
        code: String(code),
        redirect_uri: redirectUri(req),
        client_id: process.env.BOBINA_CLIENT_ID,
        client_secret: process.env.BOBINA_CLIENT_SECRET,
        code_verifier: verifier,
      });
      const tokRes = await fetch(d.token_endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          Accept: 'application/json',
        },
        body,
      });
      const tok = await tokRes.json();
      if (!tokRes.ok) {
        console.error('token error', tok);
        return res.status(400).send('Token exchange failed');
      }

      let claims = {};
      if (tok.id_token) {
        const { payload } = await jwtVerify(tok.id_token, await jwks(), {
          issuer: ISSUER,
          audience: process.env.BOBINA_CLIENT_ID,
        });
        if (payload.nonce && payload.nonce !== nonce) {
          return res.status(400).send('Nonce mismatch');
        }
        claims = payload;
      }
      if (tok.access_token) {
        try {
          const ui = await fetch(d.userinfo_endpoint, {
            headers: { Authorization: `Bearer ${tok.access_token}` },
          });
          if (ui.ok) claims = { ...claims, ...(await ui.json()) };
        } catch (e) {
          console.warn('userinfo failed', e.message);
        }
      }

      const resolved = await resolvePlayerAccount(pool, claims, claimHandle);

      const sid = newId();
      const expires = new Date(Date.now() + SESSION_MS);
      await pool.query(
        `INSERT INTO sessions (id, bc_id, expires_at) VALUES ($1, $2, $3)`,
        [sid, resolved.bcId, expires.toISOString()]
      );

      setSessionCookie(res, req, sid);

      const q = new URLSearchParams({
        bobina: '1',
        linked: String(resolved.claim.claimed || 0),
        score: String(resolved.claim.highScore || 0),
      });
      res.redirect(`/?${q.toString()}`);
    } catch (e) {
      console.error('GET /auth/bobina/callback', e);
      res.status(500).send('Bobina callback failed: ' + (e.message || 'error'));
    }
  });

  app.post('/auth/logout', async (req, res) => {
    const sid = req.cookies?.[SESSION_COOKIE];
    if (sid) {
      await pool.query(`DELETE FROM sessions WHERE id = $1`, [sid]);
      res.clearCookie(SESSION_COOKIE, { path: '/' });
    }
    res.json({ ok: true });
  });

  /** Re-run mini resolve + score claim for the current session. */
  app.post('/api/sync', async (req, res) => {
    try {
      const player = await sessionPlayer(pool, req);
      if (!player) {
        return res.status(401).json({ ok: false, authenticated: false });
      }
      const result = await syncPlayer(pool, player);
      res.json({ ok: true, authenticated: true, ...result });
    } catch (e) {
      console.error('POST /api/sync', e);
      res.status(500).json({ ok: false, error: e.message });
    }
  });

  app.get('/api/me', async (req, res) => {
    try {
      const player = await sessionPlayer(pool, req);
      if (!player) {
        return res.json({ authenticated: false, bobinaConfigured: configured() });
      }

      // Lightweight resolve on every me fetch so DB stays fresh
      let username = player.cached_username;
      let avatar = player.cached_avatar;
      try {
        const mini = await fetchMini(player.bc_id);
        if (mini?.username) {
          username = mini.username;
          avatar = mini.image || avatar;
          if (mini.username !== player.cached_username || mini.image) {
            await pool.query(
              `UPDATE players SET cached_username = $2, cached_avatar = COALESCE($3, cached_avatar), updated_at = NOW()
               WHERE bc_id = $1`,
              [player.bc_id, mini.username, mini.image]
            );
            // Keep scoreboard display in lockstep
            await pool.query(
              `UPDATE bobina_scores SET bobina_username = $2, name = $3, avatar = COALESCE($4, avatar)
               WHERE bc_id = $1`,
              [player.bc_id, mini.username, `@${mini.username}`, mini.image]
            );
          }
        }
      } catch (e) {
        console.warn('mini refresh on /api/me failed', e.message);
      }

      const scoreRow = await pool.query(
        `SELECT COUNT(*)::int AS n, COALESCE(MAX(score),0)::bigint AS best
         FROM bobina_scores WHERE bc_id = $1`,
        [player.bc_id]
      );

      res.json({
        authenticated: true,
        bobinaConfigured: configured(),
        bcId: player.bc_id,
        username,
        avatar,
        xId: player.cached_x_id,
        xUsername: player.cached_x_username,
        highScore: Number(player.high_score) || Number(scoreRow.rows[0].best),
        linkedScores: scoreRow.rows[0].n,
        profileUrl: username ? `${ISSUER}/${username}` : null,
      });
    } catch (e) {
      res.status(500).json({ authenticated: false, error: e.message });
    }
  });
}

async function sessionPlayer(pool, req) {
  const sid = req.cookies?.[SESSION_COOKIE];
  if (!sid) return null;
  const r = await pool.query(
    `SELECT p.*
     FROM sessions s
     JOIN players p ON p.bc_id = s.bc_id
     WHERE s.id = $1 AND s.expires_at > NOW()`,
    [sid]
  );
  return r.rows[0] || null;
}

function missingCredsHtml() {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><title>Bobina login</title>
<style>body{font-family:system-ui,sans-serif;background:#12060c;color:#f5e6ef;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0}
.card{max-width:36rem;padding:2rem;border:1px solid #4a2840;border-radius:16px;background:#1a0a14}
a{color:#ff7ab5}</style></head><body><div class="card">
<h1>Bobina.moe login not configured</h1>
<p>Set <code>BOBINA_CLIENT_ID</code> / <code>BOBINA_CLIENT_SECRET</code> in <code>.env</code>.</p>
<p><a href="/">← Back to the game</a></p>
</div></body></html>`;
}

module.exports = {
  mountBobinaAuth,
  sessionPlayer,
  configured,
  SESSION_COOKIE,
  ISSUER,
  syncPlayer,
  resolvePlayerAccount,
};
