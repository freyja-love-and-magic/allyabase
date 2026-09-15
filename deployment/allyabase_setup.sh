#!/bin/bash
#
# allyabase-setup — clone, install, and run an allyabase, with only the
# services you actually want.
#
# bdo, continuebee, and fount are always installed: every other service
# authenticates through fount, verifies state through continuebee, and stores
# objects in bdo. Everything else is opt-in.
#
# This script is meant to be the single entry point for every deployment
# flavour — droplet/pm2, DigitalOcean provisioning (see
# digitalocean/03-install-services.sh, which already calls it), and the docker
# multi-base test environment (via --port-offset). If you find yourself
# hand-writing an ecosystem.config.js somewhere else, that's a bug in this
# script, not a reason to fork it.
#
# Usage:
#   allyabase-setup [PARENT_DIR] [options]
#
# A positional PARENT_DIR gets '/allyabase' appended (so `allyabase-setup
# /var/lib` installs into /var/lib/allyabase). Use --dir=PATH to name the
# install directory exactly, with nothing appended — which is what you want
# any time the path already ends in 'allyabase', or when something else owns
# that name in the same tree (the docker image keeps the allyabase repo at
# /usr/src/app/allyabase and installs services beside it in /usr/src/app).
#
#   --all                 install every service (default)
#   --minimal             install only bdo, continuebee, fount
#   --services=a,b,c      install exactly these (plus the required three)
#   --with=a,b            add to the default set
#   --without=a,b         remove from the default set
#   --dir=PATH            install here exactly; don't append '/allyabase'
#   --port-offset=N       add N to every port (multi-base; docker uses this)
#   --org=NAME            default GitHub org to clone from
#   --install-only        clone and npm install, then stop (docker build step)
#   --start-only          write ecosystem.config.js and start (docker run step)
#   --config-only         write ecosystem.config.js and stop, without starting
#                         pm2 — for callers that need to add their own apps to
#                         the process list first (docker/start-with-ports.sh)
#   --list                print the service manifest and exit
#   --nginx               print nginx location blocks for the selection, exit
#   --dry-run             print what would happen, change nothing
#   -h, --help            this message
#
# ALLYABASE_SERVICES=a,b,c in the environment does the same as --services.

set -euo pipefail

# ── Service manifest ──────────────────────────────────────────────────────────
#
# name|default_port|github_org|required|needs
#
# Ports are each service's OWN default, taken from its server source — not a
# number invented here. If you change one, change it in the service too, or
# the service will listen somewhere other than where nginx proxies it.
#
# `needs` lists service-level dependencies BEYOND the required three (which
# everything implicitly needs). Selecting a service pulls its needs in
# automatically.
#
# Every service currently lives under freyja-love-and-magic. The org is still
# a per-service column rather than one constant because it has diverged before
# (savage and eumachia were extracted into a different org than the rest for a
# while) and a single service moving shouldn't require restructuring this.
# --org=NAME overrides the whole column at once.
SERVICE_MANIFEST=(
    "bdo|3003|freyja-love-and-magic|required|"
    "continuebee|2999|freyja-love-and-magic|required|"
    "fount|3006|freyja-love-and-magic|required|"
    "addie|3005|freyja-love-and-magic|optional|"
    "aretha|7277|freyja-love-and-magic|optional|"
    "dolores|3007|freyja-love-and-magic|optional|"
    "eumachia|3013|freyja-love-and-magic|optional|addie"
    "joan|3004|freyja-love-and-magic|optional|"
    "julia|3000|freyja-love-and-magic|optional|"
    "minnie|2525|freyja-love-and-magic|optional|"
    "pref|3002|freyja-love-and-magic|optional|"
    "prof|3008|freyja-love-and-magic|optional|"
    "sanora|7243|freyja-love-and-magic|optional|"
    "savage|3012|freyja-love-and-magic|optional|"
)

# ── Manifest accessors ────────────────────────────────────────────────────────

manifest_field() { # $1 = service, $2 = field index (1-5)
    local row
    for row in "${SERVICE_MANIFEST[@]}"; do
        if [[ "${row%%|*}" == "$1" ]]; then
            printf '%s' "$(printf '%s' "$row" | cut -d'|' -f"$2")"
            return 0
        fi
    done
    return 1
}

