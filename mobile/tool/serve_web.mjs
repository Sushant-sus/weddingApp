// Serves the built Flutter web app (build/web) and proxies /api/v1/* to the
// deployed backend. The browser talks same-origin to this server, so there is
// no CORS preflight; the proxied request is server-to-server (no Origin header),
// which the backend already permits.
//
// Usage:
//   node tool/serve_web.mjs                       # defaults below
//   PORT=8080 API_TARGET=https://host node tool/serve_web.mjs
//
// Zero dependencies — only Node's built-in http/https/fs modules.

import http from 'node:http';
import https from 'node:https';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const PORT = Number(process.env.PORT ?? 8080);
const API_TARGET = (process.env.API_TARGET ?? 'https://weddingapp-ox7i.onrender.com').replace(/\/+$/, '');
const WEB_ROOT = fileURLToPath(new URL('../build/web', import.meta.url));

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.map': 'application/json; charset=utf-8',
};

if (!existsSync(WEB_ROOT)) {
  console.error(`Build output not found at ${WEB_ROOT}`);
  console.error('Run: flutter build web --release --dart-define=API_BASE_URL=http://localhost:' + PORT + '/api/v1');
  process.exit(1);
}

const target = new URL(API_TARGET);

function proxy(req, res) {
  const headers = { ...req.headers };
  // Strip browser-only headers; let the backend see a clean server request.
  delete headers.host;
  delete headers.origin;
  delete headers.referer;
  headers.host = target.host;

  const transport = target.protocol === 'http:' ? http : https;
  const upstream = transport.request(
    {
      protocol: target.protocol,
      hostname: target.hostname,
      port: target.port || (target.protocol === 'https:' ? 443 : 80),
      method: req.method,
      path: req.url,
      headers,
    },
    (up) => {
      res.writeHead(up.statusCode ?? 502, up.headers);
      up.pipe(res);
    },
  );
  upstream.on('error', (err) => {
    res.writeHead(502, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ success: false, error: { code: 'PROXY_ERROR', message: err.message } }));
  });
  req.pipe(upstream);
}

function serveStatic(req, res) {
  const urlPath = decodeURIComponent((req.url ?? '/').split('?')[0]);
  let filePath = normalize(join(WEB_ROOT, urlPath));
  // Prevent path traversal outside the web root.
  if (!filePath.startsWith(WEB_ROOT)) {
    res.writeHead(403).end('Forbidden');
    return;
  }
  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(filePath, 'index.html');
  }
  // SPA fallback: unknown routes (no file extension) serve index.html.
  if (!existsSync(filePath)) {
    if (extname(filePath)) {
      res.writeHead(404).end('Not found');
      return;
    }
    filePath = join(WEB_ROOT, 'index.html');
  }
  const type = MIME[extname(filePath)] ?? 'application/octet-stream';
  res.writeHead(200, { 'content-type': type });
  createReadStream(filePath).pipe(res);
}

http
  .createServer((req, res) => {
    if ((req.url ?? '').startsWith('/api/')) return proxy(req, res);
    return serveStatic(req, res);
  })
  .listen(PORT, () => {
    console.log(`\n  Aayojan web app  →  http://localhost:${PORT}`);
    console.log(`  API proxied to   →  ${API_TARGET}/api/v1\n`);
  });
