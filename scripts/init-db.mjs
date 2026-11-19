import { DatabaseSync } from 'node:sqlite';
import { readFileSync, readdirSync, existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const dbDir = path.join(projectRoot, 'db');
const dbPath = path.join(dbDir, 'loadsecure.db');
const drizzleDir = path.join(projectRoot, 'drizzle');

if (!existsSync(dbDir)) {
  mkdirSync(dbDir, { recursive: true });
}

console.log(`[DB] Conectando ao banco de dados SQLite em: ${dbPath}`);
const sqlite = new DatabaseSync(dbPath);
sqlite.exec('PRAGMA foreign_keys = ON;');

// Tabela de controle de migrações
sqlite.exec(`
  CREATE TABLE IF NOT EXISTS _migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    applied_at INTEGER NOT NULL
  );
`);

const migrationFiles = readdirSync(drizzleDir)
  .filter(f => f.endsWith('.sql'))
  .sort();

console.log(`[DB] Encontradas ${migrationFiles.length} migration(s).`);

const appliedRows = sqlite.prepare('SELECT name FROM _migrations').all();
const appliedSet = new Set(appliedRows.map(r => r.name));

// Se as tabelas já existiam no banco antes do registro de migração
const hasCompanies = sqlite.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='companies'").get();
if (hasCompanies && !appliedSet.has('0000_long_vin_gonzales.sql')) {
  sqlite.prepare('INSERT OR IGNORE INTO _migrations (name, applied_at) VALUES (?, ?)').run('0000_long_vin_gonzales.sql', Date.now());
  appliedSet.add('0000_long_vin_gonzales.sql');
}

let appliedCount = 0;
for (const file of migrationFiles) {
  if (appliedSet.has(file)) {
    console.log(`[DB] Migration já aplicada: ${file}`);
    continue;
  }

  console.log(`[DB] Aplicando migration: ${file}...`);
  const sql = readFileSync(path.join(drizzleDir, file), 'utf8');
  const statements = sql
    .split('--> statement-breakpoint')
    .map(s => s.trim())
    .filter(Boolean);

  sqlite.exec('BEGIN');
  try {
    for (const statement of statements) {
      sqlite.exec(statement);
    }
    sqlite.prepare('INSERT INTO _migrations (name, applied_at) VALUES (?, ?)').run(file, Date.now());
    sqlite.exec('COMMIT');
    appliedCount++;
    console.log(`[DB] Migration ${file} aplicada com sucesso!`);
  } catch (err) {
    sqlite.exec('ROLLBACK');
    throw err;
  }
}

// Listar tabelas presentes
const tables = sqlite.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name").all();
console.log('[DB] Tabelas presentes no banco de dados:');
for (const t of tables) {
  console.log(`  - ${t.name}`);
}

sqlite.close();
console.log('[DB] Banco de dados pronto e atualizado com sucesso!');
