# Allyabase - Planet Nine Ecosystem

## Overview

Allyabase is the foundational ecosystem for Planet Nine, providing a complete microservices architecture with federated wiki integration, sessionless authentication, and MAGIC protocol support.

**Location**: `/allyabase/`

## How the apps and services fit together (September 2026)

What building the HomeFront apps against allyabase actually taught us, as of
September 2026. The rest of this file describes the services and the test
environment; this section is about the seams between them, which is where all
the time went.

The apps: **BizBuz** (business cards), **LinkityLink** (link-in-bio),
**getpayed** (invoices, formerly Gelder), **idothis** (local services
directory). All four are Tauri 2 + vanilla JS, iOS-first, and all four are
thin clients over these services with no server of their own.

### 1. Identity: one keypair per thing, not per user

Every app keeps a per-install sessionless keypair in its own app data
directory (`sessionless_key.json`). On top of that:

- **One keypair per published record.** BDO's public slot is keyed by pubKey,
  so a single identity means a single slot: the second card an app published
  would overwrite the first. BizBuz and LinkityLink mint a keypair per card,
  getpayed one per invoice.
- **One app-embedded keypair for a shared list.** idothis's directory and
  requests inbox are single BDO records written by a private key hardcoded in
  `lib.rs`, because BDO has no multi-writer list primitive. Anyone with the
  source has write access. It is called out in the code as an MVP limitation,
  not an oversight.
- **A profile's uuid is its owner's pubKey** in prof, which is what makes
  ownership checkable without a user registry.

**`sessionless-node` is a module-level singleton.** `sessionless.getKeys` is
global state, so anything juggling two identities in one process must
re-point it immediately before each `sign()`. Signing with the wrong key
looks exactly like an auth bug on the server, and cost hours in eumachia. The
Rust `sessionless` crate is instance-based and has no such trap.

`sign()` takes a message. `sessionless.sign(privateKey, uuid, timestamp)`
appears in older docs and is not a real signature — it was still in prof's
README a week ago.

### 2. A uuid belongs to the base that minted it

BDO, addie and prof all mint their own server-side uuids, unrelated to the
signing pubKey. A uuid minted on one base does not resolve on another, and
**the failure is usually silent**: BDO answers `{"bdo": null}`, which parses
as an empty record with no error.

idothis lost both of its shared features this way. Its directory and requests
uuids had been minted on a retired Netlify gateway, so joining appeared to
work and nobody was ever discoverable. Nothing logged anything.

So: every app namespaces cached uuids by environment — `bdoUuidByEnv` keyed
by hostname with dots swapped for dashes (`prod-8as-world`), `GATEWAY_ENV`,
`base.json` written once. Moving a base means re-minting anything hardcoded
and pasting the new uuids in, and a functional round trip afterwards is the
only proof that worked.

### 3. Public or private: BDO or prof, and prof can never back discovery

This is the most important thing learned wiring idothis to prof.

| | BDO | prof |
|---|---|---|
| Who can read | anyone with the pre-signed URL; in the shared-record pattern, every install | only the key that wrote it |
| At rest | plaintext | AES-256-GCM, key in the service's environment |
| Purpose | things meant to be shared | the user's own PII |

