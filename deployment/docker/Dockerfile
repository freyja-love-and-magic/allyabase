FROM node:22.14.0

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y git vim

# Services are cloned and installed by allyabase_setup.sh, which owns the
# service list, each service's default port, and its env. This used to be 11
# hardcoded `git clone` lines plus 11 `WORKDIR`/`npm install` pairs that had to
# be edited by hand whenever a service was added — and which silently omitted
# prof, savage, and eumachia.
#
# ALLYABASE_SERVICES picks a subset at build time; bdo, continuebee, and fount
# are always installed. Clone URLs come from the setup script's manifest, so
# they don't need repeating here.
ARG ALLYABASE_SERVICES=""
# Pin the branch explicitly. Cloning without -b takes the remote's default
# branch, which does NOT have the manifest-driven setup script — and the old
# script has no option parsing at all, so it silently treats "--dir=..." as a
# positional build dir, fails its mkdir, then clones every service into the
# current directory instead. Both of the errors that produces are confusing
# and neither points at the branch.
#
# Change this to main once pick-and-choose is merged.
ARG ALLYABASE_BRANCH=pick-and-choose
RUN git clone -b "$ALLYABASE_BRANCH" https://www.github.com/freyja-love-and-magic/allyabase.git allyabase
RUN chmod +x /usr/src/app/allyabase/deployment/allyabase_setup.sh

# Fail loudly and immediately if the cloned script predates the manifest,
# rather than letting the old script's arg-handling produce a mystery.
RUN grep -q -- '--dir=\*' /usr/src/app/allyabase/deployment/allyabase_setup.sh \
    || (echo "ERROR: allyabase branch '$ALLYABASE_BRANCH' has a pre-manifest allyabase_setup.sh" >&2; exit 1)

# Every port in allyabase_setup.sh's manifest, plus the docker-only apps.
# The old list omitted 3006 — fount's, and fount is a required service — and
# exposed 3001, which nothing listens on. Keep this in sync with `--list`.
#   2525 minnie   2999 continuebee  3000 julia    3002 pref     3003 bdo
#   3004 joan     3005 addie        3006 fount    3007 dolores  3008 prof
#   3010 glyphenge (docker-only)    3012 savage   3013 eumachia
#   3333 wiki (docker-only)         7243 sanora   7277 aretha
EXPOSE 2525 2999 3000 3002 3003 3004 3005 3006 3007 3008 3010 3012 3013 3333 7243 7277

RUN npm install -g pm2
RUN npm install -g wiki

# --dir, not a positional: the positional form appends '/allyabase', which
# would collide with the allyabase repo checked out just above.
RUN /usr/src/app/allyabase/deployment/allyabase_setup.sh \
      --dir=/usr/src/app --install-only \
      ${ALLYABASE_SERVICES:+--services="$ALLYABASE_SERVICES"}

WORKDIR /usr/src/app

COPY start.sh /usr/src/app/
RUN chmod +x /usr/src/app/start.sh

ENV PM2_SAVE_INTERVAL=30000
ENV PM2_LOG_DATE_FORMAT="YYYY-MM-DD HH:mm:ss.SSS"

CMD ["./start.sh"]

