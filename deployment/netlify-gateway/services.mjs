// Every allyabase service already has a LOCALHOST-conditional wired into its
// inter-service calls, e.g. bdo.js: `fount.baseURL = process.env.LOCALHOST ?
// 'http://localhost:3006/' : 'https://...allyabase.com/'`. That pattern exists
// for local dev (docker-compose style: run every service on its own port on
// one machine). We're reusing it here for a different reason: a bundled
// Netlify Function is exactly that same topology - one process, many
// services, loopback between them - so setting LOCALHOST=true and binding
// each service to its conventional port turns what used to be "call a
// possibly-cold separate Function over the network" into "call an
// already-listening object in this same process."
process.env.LOCALHOST = process.env.LOCALHOST || 'true';
process.env.PERSISTENCE_BACKEND = process.env.PERSISTENCE_BACKEND || 'netlify-blobs';

import bdoApp from '../bdo/src/server/node/bdo.js';
import addieApp from '../addie/src/server/node/addie.js';
import fountApp from '../fount/src/server/node/fount.js';
import eumachiaApp from '../eumachia/src/server/node/eumachia.js';
// TEMPORARY: bundle limited to a slice that fits under Lambda's 250MB
// unzipped code cap. The full 12-service bundle blows the limit on
// netlify-packaging branches (dolores alone pulls in ~100MB of
// @opentelemetry / @atproto / rxjs / etc.).
//
// Current slice covers getpayed end-to-end:
//   - addie   → Stripe Express onboarding (also used by bizbuz)
//   - fount   → identity (transitively required by addie)
//   - bdo     → invoice publish + canonical profile storage
//   - eumachia → the actual pay page + PaymentIntent/status routes
//                (savage strips JS so it can't host Stripe Elements,
//                which is why eumachia owns the interactive checkout).
//
// Restore the other imports once we split into per-service functions
// or aggressively prune upstream — see the prune list in
// scripts/prepare-services.sh for what we've already cut.
//
// Currently omitted: sanora, pref, joan, continuebee, aretha, julia,
// dolores, savage, minnie.

// Ports match each service's own standalone app.listen() default exactly -
// see each service's <name>.js. Several services bootstrap themselves against
// fount and/or addie at import time (a `repeat(bootstrap)` retry loop that
// fires every 2s until it succeeds) - those first attempts will fail here
// too, since imports finish (and every service's bootstrap loop starts)
// before startAll() below has bound any ports. They self-heal on their next
// retry, ~2s after startAll() runs - same self-healing behavior as the
// droplet deployment, just now resolving against a local peer instead of a
// network call.
const SERVICES = {
  bdo: { app: bdoApp, port: 3003 },
  fount: { app: fountApp, port: 3006 },
  addie: { app: addieApp, port: 3005 },
  eumachia: { app: eumachiaApp, port: 3011 },
};

let started = false;

const startAll = () => {
  if (started) {
    return SERVICES;
  }
  started = true;

  for (const [name, { app, port }] of Object.entries(SERVICES)) {
    app.listen(port, '127.0.0.1', () => {
      console.log(`[gateway] ${name} listening on 127.0.0.1:${port}`);
    });
  }

  return SERVICES;
};

export { SERVICES, startAll };
