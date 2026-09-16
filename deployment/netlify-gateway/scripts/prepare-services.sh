#!/usr/bin/env bash
# Installs npm deps for every sibling allyabase service that gets bundled
# into the Netlify Function (see ../services.js for the import list).
#
# The gateway's own package.json only lists the wrapper deps (express,
# http-proxy-middleware, serverless-http, jsdom). The sibling services'
# transitive deps (each ../{svc}/src/server/node/package.json — cors,
# fount-js, bdo-js, sessionless-node, stripe, dayjs, ws, etc.) get
# resolved by esbuild at bundle time by walking each imported file's
# own node_modules tree — so each service dir needs a populated
# node_modules before `netlify deploy` runs. This script guarantees
# that on any fresh clone.
#
# Run as netlify.toml's [build] command; also safe to run by hand from
# either the netlify-gateway dir or (via the -C flag) elsewhere.
set -euo pipefail

# Resolve the netlify-gateway dir regardless of where this script is
# invoked from. `realpath` would be cleaner but isn't on macOS by default.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATEWAY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOYMENT_DIR="$(cd "$GATEWAY_DIR/.." && pwd)"

# Keep in sync with the imports at the top of ../services.mjs.
# Currently trimmed to what fits under the 250MB Lambda limit —
# see services.mjs for the reasoning and full un-omitted list.
SERVICES=(
  bdo
  addie
  fount
  eumachia
)

echo "==> Installing sibling service deps for bundling"
echo "    (gateway: $GATEWAY_DIR)"
echo "    (deployment: $DEPLOYMENT_DIR)"

# Netlify's default auto-install step only fires when a package-lock.json
# is present in the site's base dir. This gateway ships without one on
# purpose (the bundle is composed at build time), so install our own deps
# here to guarantee serverless-http / @netlify/blobs / http-proxy-middleware
# are on disk before zisi tries to resolve them.
echo "==> [gateway] npm install"
(cd "$GATEWAY_DIR" && npm install --no-audit --no-fund --loglevel=error --omit=dev)

for svc in "${SERVICES[@]}"; do
  dir="$DEPLOYMENT_DIR/$svc/src/server/node"
  if [ ! -f "$dir/package.json" ]; then
    echo "!! Missing $dir/package.json — expected sibling service checked out here."
    exit 1
  fi
  # --no-audit / --no-fund: don't emit chatter that hides real errors.
  # --omit=dev: sibling services list some huge dev-only tooling
  # (typescript, etc.) as regular deps — leaving devDeps in blows the
  # Lambda 250MB unzipped code limit. Runtime code should be in
  # `dependencies`, so this is defensible; if a service misclassified
  # a runtime dep as dev, add it to that service's `dependencies`
  # upstream rather than dropping this flag.
  echo "==> [$svc] npm install"
  (cd "$dir" && rm -rf node_modules && npm install --no-audit --no-fund --loglevel=error --omit=dev)
done

echo "==> All sibling service deps installed."

# Prune build-time-only packages that some services list as runtime deps.
# These get resolved by zisi's dep-walk and dragged into the bundle even
# though nothing in the actual code path imports them at request time.
# Confirmed by grep across every service's src/server/node/ tree.
#
# Combined savings on current netlify-packaging branches:
#   typescript (39MB in addie) + @types/* + ts-custom-error's
#   codeclimate-reporter binary (13MB in dolores) ~= 60MB
#
# If a real runtime failure ever points at one of these, remove it from
# this list and address the underlying missing dep upstream.
PRUNE_PATTERNS=(
  "typescript"
  "@types"
  "ts-custom-error/codeclimate-reporter"
)
echo "==> Pruning build-time-only packages from sibling node_modules"
pruned=0
for svc in "${SERVICES[@]}"; do
  nm="$DEPLOYMENT_DIR/$svc/src/server/node/node_modules"
  [ -d "$nm" ] || continue
  for pat in "${PRUNE_PATTERNS[@]}"; do
    target="$nm/$pat"
    if [ -e "$target" ]; then
      rm -rf "$target"
      pruned=$((pruned + 1))
    fi
  done
done
echo "    Pruned $pruned path(s)."