service_port()     { manifest_field "$1" 2; }
service_org()      { manifest_field "$1" 3; }
service_required() { [[ "$(manifest_field "$1" 4)" == 'required' ]]; }
service_needs()    { manifest_field "$1" 5; }

all_services()      { local r; for r in "${SERVICE_MANIFEST[@]}"; do printf '%s\n' "${r%%|*}"; done; }
required_services() { local s; while read -r s; do service_required "$s" && printf '%s\n' "$s"; done < <(all_services); }
service_exists()    { manifest_field "$1" 1 >/dev/null 2>&1; }

# ── Options ───────────────────────────────────────────────────────────────────

defaultDir="/var/lib"
buildDir=""
explicit_dir=""
selection_mode='all'
requested=""
with_extra=""
without_extra=""
port_offset=0
default_org=""
dry_run=false
# 'both' does the lot (the plain droplet case). Docker splits it: the image
# build clones and installs (ports aren't known yet), the container start
# writes ecosystem.config.js with that base's --port-offset and launches pm2.
phase='both'

usage() { sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)           selection_mode='all' ;;
        --minimal)       selection_mode='minimal' ;;
        --services=*)    selection_mode='explicit'; requested="${1#*=}" ;;
        --with=*)        with_extra="${with_extra},${1#*=}" ;;
        --without=*)     without_extra="${without_extra},${1#*=}" ;;
        --dir=*)         explicit_dir="${1#*=}" ;;
        --port-offset=*) port_offset="${1#*=}" ;;
        --org=*)         default_org="${1#*=}" ;;
        --install-only)  phase='install' ;;
        --start-only)    phase='start' ;;
        --config-only)   phase='config' ;;
        --list)          selection_mode='list' ;;
        --nginx)         selection_mode="${selection_mode}"; PRINT_NGINX=true ;;
        --dry-run)       dry_run=true ;;
        -h|--help)       usage; exit 0 ;;
        -*)              echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)               buildDir="$1" ;;
    esac
    shift
done

PRINT_NGINX="${PRINT_NGINX:-false}"

# ALLYABASE_SERVICES is the env-var equivalent of --services, for callers that
# find it easier to export a variable than build an argument list (docker).
if [[ -z "$requested" && -n "${ALLYABASE_SERVICES:-}" ]]; then
    selection_mode='explicit'
    requested="$ALLYABASE_SERVICES"
fi

if [[ "$selection_mode" == 'list' ]]; then
    printf '%-14s %-7s %-22s %-9s %s\n' SERVICE PORT ORG REQUIRED NEEDS
    for row in "${SERVICE_MANIFEST[@]}"; do
        IFS='|' read -r n p o r d <<< "$row"
        printf '%-14s %-7s %-22s %-9s %s\n' "$n" "$p" "$o" "$r" "${d:--}"
    done
    exit 0
fi

