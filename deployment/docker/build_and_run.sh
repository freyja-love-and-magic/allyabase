#!/bin/bash
#
# Build the single-base image and run it in the foreground.
#
# Usage:
#   ./build_and_run.sh
#   PROF_ENCRYPTION_KEY=$(openssl rand -hex 32) ./build_and_run.sh --enable-prof
#
# prof is opt-in, same as everywhere else in this deployment: it holds PII,
# encrypts it at rest, and EXITS ON STARTUP without a key rather than accept
# profiles it cannot store. Passing --enable-prof without a key is refused
# here, so the container doesn't restart a dying prof forever.

set -e

ENABLE_PROF=false
for arg in "$@"; do
    case "$arg" in
        --enable-prof) ENABLE_PROF=true ;;
        -h|--help)
            echo "Usage: $0 [--enable-prof]"
            echo ""
            echo "Env:"
            echo "  PROF_ENCRYPTION_KEY      64 hex chars, required with --enable-prof"
            echo "  PROF_ENCRYPTION_KEY_ID   label stamped into each blob (default k1)"
            echo "  PROF_DECRYPTION_KEYS     \"kA:<hex>,kB:<hex>\", superseded keys kept readable"
            exit 0 ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--enable-prof]" >&2
            exit 1 ;;
    esac
done

PROF_ARGS=()
if [ "$ENABLE_PROF" = true ]; then
    if [ -z "$PROF_ENCRYPTION_KEY" ]; then
        echo "❌ --enable-prof needs PROF_ENCRYPTION_KEY, which prof uses to encrypt profiles at rest."
        echo "   Generate one:"
        echo ""
        echo "     PROF_ENCRYPTION_KEY=\$(openssl rand -hex 32) $0 --enable-prof"
        echo ""
        echo "   Keep a copy somewhere durable. Losing it loses every stored profile."
        exit 1
    fi

    # The generated pm2 config reads these from the container's environment at
    # start time, so they have to be passed in here rather than baked into the
    # image — an encryption key does not belong in an image layer.
    PROF_ARGS=(
        -e ENABLE_PROF=true
        -e PROF_ENCRYPTION_KEY="$PROF_ENCRYPTION_KEY"
        -e PROF_ENCRYPTION_KEY_ID="${PROF_ENCRYPTION_KEY_ID:-k1}"
        -p 3008:3008
    )
    if [ -n "$PROF_DECRYPTION_KEYS" ]; then
        PROF_ARGS+=(-e PROF_DECRYPTION_KEYS="$PROF_DECRYPTION_KEYS")
    fi
    echo "🔐 prof enabled on 3008, encrypting at rest under key id ${PROF_ENCRYPTION_KEY_ID:-k1}"
elif [ -n "$PROF_ENCRYPTION_KEY" ]; then
    echo "ℹ️  PROF_ENCRYPTION_KEY is set but prof is off. Add --enable-prof to start it."
fi

docker build -t allyabase .

docker run \
  -p 2525:2525 \
  -p 2999:2999 \
  -p 3000:3000 \
  -p 3002:3002 \
  -p 3003:3003 \
  -p 3004:3004 \
  -p 3005:3005 \
  -p 3006:3006 \
  -p 3007:3007 \
  -p 3012:3012 \
  -p 3013:3013 \
  -p 7243:7243 \
  -p 7277:7277 \
  "${PROF_ARGS[@]}" \
  allyabase
