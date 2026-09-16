# Integrating with Allyabase — A Howto for Claude

This is a practical guide for building a **new application that talks to allyabase**, written for Claude to reference when doing integration work. It's distinct from `CLAUDE.md` (allyabase's own internal architecture) and `AGENT.md`/`PN-AGENT.md` (general ecosystem conventions) — this one is about consuming allyabase from the outside, the way `homeventory` or `4es-dot-world/consulting-dot-4es-world` do.

Everything here is drawn from real integration and deployment work, including bugs actually hit and fixed along the way — not just how the docs say it should work.

## Core Concept: Sessionless Identity

Allyabase has no passwords, no emails, no sessions. Every user — including your app itself, when it acts as a client — is a secp256k1 keypair. Auth is: sign a message with your private key, the server verifies the signature against your public key.

```js
import sessionless from 'sessionless-node';

let keys = null;
await sessionless.generateKeys(
  (k) => { keys = k; },       // saveKeys — persist this however you like
  () => keys                   // getKeys — return whatever you persisted
);

const timestamp = Date.now().toString();
const message = timestamp + keys.pubKey;
const signature = await sessionless.sign(message);
```

`saveKeys`/`getKeys` are callbacks *you* provide — sessionless doesn't know or care where the keypair lives. This is the single most important integration seam: get it right and everything downstream works; get it wrong (e.g. don't actually persist it) and your app silently re-registers as a brand-new identity every time it restarts.

## The Client Library Pattern

Each service has a matching client library (`bdo-js`, `addie-js`, `fount-js`, `sanora-js`, ...). They all follow the same shape:

```js
import bdo from 'bdo-js';

bdo.baseURL = 'https://dev.bdo.allyabase.com/'; // or wherever your instance lives

// First time: registers a new identity with this service
const uuid = await bdo.createUser(hash, initialData, saveKeys, getKeys);

// Later: read/write using that identity
await bdo.updateBDO(uuid, hash, newData, isPublic);
const result = await bdo.getBDO(uuid, hash);
```

`createUser` internally calls your `getKeys()` first — if it returns an existing keypair, the library reuses that identity instead of registering a new one. This is why `saveKeys`/`getKeys` being *correctly wired to real persistence* matters so much: it's the difference between "one stable identity forever" and "a new orphaned identity on every cold start."

## Local Dev vs Production: the `LOCALHOST` Convention

Every service in this ecosystem follows the same pattern for pointing at its dependencies:

```js
const SUBDOMAIN = process.env.SUBDOMAIN || 'dev';
bdo.baseURL = process.env.LOCALHOST
  ? 'http://localhost:3003/'
  : `https://${SUBDOMAIN}.bdo.allyabase.com/`;
```

Set `LOCALHOST=true` when running against a local/dev stack (docker-compose, or services running directly on your machine), and it resolves to loopback ports instead of the hosted subdomains. Match this convention in your own app rather than inventing a new one — it composes cleanly with everything else in the ecosystem, including the bundled-serverless deployment pattern described below.

## Service Directory

| Service | Client lib | Default port | Purpose |
|---|---|---|---|
| bdo | `bdo-js` | 3003 | "Big Dumb Object" storage — generic key/value blobs |
| sanora | `sanora-js` | 7243 | Products, marketplace, order handling |
| addie | `addie-js` | 3005 | Payments (Stripe), user registration |
| fount | `fount-js` | 3006 | Nineum/MAGIC economy, spellbook resolution |
| pref | — | 3002 | User preferences |
| joan | — | 3004 | Credential/account recovery |
| continuebee | — | 2999 | State/hash verification |
| aretha | — | 7277 | Limited-run products, ticketing |
| julia | — | 3000 | P2P messaging, key coordination |
| dolores | — | 3007 | Social feeds, media, video |
| minnie | — | 2525 | Transactional email (proxies Resend) |
| prof | — | 3008 | Profile management (binary image storage — different persistence shape than the rest, see below) |

## Writing Resilient Integration Code

These are lessons from real bugs, not theoretical concerns.

**Don't let a registration/bootstrap call crash your whole process.** A bare `await someService.createUser(...)` at module top level means an unreachable dependency doesn't just fail that call — an unhandled rejection can kill the entire Node process. Wrap it in retry-with-backoff instead:

```js
const repeat = (fn) => setTimeout(fn, 2000);

