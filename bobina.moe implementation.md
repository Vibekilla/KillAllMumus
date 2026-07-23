# Kill All Mumus — Bobina.moe Account Linkage & Leaderboard Guide

How **killallmumus.com** integrates with the Bobina identity system so that:

- Bobina accounts are the **canonical identity** for a player (their `bc_id`).
- All game data (scores, stats, leaderboard entries) is **tied to `bc_id`**, so it survives username/handle changes and is portable across devices.
- Anyone can **play anonymously**, but a signed-in Bobina player's data is **always saved** server-side.
- A leaderboard row on killallmumus.com can **resolve back** to that player's Bobina profile (`https://bobina.moe/<username>`) or their linked **X** account.

> Issuer: `https://bobina.moe`
> Discovery: `https://bobina.moe/.well-known/openid-configuration`
> This guide builds on the base [Login with Bobina.moe integration guide](./oauth-integration.md). Read that first — it covers PKCE, the token exchange, and ID-token verification in full. This doc only adds the game-specific pieces.

> **Credentials are issued by the Bobina Council at their sole discretion.** Register `killallmumus.com` as an OAuth client via a Council admin (**System → OAuth Apps**) and request only the scopes below.

---

## 1. The identity model

| Concept | What it is | Where it comes from |
|---------|-----------|---------------------|
| **`bc_id`** | The Bobina Council ID (`bc_...`). The **primary key** for a player. Never changes. | `sub` claim from the ID token / UserInfo |
| **username** | The player's current bobina.moe handle. Used for the profile deep-link. May change. | `username` claim (`profile` scope) |
| **X ID** | The stable numeric X (Twitter) user ID. Rename-proof; use for crediting. | `x_id` claim (`social` scope) |
| **X username** | The player's current `@handle` on X. May change. | `x_username` claim (`social` scope) |

**Rule:** store game data keyed by **`bc_id`**. Treat `username` and `x_username` as **display/deep-link hints** that can go stale — re-resolve them (Section 5), never use them as a primary key.

---

## 2. Scopes to request

Request the minimum needed for account linkage and leaderboard attribution:

\`\`\`
openid profile social
\`\`\`

| Scope | Why the game needs it |
|-------|----------------------|
| `openid` | Always required. Returns `sub` = `bc_id`, the key you store game data under. |
| `profile` | `username` (for the `bobina.moe/<username>` deep-link), `name`, and `picture` (leaderboard avatar/display name). |
| `social` | `x_id` + `x_username` to credit/deep-link the player's X account, plus any other socials they've chosen to show. |

Ask the Council admin to allow-list `openid`, `profile`, and `social` for the killallmumus.com client.

> **`social` is privacy-gated.** You only receive socials the user has toggled **visible** in **Profile → Social links** on bobina.moe. Any social claim (including `x_id`/`x_username`) may be **absent** — always treat them as optional and fall back to the bobina.moe profile link.

---

## 3. Account gating with anonymous play

Design the game so identity is **optional but sticky**:

1. **Anonymous by default.** A new player gets a local, client-side session (e.g. a random `guest_id` in `localStorage`). They can play immediately; scores are provisional and local.
2. **"Sign in with Bobina"** runs the standard Authorization Code + PKCE flow (see base guide). On success you receive `bc_id` (`sub`).
3. **On first sign-in, claim the guest data.** Migrate the anonymous session's stats to the `bc_id` record (Section 4), then discard the `guest_id`. From then on, that player's data lives under `bc_id` and is saved server-side on every run.
4. **Gate only what you must.** Leave general play open to guests; require a linked Bobina account only for ranked leaderboard placement, rewards, or cross-device sync — your choice.

\`\`\`ts
// Pseudocode for resolving the current player's storage key.
function playerKey(session): string {
  return session.bcId            // signed-in Bobina player (canonical)
    ?? `guest:${session.guestId}` // anonymous, local-only
}
\`\`\`

> Because a signed-in player's data is always keyed by `bc_id` server-side, it is never lost when they switch devices or change their bobina.moe username or X handle.

---

## 4. Storing game data (keyed by `bc_id`)

Persist scores/stats under `bc_id`. Keep a small, cached copy of display fields for fast leaderboard rendering, but re-resolve them periodically (Section 5).

\`\`\`ts
// Example row in the game's own database
interface PlayerRecord {
  bcId: string           // PRIMARY KEY — from `sub`. Never changes.
  highScore: number
  kills: number
  gamesPlayed: number
  // cached display hints (safe to be stale; re-resolve from bobina.moe)
  cachedUsername?: string   // from `username`
  cachedAvatar?: string     // from `picture`
  cachedXId?: string        // from `x_id` (stable, rename-proof)
  cachedXUsername?: string  // from `x_username`
  updatedAt: string
}

// On sign-in: upsert by bcId and refresh cached hints from this turn's claims.
async function onBobinaLogin(claims) {
  await db.players.upsert({
    where: { bcId: claims.sub },
    create: { bcId: claims.sub, highScore: 0, kills: 0, gamesPlayed: 0 },
    update: {}, // don't clobber stats
  })
  await db.players.update({
    where: { bcId: claims.sub },
    data: {
      cachedUsername: claims.username ?? null,
      cachedAvatar: claims.picture ?? null,
      cachedXId: claims.x_id ?? null,          // may be undefined if X hidden/unlinked
      cachedXUsername: claims.x_username ?? null,
      updatedAt: new Date().toISOString(),
    },
  })
  // Migrate any anonymous guest progress into this bcId, then drop the guest id.
  await migrateGuestData(currentGuestId, claims.sub)
}
\`\`\`

---

## 5. Resolving a leaderboard row back to a profile

Each leaderboard entry stores a `bc_id`. To render a clickable row that links back to bobina.moe (or X), resolve the `bc_id` to fresh display data.

### 5a. Deep-link targets

| Click target | URL | Requires |
|--------------|-----|----------|
| Bobina profile | `https://bobina.moe/<username>` | `username` (re-resolved, see below) |
| X profile (by handle) | `https://x.com/<x_username>` | `x_username` from `social` scope |
| X profile (by ID, rename-proof) | `https://x.com/i/user/<x_id>` | `x_id` from `social` scope |

