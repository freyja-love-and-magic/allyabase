import { BlobsServer } from '@netlify/blobs/server';

const port = Number(process.env.BLOBS_LOCAL_PORT) || 8999;
const token = process.env.BLOBS_LOCAL_TOKEN || 'local-dev-token';
const directory = process.env.BLOBS_LOCAL_DIR || 'data/netlify-blobs';

const server = new BlobsServer({ directory, port, token });

await server.start();

console.log(`Netlify Blobs local dev server listening on http://localhost:${port}`);
console.log(`Persisting to ${directory}`);