prof has **no route that hands one person's profile to another**. `GET
/profiles` returns uuids only, requires a tag, and pages. So a feature where
users browse each other — idothis's swipe stack, any directory — cannot be
backed by prof, however much the data looks like profiles. That data has to
live in BDO (public, by design) and the app has to be honest in its privacy
manifest about publishing it.

What prof is for is the user's own copy: idothis's opt-in profile backup
(September 2026) is the first consumer. See `idothis/CLAUDE.md` → "Profile
backup (prof)" for the mapping and its limits.

prof also **exits 1 on startup without `PROF_ENCRYPTION_KEY`**, and
`docker/spin-up-bases.sh` refuses `--enable-prof` without one, rather than
starting a service that would take PII it cannot store safely. Losing that
key loses every profile under it.

### 4. savage serves what BDO holds, and strips behaviour out of it

savage renders a published record's `svg` field as a webpage at a permanent
pre-signed URL. It holds no keys: the query string *is* the credential, so the
app computes the share URL locally the instant it publishes.

Because the SVG is untrusted, `sanitizeSvg` removes scripts, `javascript:`
URLs and `on*` attributes. Two consequences that bit:

- BizBuz's referral card cannot auto-redirect to the App Store. It is a plain
  `<a href>` button.
- The sanitizer also stripped `data:` URIs, which silently deleted the
  **photo** out of every published card. The fix (September 2026) stashes a
  base64 raster data URI behind a placeholder, runs the JavaScript strip, then
  restores it onto `<image>` elements only — png/jpeg/gif/webp, never
  `svg+xml`. If a published card renders without its photo, look there first.

Anything interactive needs **eumachia**, which authors its own markup and
escapes every interpolated invoice field. The security posture is inverted
between the two services, and each one's defence is load-bearing in its own
direction.

### 5. The Canonical Profile is four copies of one struct

A single shared record in the iOS App Group **`group.club.home.front`**, under
the key `canonical.profile`, read and written through
`tauri-plugin-app-group` (UserDefaults-backed). It carries the photo, up to 20
free-form `{slug, name, value}` fields, a postal address, and each app's own
fields.

**Every app overwrites the whole record on save.** So every app must carry
forward the fields it does not own, or saving in one app erases what another
wrote. The fields and their owners today:

| Field | Owned by | Everyone else |
|---|---|---|
| `photo`, `fields` | all four (each has an editor) | — |
| `address` | Gettit | carry forward |
| `idothisCategories`, `serviceZip`, `idothisRateCents` | idothis | carry forward |
| `stripeConnected`, `payout` | getpayed | carry forward |

Adding a field means adding it to four Rust structs, or the next app to save
deletes it. The struct is deliberately copy-pasted rather than shared as a
crate; the contract is pinned by a round-trip test in each app
(`canonical_profile_round_trips_payout_key`), which asserts an unknown future
field survives a parse-and-save.

Two narrower app-to-app handoffs use the same plugin with their own keys:
`linkitylink.card` (LinkityLink → BizBuz) and `bizbuz.profile` (BizBuz →
LinkityLink, idothis).

**Documentation drift worth knowing about**: BizBuz's, getpayed's and
idothis's CLAUDE.md all said the group was `group.freyja.idothis`. It is not,
and never was in code — the entitlements, the Swift plugin's
`UserDefaults(suiteName:)` and all four build scripts use
`group.club.home.front`. That name survives only in the app-group plugin's
autogenerated permission blurbs.

### 6. A payout destination is a pair, never a key

```
payout: { pubKey: "02…", addieURL: "https://prod.8as.world/addie/" }
```

Addie is distributed, so a pubkey alone is ambiguous — it only means anything
resolved against the addie instance holding that account. The pair travels as
one struct for that reason, and matches addie's own payee shape (`pubKey` +
`addieURL`, see `buildPayeeMetadata` and `/verify-payee`), so it can be
lifted straight into a payout request.

**Still outstanding**: getpayed's invoices carry `creator_addie_pub_key` with
no `addieURL` alongside it. Same gap, not yet fixed.

### 7. The money path, and the five bugs stacked in it

Getting one real payment from a card to a creator's balance took five fixes,
each of which was only findable by running a real payment in Stripe test
mode:

1. The platform profile was incomplete (fixed in the Stripe dashboard).
2. Connected accounts were created with `transfers` only. Stripe requires
   **`card_payments` alongside `transfers`** for transfers to work without
   special approval; both account-creation paths now request both.
3. `addie-js` 0.0.7's `getPaymentIntent` took five parameters and silently
   dropped the `merchant` argument eumachia passes as its sixth. No
   `merchant_pubkey` on the intent, so the payout step found nobody to pay,
   and the charge succeeded while the money stayed on the platform account.
   **0.0.8 is the floor. Don't relax the pin.**
4. The merchant was never in the recipients list, so nothing was transferred
   even once it was known.
5. Transfers drew on the platform's available balance, which is empty in test
   mode. They now pass **`source_transaction`** (the charge's
   `latest_charge`), funding the transfer from the charge itself.
   `pm_card_bypassPending` is the test card that settles straight to
   available balance if you need the other behaviour.

`eumachia/src/server/node/test/README.md` is the manual-testing guide: 31
cases naming the exact Stripe test card or token that triggers each failure,
including the ones where the payer is charged and the creator is paid nothing.

Stripe Connect onboarding moved from a hosted browser page to the **Stripe
iOS SDK** (`tauri-plugin-stripe-connect`). The SDK links into the app target
rather than the plugin, because Tauri's static-library plugins drop SwiftPM
resource bundles; see `getpayed/CLAUDE.md` for the bridge contract.

### 8. MAGIC through fount is not an authorization boundary

This repo's CLAUDE.md describes MAGIC as "centralized Fount authentication",
and that is true about *casting*: fount checks the caster signature on the
envelope. It says nothing about what the casting may touch.

prof's spells took `spell.components.uuid` at face value and checked nothing,
so `profUserProfileDelete` deleted whichever profile you named — straight
around the ownership its REST routes enforce. They now require the profile
owner's signature (`timestamp + uuid`) in the components, checked against the
`ownerPubKey` on the record, with the signed timestamp checked for freshness
in its own right.

**Any service holding per-user data has to check ownership itself.** Fount's
signature answers a different question.

### 9. `GET /services` is not a reliable inventory

savage was live on prod, routed in nginx and serving, while absent from the
services listing. A missing entry means nothing; probe the service. (Learned
the hard way after telling the user savage wasn't deployed.)

### 10. Build and release facts that apply to all four apps

- **`FORCE_COLOR` breaks iOS builds.** `xcodegen` resolves `${FORCE_COLOR}`
  in `project.yml`'s Run Script phase eagerly, from the generating shell, so
  a bare value lands in the arch list and tauri fails with "`3` isn't a known
  arch" — a misleading error that looks like a toolchain problem. All four
  `scripts/build-ios.cjs` now `delete process.env.FORCE_COLOR` themselves.
- **`tauri ios init` wipes `gen/apple/` every build**, so each script reapplies
  the same set of patches afterwards: `ios-native/` source path (carrying
  `PrivacyInfo.xcprivacy`), iPhone-only `TARGETED_DEVICE_FAMILY`,
  `ITSAppUsesNonExemptEncryption: false`, the real icon with alpha flattened
  on every size, and the App Group entitlement.
- **Version trains close.** Once a build is submitted under a version, App
  Store Connect answers further uploads with `Validation failed (409) Invalid
  Pre-Release Train`. Every submission round needs a new version in three
  files (`tauri.conf.json`, `package.json`, `Cargo.toml`) plus `.build-number`
  reset to 0. **Store version strings and repo versions do not correspond**
  and are not worth reconciling.
- **Screenshots**: each app has `app-store-screenshots/README.md` and a
  `make-screenshots.sh` producing 6.9″ (1320×2868) and 6.5″ (1284×2778).
  `SKIP_TF_MASK=1` skips the TestFlight banner mask, which otherwise blacks
  out the status bar clock.
- **BizBuz always points at prod**, never dev. Per-state bases
  (`<state>.8as.world`) are pinned per install on the first card.
- **No em dashes in user-facing copy** — app UI and the website both. House
  style.

### 11. Privacy manifests follow the data, not the intent

Apple's test for "collect" is transmission plus retention, not whether we read
it. Encrypted and private still counts: idothis's opt-in prof backup is
declared, because it is transmitted and kept. A profile with free-form fields
predictably carries an email address or a phone number even though the app
never asks for either by name, so both are declared once those fields can
leave the device.

Also: `NSPrivacyAccessedAPICategoryUserDefaults` needs reason `1C8F.1` (App
Group access) or the upload fails with ITMS-91053, and an empty reasons array
is what triggers it.

### Where the details live

These are sibling checkouts at `~/Work`, not paths inside this repo.

- Service docs: `prof/CLAUDE.md`, `savage/CLAUDE.md`, `eumachia/CLAUDE.md`,
  `addie/CLAUDE.md`, `bdo/CLAUDE.md`
- App docs: `bizbuz/CLAUDE.md`, `linkitylink/CLAUDE.md`, `getpayed/CLAUDE.md`,
  `idothis/CLAUDE.md`
- prof's own contract and encryption scheme: `prof/README.md`,
  `prof/MAGIC-ROUTES.md`

## Core Architecture

### 🌐 **Federated Wiki Proxy Routing (November 2025)**

Allyabase now supports routing all service traffic through Federated Wiki as a single entry point, matching production architecture.

#### Wiki Plugin: wiki-plugin-allyabase
**Location**: `/src/wiki/wiki-plugin-allyabase/`

The wiki plugin provides:
- **Service Proxy Routes**: All microservices accessible via `/plugin/allyabase/{service}/*`
- **Feed Management**: Dolores feed subscriptions
- **Inventory System**: BDO-based inventory management
- **Deployment Tools**: Service deployment and configuration

#### Proxy Route Mapping

All Planet Nine services are accessible through the wiki proxy:

```
/plugin/allyabase/julia/*        → julia:3000
/plugin/allyabase/continuebee/*  → continuebee:2999
/plugin/allyabase/pref/*         → pref:3002
/plugin/allyabase/bdo/*          → bdo:3003
/plugin/allyabase/joan/*         → joan:3004
/plugin/allyabase/addie/*        → addie:3005
/plugin/allyabase/fount/*        → fount:3006
/plugin/allyabase/dolores/*      → dolores:3007
/plugin/allyabase/minnie/*       → minnie:2525
/plugin/allyabase/aretha/*       → aretha:7277
/plugin/allyabase/sanora/*       → sanora:7243
/plugin/allyabase/glyphenge/*    → glyphenge:3010
/plugin/allyabase/linkitylink/*  → glyphenge:3010 (alias)
```

#### Implementation Details

**Server-side Plugin Entry**: `/src/wiki/wiki-plugin-allyabase/index.js`
```javascript
module.exports = {
  server: require('./server/server.js')
};
```

**Proxy Route Handler**: `/src/wiki/wiki-plugin-allyabase/server/proxy.js`
- Handles all `/plugin/allyabase/{service}/*` routes
- Proxies HTTP requests to backend services
- Preserves method (GET, POST, PUT, DELETE)
- Forwards headers and body
- Returns responses transparently

### 🐳 **Docker Test Environment**

**Location**: `/deployment/docker/`

#### Flexible Multi-Base Architecture

The Docker setup supports running multiple isolated allyabase instances simultaneously:

**Scripts**:
- `spin-up-bases.sh` - Start 1-3 test bases with configurable options
- `Dockerfile-flexible` - Multi-service container image
- `start-with-ports.sh` - Service startup with dynamic port mapping

**Port Mapping** (Test Environment):
- Base 1: Host ports 5111-5125 → Docker internal ports
- Base 2: Host ports 5211-5225 → Docker internal ports
- Base 3: Host ports 5311-5325 → Docker internal ports

Each base includes:
- All 14 microservices
- Federated Wiki on port 3333 (mapped to 5x24)
- Glyphenge on port 3010 (mapped to 5x25)
- Wiki plugin with proxy routes enabled

#### Usage Examples

```bash
# Start 3 bases with clean rebuild
./spin-up-bases.sh --clean --build

# Start with seeding on Base 1
./spin-up-bases.sh --seed --seed-base=1

# Start with prof service enabled. Needs an encryption key: prof exits
# rather than store PII it cannot encrypt, and this script refuses the flag
# without one. See docker/.env.example.
PROF_ENCRYPTION_KEY=$(openssl rand -hex 32) ./spin-up-bases.sh --enable-prof

# Test wiki proxy on Base 1
curl http://localhost:5124/plugin/allyabase/fount/health
```

### 📦 **Microservices**

**Location**: `/deployment/{service}/`

#### Core Services
1. **Fount** (3006) - Authentication and experience/nineum management
2. **BDO** (3003) - Big Dumb Object storage
3. **Joan** (3004) - Identity management
4. **Julia** (3000) - Messaging and coordination
5. **Pref** (3002) - User preferences
6. **Continuebee** (2999) - Session continuity

#### Application Services
7. **Addie** (3005) - AI assistant and payment processing
8. **Sanora** (7243) - E-commerce and product management
9. **Dolores** (3007) - Content discovery and feeds
10. **Aretha** (7277) - Ticket and access management
11. **Minnie** (2525) - Email service

#### Platform Services
13. **Glyphenge** (3010) - Server-side SVG rendering and link tapestries
14. **Prof** (3008) - Profile management. Holds PII: encrypted at rest and
    owner-only, and it exits on startup without `PROF_ENCRYPTION_KEY`. Not in
    a default base; enable it deliberately.

### 🔐 **Sessionless Authentication**

All services use cryptographic signature-based authentication:
- No passwords or sessions
- secp256k1 keypairs
- Message signing with timestamps
- Per-service authentication middleware

### ⚡ **MAGIC Protocol**

Cross-service operations coordinated through MAGIC spells:
- Centralized Fount authentication — of the **caster**, not of what the
  casting may touch. A service holding per-user data must check ownership
  itself; see "MAGIC through fount is not an authorization boundary" above,
  and `prof/MAGIC-ROUTES.md` for what that looks like in practice.
- Multi-service workflows
- Experience granting
- Gateway rewards

See individual service CLAUDE.md files for available spells.

## Test Environment Configuration

### SDK Configuration

Client SDKs support test-wiki mode for wiki proxy routing:

**BDO SDK** (`bdo-js`):
```javascript
bdo.configure({
  env: 'test-wiki',
  base: 1  // Uses Base 1 wiki proxy (port 5124)
});
```

**Fount SDK** (`fount-js`):
```javascript
fount.configure({
  env: 'test-wiki',
  base: 2  // Uses Base 2 wiki proxy (port 5224)
});
```

**Addie SDK** (`addie-js`):
```javascript
addie.configure({
  env: 'test-wiki',
  base: 3  // Uses Base 3 wiki proxy (port 5324)
});
```

### iOS App Configuration

**Location**: `/the-advancement/src/The Advancement/Shared (App)/Configuration.swift`

Test-wiki environment available:
```swift
case testWiki
// Routes all service traffic through wiki proxy at localhost:5124
```

### Seeding Test Data

**Script**: `/deployment/docker/seed-ecosystem.js`

Supports multiple environments:
- `local` - Direct service access on localhost
- `test` - Docker container ports (51xx, 52xx, 53xx)
- `test-wiki` - Via wiki proxy routes

```bash
# Seed via wiki proxy
node seed-ecosystem.js test-wiki 1
```

## Local Development

### Sanora Store Testing

**Location**: `/sharon/tests/sanora/`

Tools for testing Sanora feed generation and serving:

**make-store.js**:
- Scans folder for artifacts (books, music, posts)
- Generates federated feeds (Libris, Canimus, Scribus)
- Starts HTTP server on port 8080
- Beautiful landing page with feed links

**serve-store.js**:
- Serves existing .store directory
- Fast restart without regenerating feeds
- Static file serving for artifacts

```bash
# Create and serve store
cd /path/to/artifacts
node /path/to/sharon/tests/sanora/make-store.js "My Store"

# Access at http://localhost:8080
# Feeds at http://localhost:8080/feeds/
```

**Note**: Store server (port 8080) is independent of wiki proxy (port 5124). Both can run simultaneously.

## Wiki Proxy Testing

### Manual Testing

```bash
# Start bases
cd /allyabase/deployment/docker
./spin-up-bases.sh --clean --build

# Test proxy routes (Base 1 on port 5124)
curl http://localhost:5124/plugin/allyabase/bdo/health
curl http://localhost:5124/plugin/allyabase/fount/resolve
curl -X POST http://localhost:5124/plugin/allyabase/julia/magic/spell/spellTest

# Test Base 2 (port 5224) and Base 3 (port 5324) similarly
```

### Sharon Integration Tests

**Location**: `/sharon/tests/`

Wiki proxy tests available in service-specific test suites. Configure test environment to use wiki proxy URLs.

## Production vs Test Architecture

### Production
- Single wiki instance serves all traffic
- Services on private network
- Wiki on public domain
- All access via `/plugin/allyabase/{service}/*`

### Test (Docker)
- 3 independent bases for parallel testing
- Each base has own wiki on 5x24
- Each base has complete service set
- Simulates production routing

### Local Development
- Services run directly on localhost
- Wiki optional
- Direct service access for debugging
- Store server for feed testing (port 8080)

## File Structure

```
allyabase/
├── src/
│   └── wiki/
│       └── wiki-plugin-allyabase/
│           ├── index.js              # Plugin entry point
│           ├── package.json
│           ├── client/               # Client-side MAGIC spells
│           └── server/
│               ├── server.js         # Server initialization
│               ├── proxy.js          # Service proxy routes
│               ├── feeds.js          # Dolores integration
│               ├── inventory.js      # BDO inventory system
│               └── deployment.js     # Deployment tools
├── deployment/
│   ├── docker/
│   │   ├── Dockerfile-flexible       # Multi-service container
│   │   ├── spin-up-bases.sh          # Multi-base orchestration
│   │   ├── start-with-ports.sh       # Service startup script
│   │   ├── seed-ecosystem.js         # Test data seeding
│   │   └── test-bases-config.json    # Port mappings
│   ├── addie/                        # Service deployment files
│   ├── aretha/
│   ├── bdo/
│   ├── continuebee/
│   ├── dolores/
│   ├── fount/
│   ├── joan/
│   ├── julia/
│   ├── minnie/
│   ├── pref/
│   ├── prof/
│   └── sanora/
└── CLAUDE.md                         # This file
```

## Recent Updates

### November 2025 - Wiki Proxy Routing
- ✅ Implemented complete wiki proxy routing infrastructure
- ✅ Created wiki-plugin-allyabase with service proxy support
- ✅ Updated Docker setup to install plugin from GitHub
- ✅ Added test-wiki environment to all SDK configurations
- ✅ Updated iOS Configuration.swift with test-wiki mode
- ✅ Verified proxy routes working in test environment

### Key Implementation Details
- Wiki plugin requires `index.js` entry point exporting server module
- Plugin installed via `cp -r` from GitHub clone into wiki's node_modules
- Proxy routes use http module for request forwarding
- All HTTP methods (GET, POST, PUT, DELETE) supported
- Headers and request bodies forwarded transparently

## Related Documentation

- Wiki Plugin: `/src/wiki/wiki-plugin-allyabase/README.md`
- Docker Setup: `/deployment/docker/README.md`
- Service Docs: `/deployment/{service}/CLAUDE.md`
- Sharon Tests: `/sharon/CLAUDE.md`
- Test Environment: `/deployment/docker/README-SEEDING.md`

## Last Updated
September 24, 2026 - Added "How the apps and services fit together": the
integration seams the HomeFront apps actually run on, written up after wiring
idothis to prof and getting a real Stripe payment through addie and eumachia.
Nothing below that section was re-verified in this pass; the wiki-proxy and
docker material still dates from November 2025, and savage and eumachia have
since been extracted into their own repos at `~/Work`.

November 30, 2025 - Added comprehensive wiki proxy routing documentation and test environment configuration details.
