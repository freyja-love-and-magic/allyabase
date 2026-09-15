#!/bin/bash
#
# Container start for one allyabase base.
#
# Which allyabase services run, on which ports, and with what env is decided
# entirely by ../allyabase_setup.sh — this script no longer keeps its own copy
# of that list. It used to hand-write a 150-line ecosystem.config.js with a
# hardcoded block per service, which drifted from the services' actual default
# ports (nginx configs generated from that drift proxied /fount/ to pref's
# port, among others).
#
# What stays here is the part that genuinely belongs to the docker test
# environment and isn't an allyabase service: glyphenge, the path-router
# proxy, and federated wiki.
#
# Usage: ./start-with-ports.sh [PORT_OFFSET]
#
#   PORT_OFFSET shifts every port, so several bases can run side by side:
#   base 1 = 1000, base 2 = 2000, base 3 = 3000.
#
# Env:
#   ALLYABASE_SERVICES=a,b,c   pick services (default: all). Passed straight
#                              through to allyabase_setup.sh, which always
#                              adds bdo/continuebee/fount.
#   ENABLE_PROF=true           legacy shorthand, kept working: adds prof.

set -e

PORT_OFFSET=${1:-0}
APP_DIR=/usr/src/app
SETUP="$APP_DIR/allyabase/deployment/allyabase_setup.sh"

# Not allyabase services — they have no entry in the setup script's manifest
# and are started below rather than through it.
GLYPHENGE_PORT=$((3010 + PORT_OFFSET))
WIKI_PORT=$((3333 + PORT_OFFSET))
PROXY_PORT=$((5124 + (PORT_OFFSET / 100)))

echo "Starting allyabase with port offset: $PORT_OFFSET"
echo

# ── allyabase services ────────────────────────────────────────────────────────

SETUP_ARGS=(--dir="$APP_DIR" --config-only "--port-offset=$PORT_OFFSET")

if [ -n "$ALLYABASE_SERVICES" ]; then
    SETUP_ARGS+=("--services=$ALLYABASE_SERVICES")
elif [ "$ENABLE_PROF" = "true" ]; then
    SETUP_ARGS+=(--all)
else
    # prof has always been opt-in in this environment.
    SETUP_ARGS+=(--all --without=prof)
fi

# --config-only rather than --start-only: the docker-only apps below still have
# to be appended to the process list, so pm2 starts once at the end of this
# script instead of inside the setup script.
"$SETUP" "${SETUP_ARGS[@]}"

# ── docker-only apps ──────────────────────────────────────────────────────────
#
# Spliced into the generated config by replacing its closing bracket. Keeps a
# single pm2 process list rather than a second pm2 invocation.

CONFIG="$APP_DIR/ecosystem.config.js"

python3 - "$CONFIG" "$GLYPHENGE_PORT" "$PROXY_PORT" <<'PY'
import sys
config_path, glyphenge_port, proxy_port = sys.argv[1], sys.argv[2], sys.argv[3]
with open(config_path) as f:
    config = f.read()

extra = """    {
      name: 'glyphenge',
      script: '/usr/src/app/the-advancement/glyphenge/server.js',
      env: {
        LOCALHOST: 'true',
        PORT: '%s'
      }
    },
    {
      name: 'proxy',
      script: '/usr/src/app/allyabase/deployment/docker/proxy-server.js',
      env: {
        LOCALHOST: 'true',
        PROXY_PORT: '%s'
      }
    },
""" % (glyphenge_port, proxy_port)

# The generated file ends with "  ]\n}\n"; insert before that bracket.
marker = "  ]\n}"
assert marker in config, "unexpected ecosystem.config.js shape — did allyabase_setup.sh change?"
config = config.replace(marker, extra + marker)

with open(config_path, "w") as f:
    f.write(config)
print("  glyphenge      :%s" % glyphenge_port)
print("  proxy          :%s" % proxy_port)
PY

echo "  wiki           :$WIKI_PORT"
echo

# ── federated wiki ────────────────────────────────────────────────────────────
#
# Deliberately NOT under pm2: wiki-plugin-allyabase calls "pm2 stop all" on
# startup to reset services, which would kill the wiki hosting it.

echo "Starting federated wiki on port $WIKI_PORT with sessionless security and allyabase proxy..."
wiki --security wiki-security-sessionless --plugin wiki-plugin-allyabase --plugin wiki-plugin-home --port "$WIKI_PORT" > /var/log/wiki.log 2>&1 &

cd "$APP_DIR"
pm2-runtime start ecosystem.config.js
