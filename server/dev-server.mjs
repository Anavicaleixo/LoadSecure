import http from 'node:http';
import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';
import worker from './index.js';
import { createSupabaseClient, createSupabaseAdapter } from './supabase-adapter.mjs';

if (process.loadEnvFile && existsSync('.env')) {
  process.loadEnvFile('.env');
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dbPath = path.resolve(__dirname, '../db/loadsecure.db');

export const createSqliteAdapter = (sqlite) => ({
  prepare(sql) {
    return {
      bind(...args) {
        return {
          async first() {
            return sqlite.prepare(sql).get(...args) || null;
          },
          async all() {
            return { results: sqlite.prepare(sql).all(...args) };
          },
          async run() {
            const stmt = sqlite.prepare(sql);
            if (/RETURNING/i.test(sql)) return { results: stmt.all(...args) };
            return { results: [], meta: stmt.run(...args) };
          }
        };
      }
    };
  },
  async batch(statements) {
    sqlite.exec('BEGIN');
    try {
      const out = [];
      for (const s of statements) out.push(await s.run());
      sqlite.exec('COMMIT');
      return out;
    } catch (e) {
      sqlite.exec('ROLLBACK');
      throw e;
    }
  }
});

let db;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
const useSupabase = process.env.DB_DRIVER === 'supabase' || (process.env.SUPABASE_URL && supabaseKey && process.env.DB_DRIVER !== 'sqlite');

if (useSupabase) {
  console.log(`[LoadSecure Server] Conectando ao Supabase em: ${process.env.SUPABASE_URL}`);
  const supabase = createSupabaseClient(process.env.SUPABASE_URL, supabaseKey);
  db = createSupabaseAdapter(supabase);
} else {
  if (!existsSync(dbPath)) {
    console.log('[Dev Server] Banco de dados SQLite não encontrado, executando inicialização...');
    await import('../scripts/init-db.mjs');
  }
  const sqlite = new DatabaseSync(dbPath);
  sqlite.exec('PRAGMA foreign_keys = ON;');
  db = createSqliteAdapter(sqlite);
  console.log(`[LoadSecure Server] Conectado ao banco SQLite local: ${dbPath}`);
}

const port = Number(process.env.PORT) || 8787;

const server = http.createServer(async (req, res) => {
  const origin = req.headers.origin || '*';
  const corsHeaders = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Credentials': 'true',
  };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  const host = req.headers.host || `localhost:${port}`;
  const fullUrl = `http://${host}${req.url}`;

  // Read body if POST/PUT
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  const body = Buffer.concat(chunks);

  const request = new Request(fullUrl, {
    method: req.method,
    headers: req.headers,
    body: ['GET', 'HEAD'].includes(req.method) ? undefined : body
  });

  try {
    const response = await worker.fetch(request, {
      DB: db,
      ASSETS: {
        async fetch() {
          return new Response('Not found', { status: 404 });
        }
      }
    });

    const headers = {
      ...corsHeaders,
      ...Object.fromEntries(response.headers.entries())
    };
    res.writeHead(response.status, headers);
    const resBody = await response.arrayBuffer();
    res.end(Buffer.from(resBody));
  } catch (err) {
    console.error('[Server Error]:', err);
    res.writeHead(500, { ...corsHeaders, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Internal Server Error' }));
  }
});

server.listen(port, () => {
  console.log(`[LoadSecure Server] Executando em http://localhost:${port}`);
  console.log(`[LoadSecure Server] Driver ativo: ${useSupabase ? 'Supabase (PostgreSQL)' : 'SQLite Local'}`);
});
