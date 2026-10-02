#!/bin/bash
#
# Container entrypoint (the Dockerfile's CMD) for a single-base allyabase.
#
# This used to inline its own ecosystem.config.js — a third hardcoded copy of
# the service list alongside the Dockerfile's clone list and
# start-with-ports.sh's config. It listed 11 services with no PORT set at all
# (relying on each service's built-in default), and adding a service meant
# editing all three places. savage and eumachia were never added here, so a
# plain `docker run` started neither.
#
# Now the manifest in allyabase_setup.sh is the only place any of that lives.
#
# Env:
#   ALLYABASE_SERVICES=a,b,c   pick services (default: all). bdo, continuebee,
#                              and fount always come along.
#   ENABLE_PROF=true           legacy shorthand, kept working: adds prof.
#
# For the multi-base test environment — which also needs glyphenge, the proxy,
# and federated wiki — use start-with-ports.sh instead.

set -e

SETUP=/usr/src/app/allyabase/deployment/allyabase_setup.sh

SETUP_ARGS=(--dir=/usr/src/app --start-only)

if [ -n "$ALLYABASE_SERVICES" ]; then
    SETUP_ARGS+=("--services=$ALLYABASE_SERVICES")
elif [ "$ENABLE_PROF" = "true" ]; then
    SETUP_ARGS+=(--all)
else
    # prof has always been opt-in in this environment.
    SETUP_ARGS+=(--all --without=prof)
fi

exec "$SETUP" "${SETUP_ARGS[@]}"