**Priority:** prefer the bobina.moe profile link (canonical). Offer the X link as a secondary "credit" link when `x_id`/`x_username` is present.

### 5b. Re-resolving the current username (public, no token)

Usernames change; don't trust the value you cached at sign-in for the deep-link. Bobina exposes a **public, unauthenticated** mini-profile endpoint that accepts a `bc_id` (or username):

\`\`\`
GET https://bobina.moe/api/user/<bc_id>/mini
->  { "id": "bc_...", "username": "vibekilla", "displayName": "Vibe", "image": "https://..." }
\`\`\`

\`\`\`ts
// Build a leaderboard row's profile link from a stored bc_id.
async function resolveProfileLink(bcId: string): Promise<string | null> {
  const res = await fetch(`https://bobina.moe/api/user/${bcId}/mini`)
  if (!res.ok) return null
  const p = await res.json()
  return p.username ? `https://bobina.moe/${p.username}` : null
}
\`\`\`

- Cache responses briefly (the endpoint is CDN-cached ~2 min). For a full leaderboard page, resolve in a batch and cache client-side.
- If the endpoint 404s (account deleted/deactivated), render the row as an anonymized past player and drop the deep-link.
- `x_id` is **only** available via the `social` scope at sign-in — it is **not** returned by the public `/mini` endpoint. Store it at sign-in (Section 4) if you want the X deep-link.

### 5c. Rendering a row

\`\`\`tsx
// Prefer bobina.moe; fall back to X credit if the player showed it.
const bobinaUrl = row.cachedUsername ? `https://bobina.moe/${row.cachedUsername}` : null
const xUrl = row.cachedXUsername
  ? `https://x.com/${row.cachedXUsername}`
  : row.cachedXId
    ? `https://x.com/i/user/${row.cachedXId}`
    : null

<LeaderboardRow
  href={bobinaUrl ?? xUrl ?? undefined}   // undefined => non-clickable (guest/deleted)
  name={row.cachedUsername ?? "Anonymous Mumu Slayer"}
  avatar={row.cachedAvatar}
  score={row.highScore}
  xCredit={xUrl}
/>
\`\`\`

---

## 6. Data lifecycle & compliance

- **Key everything by `bc_id`.** It is the only stable identifier. `username` and `x_username` change; `bc_id` and `x_id` do not.
- **Request only `openid profile social`.** Do not request `wallet`, `holdings`, or `email` unless a Council admin approves a specific need.
- **Honor visibility.** Never display or store a social account that wasn't returned under the `social` scope — absence means the user chose to hide it. Do not attempt to infer hidden socials from other sources.
- **Respect deletion.** If `/api/user/<bc_id>/mini` starts returning 404, treat the Bobina account as gone: stop deep-linking to it and anonymize the leaderboard row. Provide a way to delete the player's game data on request.
- **Keep secrets server-side.** `client_secret`, `code_verifier`, and all tokens stay on killallmumus.com's backend — never in the browser or game client.
- **Verify ID tokens** (issuer `https://bobina.moe`, audience = your `client_id`, `exp`, and `nonce`) before trusting `sub`. See the base guide, Section 5.

---

## 7. End-to-end summary

1. Guest plays anonymously (local `guest_id`).
2. Guest clicks **Sign in with Bobina** → PKCE Authorization Code flow → you get `bc_id` (`sub`), `username`, `picture`, and (if shown) `x_id` / `x_username`.
3. Upsert a `PlayerRecord` keyed by `bc_id`; migrate guest progress into it.
4. All future scores/stats save server-side under `bc_id` — never lost.
5. Leaderboard stores `bc_id` per entry; rows resolve to `https://bobina.moe/<username>` (via `/api/user/<bc_id>/mini`) or to X via `x_id`/`x_username`.