if [[ -n "$explicit_dir" ]]; then
    buildDir="$explicit_dir"
    [[ $buildDir != /* ]] && buildDir="${PWD%/}/${buildDir#./}"
else
    buildDir="${buildDir:-$defaultDir}"
    [[ $buildDir != /* ]] && buildDir="${PWD%/}/$buildDir"
    buildDir="${buildDir#./}/allyabase"
fi
ecosystem_config="$buildDir/ecosystem.config.js"

# ── Resolve the selection ─────────────────────────────────────────────────────

# The trailing newline matters: `read` returns non-zero at EOF even when it
# successfully read data, so a final line without one is assigned but never
# processed by `while read`. With `printf '%s'` this silently dropped the last
# service in every list — `--services=savage,eumachia` installed savage only.
csv_to_lines() { printf '%s\n' "$1" | tr ',' '\n' | sed '/^$/d' | tr -d ' '; }

# `mapfile`/`readarray` would be the obvious tool here, but macOS still ships
# bash 3.2 (the last GPLv2 release) where neither exists — and this script has
# to be runnable on a developer's Mac, not just an Ubuntu droplet. This reads
# stdin into the array named by $1 using bash 3.2-compatible eval.
read_into() {
    local __array_name="$1" __line
    eval "$__array_name=()"
    while IFS= read -r __line; do
        [[ -n "$__line" ]] && eval "$__array_name+=(\"\$__line\")"
    done
}

resolve_selection() {
    local selected=()
    local s

    case "$selection_mode" in
        minimal)  read_into selected < <(required_services) ;;
        all)      read_into selected < <(all_services) ;;
        explicit)
            read_into selected < <(required_services)
            while read -r s; do
                service_exists "$s" || { echo "Unknown service: '$s' (try --list)" >&2; exit 2; }
                selected+=("$s")
            done < <(csv_to_lines "$requested")
            ;;
    esac

    while read -r s; do
        service_exists "$s" || { echo "Unknown service: '$s' (try --list)" >&2; exit 2; }
        selected+=("$s")
    done < <(csv_to_lines "$with_extra")

    # --without can't remove a required service: nothing else would work, and
    # silently honouring it would produce a base that fails at runtime rather
    # than here, where the mistake is still obvious.
    while read -r s; do
        if service_required "$s"; then
            echo "Refusing --without=$s: bdo, continuebee, and fount are required by every other service." >&2
            exit 2
        fi
        local kept=() k
        for k in "${selected[@]}"; do [[ "$k" != "$s" ]] && kept+=("$k"); done
        selected=("${kept[@]}")
    done < <(csv_to_lines "$without_extra")

    # Pull in dependencies. One pass is enough: `needs` only ever names
    # services that have no optional needs of their own. If that stops being
    # true, this has to loop to a fixed point.
    #
    # A dependency is NOT allowed to quietly reinstate something --without
    # excluded. `--all --without=addie` still selects eumachia, which needs
    # addie — resolving that by silently keeping addie would mean the flag the
    # user typed had no effect and nothing said so. Fail with the pair named
    # instead, so the fix (exclude both, or neither) is obvious.
    local with_deps=("${selected[@]}") dep excluded
    for s in "${selected[@]}"; do
        for dep in $(csv_to_lines "$(service_needs "$s")"); do
            for excluded in $(csv_to_lines "$without_extra"); do
                if [[ "$dep" == "$excluded" ]]; then
                    echo "Can't exclude '$dep': '$s' needs it." >&2
                    echo "Either drop --without=$dep, or exclude '$s' too (--without=$dep,$s)." >&2
                    exit 2
                fi
            done
            with_deps+=("$dep")
        done
    done

    printf '%s\n' "${with_deps[@]}" | sort -u
}

# Captured via $(...) rather than read from <(...): process substitution runs
# resolve_selection in a subshell whose `exit 2` on a bad selection only kills
# the subshell. The parent then carried on with an empty SELECTED and died on
# `set -u` instead, printing "unbound variable" after the real error message
# and exiting 1. Command substitution propagates the status properly.
selection_output="$(resolve_selection)" || exit $?
read_into SELECTED <<< "$selection_output"

port_for() { echo $(( $(service_port "$1") + port_offset )); }

# ── nginx output ──────────────────────────────────────────────────────────────
#
# Emitted from the same manifest the services are started from, so the proxy
# can't drift from the ports they actually listen on.

print_nginx() {
    local s
    echo "# Generated by allyabase-setup --nginx. Ports come from each service's"
    echo "# own default; do not hand-edit them here without changing the service."
    echo
    for s in "${SELECTED[@]}"; do
        echo "location /$s/ {"
        echo "    proxy_pass http://localhost:$(port_for "$s")/;"
        # savage builds absolute URLs back to itself (og:image, the vCard
        # link), so it has to be told the prefix the proxy strips. eumachia
        # takes the same information through PUBLIC_PREFIX in its env below.
        [[ "$s" == 'savage' ]] && echo "    proxy_set_header X-Forwarded-Prefix /$s;"
        echo "}"
        echo
    done
}

if [[ "$PRINT_NGINX" == true ]]; then
    print_nginx
    exit 0
fi

# ── Install ───────────────────────────────────────────────────────────────────

setup_services() {
    mkdir -p "$buildDir"
    cd "$buildDir"

    local service org
    for service in "${SELECTED[@]}"; do
        org="${default_org:-$(service_org "$service")}"

        if [[ -d "$service/.git" ]]; then
            printf '%s\n' "'$service' already cloned, skipping."
        else
            git clone "https://github.com/$org/$service"
        fi

        printf '%s\n' "Installing '$service'..."
        npm install "$service/src/server/node"
    done
}

# Per-service env beyond LOCALHOST/PORT. Emitted as JS object properties.
service_env_extras() {
    local service="$1"
    case "$service" in
        addie)
            cat <<-EOF
			        STRIPE_KEY: process.env.STRIPE_KEY || '<api key here>',
			        STRIPE_PUBLISHING_KEY: process.env.STRIPE_PUBLISHING_KEY || '<publishing key here>',
			        SQUARE_KEY: process.env.SQUARE_KEY || '<api key here>',
			EOF
            ;;
        savage)
            cat <<-EOF
			        BDO_URL: 'http://127.0.0.1:$(port_for bdo)/',
			        PUBLIC_PREFIX: '/savage',
			EOF
            ;;
        eumachia)
            cat <<-EOF
			        BDO_BASE_URL: 'http://127.0.0.1:$(port_for bdo)/',
			        ADDIE_BASE_URL: 'http://127.0.0.1:$(port_for addie)/',
			        PUBLIC_PREFIX: '/eumachia',
			EOF
            ;;
    esac
}

setup_ecosystem() {
    cd "$buildDir"

    if [[ ! -f package.json ]]; then
        echo "Initializing npm in this directory..."
        npm init -y
    fi

    # The docker image already installs pm2 globally, which provides the
    # pm2-runtime binary — installing a second local copy there is pure waste.
    # On a bare droplet there's usually nothing, so fall back to a local install.
    if ! command -v pm2-runtime >/dev/null 2>&1; then
        npm install pm2-runtime
    fi

    # Truncate rather than append: re-running setup previously concatenated a
    # second module.exports onto the existing file, producing a config whose
    # first half pm2 silently ignored.
    : > "$ecosystem_config"

    {
        echo 'module.exports = {'
        echo '  apps: ['
    } >> "$ecosystem_config"

    local service
    for service in "${SELECTED[@]}"; do
        {
            echo "    {"
            echo "      name: '$service',"
            echo "      script: '$buildDir/$service/src/server/node/${service}.js',"
            echo "      env: {"
            echo "        LOCALHOST: 'true',"
            echo "        PORT: '$(port_for "$service")',"
            service_env_extras "$service"
            echo "      }"
            echo "    },"
        } >> "$ecosystem_config"
    done

    {
        echo '  ]'
        echo '}'
    } >> "$ecosystem_config"
}

main() {
    echo "allyabase-setup"
    echo "  build dir:   $buildDir"
    echo "  services:    ${SELECTED[*]}"
    [[ "$port_offset" -ne 0 ]] && echo "  port offset: $port_offset"
    echo

    local s
    for s in "${SELECTED[@]}"; do
        printf '  %-14s :%s\n' "$s" "$(port_for "$s")"
    done
    echo

    if [[ "$dry_run" == true ]]; then
        echo "(dry run — nothing installed or started)"
        exit 0
    fi

    if [[ "$phase" == 'both' || "$phase" == 'install' ]]; then
        setup_services
    fi

    if [[ "$phase" == 'install' ]]; then
        echo
        echo "Installed ${#SELECTED[@]} services to $buildDir."
        echo "Run again with --start-only (and --port-offset if this is a multi-base setup) to launch them."
        exit 0
    fi

    setup_ecosystem

    if [[ "$phase" == 'config' ]]; then
        echo
        echo "Wrote $ecosystem_config (${#SELECTED[@]} services). Not starting pm2."
        exit 0
    fi

    echo
    echo "Starting ${#SELECTED[@]} services under pm2..."
    if command -v pm2-runtime >/dev/null 2>&1; then
        exec pm2-runtime start "$ecosystem_config"
    else
        exec ./node_modules/.bin/pm2-runtime start "$ecosystem_config"
    fi
}

main
