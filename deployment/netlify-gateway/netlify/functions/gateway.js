// CJS shim over the ESM Express app in ../../gateway.mjs.
//
// zisi (Netlify's non-esbuild function bundler) wraps every function in a
// CJS shim that does `require()` on the entry file. That can't load a .mjs
// or otherwise-ESM entry directly, so the entry file itself must be CJS.
// The gateway app and every sibling service it imports are ESM, so we
// keep this shim tiny and defer to dynamic `import()` for the real work.
//
// The one-shot init (cached in `handlerPromise`) means the ESM import
// only happens on the first invocation of a warm instance, not every
// request.

let handlerPromise;

async function getHandler() {
  if (!handlerPromise) {
    handlerPromise = (async () => {
      const serverless = (await import('serverless-http')).default;
      const blobs = await import('@netlify/blobs');
      const { default: app } = await import('../../gateway.mjs');
      const raw = serverless(app);
      return (event, context) => {
        // `event.blobs` is only present on real Netlify infra — absent
        // when running locally against a BLOBS_LOCAL_URL/BLOBS_LOCAL_TOKEN
        // dev server.
        if (event.blobs && blobs.connectLambda) {
          blobs.connectLambda(event);
        }
        return raw(event, context);
      };
    })();
  }
  return handlerPromise;
}

exports.handler = async (event, context) => {
  const started = Date.now();
  const path = event.rawUrl || event.path || '(no path)';
  const method = event.httpMethod || '(no method)';
  try {
    const h = await getHandler();
    const res = await h(event, context);
    console.log(`[gw] ${method} ${path} -> ${res && res.statusCode} in ${Date.now() - started}ms`);
    return res;
  } catch (err) {
    console.error(`[gw] ${method} ${path} threw after ${Date.now() - started}ms:`, err && err.stack || err);
    return {
      statusCode: 500,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ error: 'gateway_error', message: String(err && err.message || err) }),
    };
  }
};
