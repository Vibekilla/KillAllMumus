#!/usr/bin/env node
/**
 * Seed / relink itsvibekilla → bc_9dmh2n7h8z3f and sync display via mini helper.
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { createPool, migrate, claimScoresForPlayer } = require('../lib/db');
const { fetchMini, bustCache } = require('../lib/bobina-profile');

const BC_ID = process.env.LINK_BC_ID || 'bc_9dmh2n7h8z3f';
const HANDLES = ['itsvibekilla'];

async function main() {
  const pool = createPool();
  await migrate(pool);
  bustCache(BC_ID);
  const mini = await fetchMini(BC_ID);
  console.log('mini', mini);
  const username = mini?.username || 'itsvibekilla';
  const avatar = mini?.image || null;

  await pool.query(
    `INSERT INTO players (bc_id, cached_username, cached_avatar, high_score, kills, games_played, updated_at)
     VALUES ($1, $2, $3, 0, 0, 0, NOW())
     ON CONFLICT (bc_id) DO UPDATE SET
       cached_username = EXCLUDED.cached_username,
       cached_avatar = COALESCE(EXCLUDED.cached_avatar, players.cached_avatar),
       updated_at = NOW()`,
    [BC_ID, username, avatar]
  );

  const result = await claimScoresForPlayer(pool, {
    bcId: BC_ID,
    bobinaUsername: username,
    avatar,
    xId: null,
    xUsername: 'itsvibekilla',
    claimHandle: 'itsvibekilla',
  });

  // Explicit link for handle variants
  await pool.query(
    `UPDATE bobina_scores SET
       bc_id = $1,
       bobina_username = $2,
       name = $3,
       avatar = COALESCE($4, avatar)
     WHERE bc_id IS NULL
       AND LOWER(REGEXP_REPLACE(COALESCE(handle,''), '^@+', '')) = ANY($5::text[])`,
    [BC_ID, username, `@${username}`, avatar, HANDLES]
  );

  // Final collapse + display refresh
  await claimScoresForPlayer(pool, {
    bcId: BC_ID,
    bobinaUsername: username,
    avatar,
    xUsername: 'itsvibekilla',
    claimHandle: 'itsvibekilla',
  });

  const rows = await pool.query(
    `SELECT id, name, handle, score, bc_id, bobina_username FROM bobina_scores
     WHERE bc_id = $1 OR LOWER(handle) = 'itsvibekilla' ORDER BY score DESC`,
    [BC_ID]
  );
  console.log('linked rows', rows.rows);
  console.log('claim result', result);
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