# Patch every ecosystem client package (bdo-js, addie-js, fount-js) that
# still `import fetch from 'node-fetch'` — that dependency is undeclared
# in their own package.json, and Node 18+ has a global `fetch` anyway, so
# the import is both unnecessary and unresolvable at runtime. Removing
# the line is safe because the module-level `fetch` binding these files
# create just gets shadowed by the global.
#
# Long-term fix is a PR to each *-js repo; short-term this keeps the
# gateway deployable without waiting on upstream.
echo "==> Patching stray 'node-fetch' imports in ecosystem client packages"
patched=0
for svc in "${SERVICES[@]}"; do
  nm="$DEPLOYMENT_DIR/$svc/src/server/node/node_modules"
  [ -d "$nm" ] || continue
  for client in bdo-js addie-js fount-js; do
    entry="$nm/$client/$(basename "$client" -js).js"
    if [ -f "$entry" ] && grep -q "^import fetch from 'node-fetch';" "$entry"; then
      sed -i.bak "/^import fetch from 'node-fetch';/d" "$entry"
      rm -f "${entry}.bak"
      patched=$((patched + 1))
    fi
  done
done
echo "    Patched $patched file(s)."

# Each service's entry file (${svc}.js) is written as a standalone Node
# server — no `export default app`, and each calls `app.listen(port)`
# itself. But ../services.mjs expects to `import ${svc}App from '.../${svc}.js'`
# and then run `app.listen(port)` in its own startAll() loop.
#
# Two patches to reconcile:
#   1. Append `export default app;` so services.mjs's default import works.
#   2. Comment out the service's own `app.listen(...)` so services.mjs's
#      listen call is the only one — otherwise the second bind throws
#      EADDRINUSE and drops the whole function.
#
# Idempotent: we grep for a sentinel before patching, and skip if it's
# already there.
echo "==> Patching service entry files (export default + strip self-listen)"
patched=0
for svc in "${SERVICES[@]}"; do
  entry="$DEPLOYMENT_DIR/$svc/src/server/node/${svc}.js"
  [ -f "$entry" ] || continue
  if grep -q "^// gateway-patched" "$entry"; then
    continue
  fi
  # Comment out the app.listen line(s) — services.mjs does the listen.
  sed -i.bak "s|^app\.listen(|// gateway-patched: &|" "$entry"
  rm -f "${entry}.bak"
  # Only append the default export if the file doesn't already have one
  # (savage/eumachia were designed as importable modules and already
  # declare it — appending a second one throws "Identifier '.default'
  # has already been declared" at ESM load time).
  if ! grep -q "^export default " "$entry"; then
    cat >> "$entry" <<'PATCH'

// gateway-patched: added by netlify-gateway/scripts/prepare-services.sh
export default app;
PATCH
  fi
  patched=$((patched + 1))
done
echo "    Patched $patched entry file(s)."

# Lambda-specific fixes for dolores. Two independent issues:
#
#   a) canimus.js's `refreshFeeds()` does `fs.mkdirSync('./feeds')` at
#      the CWD, which on Lambda is under a read-only /var/task tree.
#      Redirect to /tmp/feeds (Lambda's only writable dir, per-invocation
#      but persists across warm invocations).
#
#   b) dolores.js kicks off `canimus.refreshFeeds()` at module load
#      without awaiting or attaching a .catch(). Under Node 20+ that
#      unhandled promise rejection is fatal to the process — one flaky
#      network fetch on cold start and the whole Lambda dies. Add a
#      .catch() sink.
#
# Idempotent via sentinel.
DOLORES_CANIMUS="$DEPLOYMENT_DIR/dolores/src/server/node/src/protocols/canimus/canimus.js"
if [ -f "$DOLORES_CANIMUS" ] && ! grep -q "gateway-patched-tmp-feeds" "$DOLORES_CANIMUS"; then
  sed -i.bak "s|'\./feeds'|'/tmp/feeds' /* gateway-patched-tmp-feeds */|g" "$DOLORES_CANIMUS"
  rm -f "${DOLORES_CANIMUS}.bak"
  echo "==> Patched dolores/canimus.js — feeds dir → /tmp/feeds"
fi
# joan/netlify-packaging imports `./src/auth/oauth.js` but that file
# isn't in the branch (appears to be an incomplete commit upstream —
# should be reported to the joan repo). Stub it out with matching named
# exports so the bundle can resolve; the OAuth code paths that call it
# will 500 at request time, but the module load succeeds, which is
# what unblocks the rest of the gateway.
JOAN_OAUTH_DIR="$DEPLOYMENT_DIR/joan/src/server/node/src/auth"
if [ ! -f "$JOAN_OAUTH_DIR/oauth.js" ]; then
  mkdir -p "$JOAN_OAUTH_DIR"
  cat > "$JOAN_OAUTH_DIR/oauth.js" <<'STUB'
// gateway-patched: stub for missing joan/netlify-packaging oauth module.
// Real implementation is missing from the branch; report to joan repo.
const notImplemented = () => {
  throw new Error('OAuth not implemented in this deployment');
};
export const initiateGitHubOAuth = notImplemented;
export const exchangeGitHubCode = notImplemented;
export const getGitHubUser = notImplemented;
STUB
  echo "==> Stubbed joan/src/auth/oauth.js (missing from netlify-packaging)"
