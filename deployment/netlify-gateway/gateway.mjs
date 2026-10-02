import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { SERVICES, startAll } from './services.mjs';

startAll();

const app = express();

app.get('/privacy.html', (req, res) => {
  res.set('Content-Type', 'text/html');
  res.send(`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Privacy</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    max-width: 640px;
    margin: 0 auto;
    padding: 64px 24px;
    line-height: 1.7;
    color: #1d1d1f;
    background: #f5f5f7;
  }
  h1 { font-size: 1.75rem; margin-bottom: 24px; }
  p { font-size: 1.05rem; margin: 0 0 20px; }
</style>
</head>
<body>
<h1>Privacy</h1>
<p>There is no privacy on the internet, and services which promise such are just one breach away from losing your data. Instead, we simply do not ask you for any information that is not already out there for a service like the one you're using. If it's a business card app, for instance, it's going to need a name and email just like what you'd have on a real business card. This card will be publicly available. If you don't want your name and email known, do not add them in the business card app. Stay suspicious of anyone who is not up front on how this works.</p>
</body>
</html>`);
});

for (const [name, { port }] of Object.entries(SERVICES)) {
  app.use(`/${name}`, createProxyMiddleware({
    target: `http://127.0.0.1:${port}`,
    changeOrigin: true,
    // changeOrigin rewrites the Host header to the internal loopback target,
    // so without this, any service backend has no way to know the real
    // external host/protocol it was reached at (savage needs this to build
    // an absolute, externally-fetchable og:image URL).
    xfwd: true,
    pathRewrite: { [`^/${name}`]: '' },
    // pathRewrite strips this prefix before the backend ever sees the
    // request - set per-request rather than via an env var read at module
    // load, since ES module imports (every service.js import above) are
    // always fully evaluated before any plain statement in this file runs,
    // so a load-time env var set here would be too late for services that
    // read it at their own module top level.
    onProxyReq: (proxyReq, req) => {
      proxyReq.setHeader('x-forwarded-prefix', `/${name}`);
      console.log(`[proxy->${name}] ${req.method} ${req.originalUrl} -> :${port}${proxyReq.path}`);
    },
    onProxyRes: (proxyRes, req) => {
      console.log(`[proxy<-${name}] ${req.method} ${req.originalUrl} <- ${proxyRes.statusCode}`);
    },
    onError: (err, req, res) => {
      console.error(`[proxy!${name}] ${req.method} ${req.originalUrl} error:`, err && err.stack || err);
      if (res && !res.headersSent) {
        res.writeHead(502, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ error: 'upstream_unreachable', service: name, message: String(err && err.message || err) }));
      }
    },
  }));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const PORT = process.env.GATEWAY_PORT || 8080;
  app.listen(PORT, () => console.log(`[gateway] proxy listening on ${PORT}`));
}

export default app;
