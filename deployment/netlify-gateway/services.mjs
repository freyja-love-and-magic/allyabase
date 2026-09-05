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
import sanoraApp from '../sanora/src/server/node/sanora.js';
import addieApp from '../addie/src/server/node/addie.js';
import fountApp from '../fount/src/server/node/fount.js';
import prefApp from '../pref/src/server/node/pref.js';
import joanApp from '../joan/src/server/node/joan.js';
import continuebeeApp from '../continuebee/src/server/node/continuebee.js';
import arethaApp from '../aretha/src/server/node/aretha.js';
import juliaApp from '../julia/src/server/node/julia.js';
import doloresApp from '../dolores/src/server/node/dolores.js';
// minnie deliberately omitted — it's an SMTP server (long-lived TCP
// daemon on port 2525), not an HTTP Express app, so it can't run
// inside a Lambda function. If it ever gains an HTTP surface, add
// it back here.
import savageApp from '../savage/src/server/node/savage.js';
import eumachiaApp from '../eumachia/src/server/node/eumachia.js';

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
  pref: { app: prefApp, port: 3002 },
  joan: { app: joanApp, port: 3004 },
  bdo: { app: bdoApp, port: 3003 },
  fount: { app: fountApp, port: 3006 },
  addie: { app: addieApp, port: 3005 },
  continuebee: { app: continuebeeApp, port: 2999 },
  aretha: { app: arethaApp, port: 7277 },
  julia: { app: juliaApp, port: 3000 },
  dolores: { app: doloresApp, port: 3007 },
  sanora: { app: sanoraApp, port: 7243 },
  savage: { app: savageApp, port: 3009 },
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