fi
if [ ! -f "$JOAN_OAUTH_DIR/otp.js" ]; then
  mkdir -p "$JOAN_OAUTH_DIR"
  cat > "$JOAN_OAUTH_DIR/otp.js" <<'STUB'
// gateway-patched: stub for missing joan/netlify-packaging otp module.
const notImplemented = () => {
  throw new Error('OTP not implemented in this deployment');
};
export const sendOTP = notImplemented;
export const verifyOTP = notImplemented;
STUB
  echo "==> Stubbed joan/src/auth/otp.js (missing from netlify-packaging)"
fi

# addie and bdo on netlify-packaging still ship the filesystem-backed
# client.js (writes to ./data/{svc}/...). Under Lambda every invocation
# gets a fresh /var/task, so `create_user` writes a file the next
# request can't find — surfaces as addie's `getUser` throwing 'not
# found' and returning 404 from /processor/stripe/express even for
# UUIDs the app just got back from create_user.
#
# Sanout, fount, and eumachia already ship a client.netlify-blobs.js
# alongside client.js and a db.js that picks between them via
# PERSISTENCE_BACKEND. Until addie/bdo catch up upstream, overwrite
# their client.js in-place with a blob-backed drop-in (same
# get/set/del surface db.js relies on, per-service store name).
# Original is preserved as client.js.orig so an unpatched checkout
# can still be diff'd.
# @netlify/blobs isn't in addie/bdo's package.json (they don't ship the
# adapter upstream yet), so install it here for the patched client.js
# below to resolve. --no-save keeps the sibling repos clean.
for svc in bdo addie; do
  nm="$DEPLOYMENT_DIR/$svc/src/server/node/node_modules"
  if [ -d "$nm" ] && [ ! -d "$nm/@netlify/blobs" ]; then
    echo "==> [$svc] installing @netlify/blobs for blob-adapter patch"
    (cd "$DEPLOYMENT_DIR/$svc/src/server/node" && npm install --no-save --no-audit --no-fund --loglevel=error @netlify/blobs)
  fi
done

patch_blob_client() {
  local svc="$1"
  local dir="$DEPLOYMENT_DIR/$svc/src/server/node/src/persistence"
  [ -f "$dir/client.js" ] || return 0
  if grep -q "gateway-patched-blob-client" "$dir/client.js" 2>/dev/null; then
    return 0
  fi
  cp "$dir/client.js" "$dir/client.js.orig"
  cat > "$dir/client.js" <<PATCH
// gateway-patched-blob-client: replaces the fs-backed default with a
// @netlify/blobs adapter so state survives across Lambda invocations.
// Original file preserved as client.js.orig.
import { getStore } from '@netlify/blobs';

const storeName = '$svc';

const getBlobStore = () => {
  if (process.env.NETLIFY_BLOBS_CONTEXT) {
    return getStore(storeName);
  }
  const edgeURL = process.env.BLOBS_LOCAL_URL;
  const token = process.env.BLOBS_LOCAL_TOKEN;
  if (!edgeURL || !token) {
    throw new Error(
      'No Netlify Blobs context found and BLOBS_LOCAL_URL/BLOBS_LOCAL_TOKEN are not set.'
    );
  }
  return getStore({ name: storeName, edgeURL, token, siteID: 'local-dev-site' });
};

const set = async (key, value) => {
  await getBlobStore().set(key, value);
  return true;
};

const get = async (key) => {
  return await getBlobStore().get(key);
};

const del = async (key) => {
  await getBlobStore().delete(key);
  return true;
};

const createClient = () => ({ on: () => createClient });
createClient.connect = () => ({ set, get, del });

export { createClient };
PATCH
  echo "==> Patched $svc/src/persistence/client.js — now blob-backed"
}
patch_blob_client bdo
patch_blob_client addie

DOLORES_MAIN="$DEPLOYMENT_DIR/dolores/src/server/node/dolores.js"
if [ -f "$DOLORES_MAIN" ] && ! grep -q "gateway-patched-catch" "$DOLORES_MAIN"; then
  sed -i.bak "s|canimus.refreshFeeds().then(\(.*\))|canimus.refreshFeeds().then(\1).catch(err => console.warn('canimus init failed:', err)) /* gateway-patched-catch */|" "$DOLORES_MAIN"
  rm -f "${DOLORES_MAIN}.bak"
  echo "==> Patched dolores.js — attached .catch() to top-level refreshFeeds()"
fi