const bootstrap = async () => {
  try {
    const uuid = await fount.createUser(saveKeys, getKeys);
    // ...
  } catch (err) {
    console.warn('bootstrap failed, retrying:', err.message);
    repeat(bootstrap);
  }
};
bootstrap(); // not awaited — let it retry in the background
```

**Don't trust in-memory state to survive between requests.** If your app might ever run somewhere stateless (a serverless function, a container that recycles) — and you should assume it might, even if it doesn't today — any handler that mutates a cached list (emails, tickets, whatever) needs to reload from the real source of truth first:

```js
app.post('/api/submit-email', async (req, res) => {
  // reload before mutating — don't trust a cache that might have reset
  await loadEmailsFromBDO();
  emailsData.emails.push({ email, submittedAt: Date.now() });
  await syncEmailsToBDO();
  // ...
});
```

**Add a cooldown for calls to a service you know might be down**, rather than eating a full connection timeout on every single request:

```js
const RETRY_INTERVAL_MS = 60 * 60 * 1000;
let cooldownUntil = null;

const isInCooldown = () => cooldownUntil !== null && Date.now() < cooldownUntil;
const recordFailure = () => { cooldownUntil = Date.now() + RETRY_INTERVAL_MS; };
const recordSuccess = () => { cooldownUntil = null; };
```

**Watch for `throw` where `null` was meant.** At least one service's `getUserByPublicKey`-style lookup throws `Error('not found')` instead of returning `null` — which is correct when you're fetching a *known* ID (a real 404), but wrong when you're checking "does this brand-new pubKey already exist" as a precondition to registration, since the throw unwinds past the code that would've created the new user. If a registration flow mysteriously always 404s for new identities, this is the first thing to check.

## Persisting Your App's Own Identity

Your `saveKeys`/`getKeys` implementation needs real, durable storage. Three options, in order of how much infrastructure they require:

1. **Local file** (fine for a long-running server, e.g. a droplet — **not** for a Netlify Function, see below):
   ```js
   const saveKeys = (k) => fs.writeFileSync(KEYS_FILE, JSON.stringify(k));
   const getKeys = () => fs.existsSync(KEYS_FILE) ? JSON.parse(fs.readFileSync(KEYS_FILE)) : null;
   ```
   This is exactly what eumachia's `identity.js` did at first, and it broke outright once bundled into `netlify-gateway`: `fs.mkdirSync('./data', ...)` throws `ENOENT` on Netlify's read-only filesystem, so identity bootstrap never completed. Ported to the same Blobs-backed `client.js`/`client.netlify-blobs.js` pair every other service in this repo uses (see `eumachia/src/server/node/src/persistence/`) — pick that pattern from the start if there's any chance your service ends up bundled serverless.
2. **A hosted KV store** (required for serverless — see below) — Netlify Blobs, Upstash Redis, etc.
3. **Your own database**, if your app already has one.

Whichever you pick, the contract is the same: `saveKeys(keys)` persists, `getKeys()` retrieves. Nothing else in the integration needs to know or care which one you chose.

## Deploying Your Integration

### Traditional (long-running process)

Just works. Run your app as a normal Node process, point it at allyabase's hosted subdomains (or `LOCALHOST=true` for local dev), done.

### Serverless (Netlify Functions)

This works, but not out of the box — Netlify's `esbuild`-based function bundler has several real incompatibilities with how these services are normally written. All of the following were hit and fixed while getting allyabase's own services running as Netlify Functions (see `deployment/netlify-gateway/` for a full working example bundling 11 services into one function):

- **No top-level `await`.** Netlify's default bundler targets CommonJS output, which doesn't support top-level `await` at all — even Node's own native support for it doesn't help, since this is a *bundler* limitation, not a runtime one. Any `const client = await createClient()...` at module scope needs to become a lazily-resolved promise instead:
  ```js
  let clientPromise = null;
  const getClient = () => {
    if (!clientPromise) clientPromise = createClient().then(c => c.connect());
    return clientPromise;
  };
  // call sites: (await getClient()).get(key) instead of client.get(key)
  ```
- **`import.meta.url` is `undefined` under that same bundling**, not just empty — `fileURLToPath(import.meta.url)` throws. If you use the common `const __filename = fileURLToPath(import.meta.url)` idiom, guard it:
  ```js
  let __dirname;
  try { __dirname = path.dirname(fileURLToPath(import.meta.url)); }
  catch { __dirname = process.cwd(); } // degrades gracefully instead of crashing
  ```
  This also means your own `if (import.meta.url === \`file://${process.argv[1]}\`) { app.listen(...) }` direct-run guards are *safe* in this environment — the comparison just always evaluates false, which is exactly what you want (never bind a port inside a Function).
- **Read-only filesystem** — only `/tmp` is writable. Any code that does `fs.mkdirSync`/`fs.writeFileSync` against a relative path (local caching, etc.) will throw `EROFS`. Wrap it or skip it in that environment.
- **Heavy transitive dependencies can break bundling in surprising ways.** `jsdom` (pulled in by anything doing server-side HTML sanitization) loads a worker script from disk at runtime rather than via a traceable import — esbuild can't bundle it. Mark it external instead (`external_node_modules = ["jsdom"]` in `netlify.toml`), and if you hit `require() of ES Module` errors afterward, pin to an older jsdom version rather than latest — recent versions pulled in an ESM-only sub-dependency that can't be `require()`'d from a CJS bundle.
- **Netlify Blobs has eventually-consistent reads by default** (up to ~60s drift) unless you're using strongly-consistent API access explicitly. A write immediately followed by a read from a different invocation may not see it yet — this is expected, not a bug, and matters most for identity registration flows that write-then-immediately-read. Concretely: BDO's emojicode assignment writes correctly on every call (a real, unique code comes back in the response every time), but a separate `GET /pubkey/:pubKey/emojicode` right after can 404 for up to a minute before it becomes visible. **Don't reach for `getStore(name, { consistency: 'strong' })` as the fix** — under this Lambda-compatibility setup (`connectLambda(event)` populating context from the incoming event), strong consistency reads fail outright with `BlobsConsistencyError: ...environment has not been configured with a 'uncachedEdgeURL' property`. Getting real strong consistency would need explicit `siteID`/`token` "API access" configuration instead of the auto-populated Lambda context — a bigger change than a one-line option flip, and out of scope until it's actually needed.
- **Bundling multiple services into one Function fixes cross-service bootstrap reliability**, if you're deploying allyabase's own services (not just consuming them). Every service already has the `LOCALHOST` convention wired into its inter-service calls — if you bind every service to its real port *within the same process* and set `LOCALHOST=true`, those calls resolve to an already-warm loopback peer instead of a possibly-cold separate Function. See `deployment/netlify-gateway/services.js` for the working pattern.
- **`sessionless-node` keeps exactly one shared, mutable identity slot per process** (a module-level `let getKeysFromDisk`, set by whichever `generateKeys(saveKeys, getKeys)`/`bdo-js`/`addie-js` `createUser` call ran most recently — some client libraries even do a blunter `sessionless.getKeys = getKeys` property overwrite). That's invisible when every service runs in its own process, but bundling 13+ independently-identitied services into **one** Function via esbuild dedupes them onto the **same** `sessionless-node` module instance — so any two services that both call `sessionless.sign()`/`getBDO()`/etc. across an `await` boundary are racing for the same global, and whichever bootstrapped (or retried) most recently silently wins for everyone else. This bit eumachia hard: `/pay/:uuid/status` kept failing with sessionless's own `"no default secure storage"` error, not because eumachia's identity wasn't set up, but because some other bundled service's bootstrap retry loop kept re-stomping the shared slot in between. The fix isn't architectural — it's to have every call site that ends up inside `sessionless.sign()` reclaim its own identity immediately beforehand, synchronously, with no `await` in between: `sessionless.getKeys = myOwnGetKeys;` right before the call (see `eumachia/src/payments/payments.js`'s `identity.claimIdentity()` calls for the working pattern). Do this in any new bundled service that calls `sessionless`/`bdo-js`/`addie-js` more than once per request lifecycle.

