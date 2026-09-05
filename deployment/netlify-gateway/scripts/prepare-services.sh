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

# Keep in sync with the imports at the top of ../services.js.
SERVICES=(
  bdo
  sanora
  addie
  fount
  pref
  joan
  continuebee
  aretha
  julia
  dolores
  savage
  eumachia
)
# minnie deliberately omitted — SMTP daemon, doesn't fit a Lambda.

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
  # --loglevel=error: same reason.
  # --omit=dev is deliberately NOT set — some services list runtime deps
  # in devDependencies (safer to install everything for the bundle).
  echo "==> [$svc] npm install"
  (cd "$dir" && npm install --no-audit --no-fund --loglevel=error)
done

echo "==> All sibling service deps installed."

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
DOLORES_MAIN="$DEPLOYMENT_DIR/dolores/src/server/node/dolores.js"
if [ -f "$DOLORES_MAIN" ] && ! grep -q "gateway-patched-catch" "$DOLORES_MAIN"; then
  sed -i.bak "s|canimus.refreshFeeds().then(\(.*\))|canimus.refreshFeeds().then(\1).catch(err => console.warn('canimus init failed:', err)) /* gateway-patched-catch */|" "$DOLORES_MAIN"
  rm -f "${DOLORES_MAIN}.bak"
  echo "==> Patched dolores.js — attached .catch() to top-level refreshFeeds()"
fi