### Adding a lightweight service to the bundle

Not everything you add to a bundled deployment needs to be a full allyabase service with its own identity and persistence — sometimes it's just a small transform or pass-through in front of an existing one. `savage` (its own repo now, previously `deployment/savage/`) is a working example: `GET /savage/user/:uuid/bdo` forwards straight through to BDO's own `GET /user/:uuid/bdo` (whatever query string it's given — auth is BDO's problem, not savage's), and wraps an `svg` property from the response in a minimal HTML page with the SVG set as `og:image`/`twitter:image`, for shareable rich link previews.

Having no persistence layer sidesteps most of the gotchas above, but wiring it into the bundle surfaced a different, narrower set of problems worth knowing about if you add something similar:

- **The internal proxy hop hides the real request from your service.** `gateway.js` uses `http-proxy-middleware` with `changeOrigin: true` to forward `/savage/*` to savage's own loopback port — which rewrites the `Host` header to the internal target (`127.0.0.1:3009`) before savage ever sees it. If your service needs to build an absolute URL back to itself, naively using `req.protocol`/`req.get('host')` produces an internal, externally-unreachable address. Fix: add `xfwd: true` to the proxy config (adds `x-forwarded-host`/`x-forwarded-proto`/`x-forwarded-for`) and read those instead, falling back to the direct values for standalone (non-bundled) deployments:
  ```js
  const host = req.get('x-forwarded-host') || req.get('host');
  const proto = req.get('x-forwarded-proto') || req.protocol;
  ```
- **`pathRewrite` strips your mount prefix, and there's no standard header for it.** Once `xfwd` recovers the host, the path is still wrong — `pathRewrite: { '^/savage': '' }` means your service only ever sees `/user/:uuid/bdo`, with no way to know it's externally reachable at `/savage/user/:uuid/bdo`. `X-Forwarded-Prefix` isn't part of `xfwd`, so set one yourself in the proxy config:
  ```js
  // http-proxy-middleware v2.x: onProxyReq is a top-level option. v3 moves
  // this under `on: { proxyReq }` instead - check your installed version.
  createProxyMiddleware({
    target: `http://127.0.0.1:${port}`,
    onProxyReq: (proxyReq) => proxyReq.setHeader('x-forwarded-prefix', `/${name}`),
    // ...
  })
  ```
- **Don't try to set that prefix via an env var from `services.js` instead — it silently won't work, and not because of a typo.** Every `import` statement in a module is fully resolved and evaluated *before* any plain statement in that same module runs, regardless of the order they're written in — so `import savageApp from '../savage/...'` (and therefore all of savage.js's own top-level code) executes before a `process.env.SAVAGE_MOUNT_PATH = '/savage'` line in the same file ever runs, no matter which line comes first textually. The header-based approach above sidesteps this, since it's set per-request rather than at module load.
- **Forwarded headers accumulate across hops rather than getting overwritten.** Deployed on Netlify, a request to `/savage/*` passes through two proxy layers — Netlify's own edge (which already sets `x-forwarded-proto`), then the gateway's internal hop to savage (`xfwd: true` sets it again) — and per standard proxy header semantics, each hop *appends* rather than replaces, so the header can arrive as `"https,https"`. This only showed up once actually deployed, not in local testing (where there's only one hop). Always take the first value:
  ```js
  const firstForwarded = (value) => value ? value.split(',')[0].trim() : null;
  ```
- **Reusing a heavy, already-configured dependency from a different service works — as long as you let its declared version range resolve, not latest.** Savage needed to sanitize untrusted SVG content before serving it back as live, browser-rendered markup — the same problem `bdo`'s `teleportation-js` dependency already solved with `removeJavaScript` (strips `<script>` tags, `on*` event handlers, `javascript:`/`data:` URLs, CSS `expression()` injections; not exported from `teleportation-js`'s main entry — import it directly from `teleportation-js/src/node-remove-javascript.js`). Installing `teleportation-js` fresh in savage's own `node_modules` pulled in `jsdom@26.1.0` — the exact version already known to bundle cleanly — because `teleportation-js` itself declares `"jsdom": "^26.1.0"`; letting that resolve naturally (instead of `npm install jsdom` directly, which grabs latest) avoided reintroducing the ESM-only sub-dependency problem described above. The gateway's existing `external_node_modules = ["jsdom"]` in `netlify.toml` covered this automatically too, since external-module marking matches by package name, not by which service's `node_modules` it resolves from.

## Testing Your Integration

Use Sharon (`planet-nine/sharon`) — it's the ecosystem's test harness. The fast, useful one for verifying a deployment is up:

```bash
cd planet-nine/sharon
ALLYABASE_BASE_URL=https://your-deployment.example.com node verify-environment.js
```

It hits every service's base URL and treats a 404 as healthy (an Express service 404ing on its bare root means it's alive and routing correctly — that's the expected response, not a failure). Note it can't distinguish "service genuinely deployed and 404ing correctly" from "nothing is even mounted at this path" — both look identical from the outside, so a clean pass doesn't guarantee every service you *think* is deployed actually is.

Deeper per-service `magic-spells.js` test suites also exist in `sharon/tests/*/magic-spells.js`, but their base URLs are currently hardcoded (either `127.0.0.1` ports or `*.allyabase.com` subdomain patterns) rather than reading `ALLYABASE_BASE_URL` — they'd need editing before they'd run against a differently-hosted deployment.

## Reference Implementation

`homeventory/website.js` (in `planet-nine/third-party/homeventory`) is a working, minimal example of a client app integrating with BDO: registering an identity, persisting keys, and syncing data — including the Netlify-specific fixes described above already applied. It's a good starting point to copy from.

savage's `src/server/node/savage.js` (extracted to its own repo; was `deployment/savage/`) is a different kind of reference: a persistence-free service bundled *alongside* allyabase's own services rather than a client consuming them from outside — good starting point for "small transform in front of an existing service" rather than "full client with its own identity." Its `scripts/smoke-test.mjs` and `scripts/test-sanitize.mjs` are also worth a look as examples of testing a bundled service end-to-end, including an adversarial test (a malicious SVG payload) that proves sanitization actually works rather than just asserting a 200 status.

## Known Issues Worth Knowing About

As of this writing, a few real bugs exist in the ecosystem that aren't yet fixed everywhere (some are fixed on local `netlify-packaging` branches but not merged):

- **addie's `getUserByPublicKey`** throws instead of returning `null` on a fresh pubKey, which can block first-time registration through addie depending on which code path you hit.
- **fount's `SERVICE_URLS` map** had continuebee pointing at the wrong port (3002 instead of 2999) — fixed on the `netlify-packaging` branch, may not be merged yet.
- **julia's `db.js`** calls `client.sendCommand(...)`, a method neither the filesystem nor Blobs persistence client implements — this code path will throw if exercised.
- **sanora's `generic-menu-stripe.js`** reads the wrong template file (`generic-address-stripe.html` instead of `generic-menu-stripe.html`) — looks like a copy-paste artifact.
- **BDO's own bootstrap call to fount** (`bdo.js`'s `bootstrap()` → `fount.createUser(db.saveKeys, db.getKeys)`) has been observed, intermittently, getting rejected by fount's timestamp-validation middleware with `{error: 'no time like the present'}`, which then loops forever via BDO's own `repeat(bootstrap)` retry every 2s. **Not currently reproducible** — a direct test against fount's `/user/create` with a fresh timestamp succeeds cleanly, and a fresh redeploy showed no recurrence over several minutes of testing. Best working theory (unconfirmed): a Netlify Blobs eventual-consistency gap in BDO's own `db.saveKeys` → `db.getKeys` immediate write-then-read inside that same bootstrap call. Low impact even if it recurs — it's BDO's background self-registration with fount, not something that blocks BDO from serving real requests, and it already self-heals via retry. Worth real investigation if it starts affecting anything user-facing.

None of these block basic integration, but worth knowing if something in one of these specific areas misbehaves.
