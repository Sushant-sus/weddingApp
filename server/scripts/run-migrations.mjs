// Runs every prisma/migrations/*.sql file in filename order (001, 002, …),
// then the base seed-procedures.sql is NOT needed (migrations are authoritative).
// All files are idempotent (CREATE OR REPLACE / IF NOT EXISTS).
//
// Usage: node scripts/run-migrations.mjs   (reads DATABASE_URL from .env)
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { config } from 'dotenv';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, '..', '.env') });

const migrationsDir = resolve(__dirname, '..', 'prisma', 'migrations');
const files = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort();

const rawUrl = process.env.DATABASE_URL ?? '';
const needsSsl = /supabase\.co|sslmode=require/i.test(rawUrl);
const url = rawUrl.replace(/[?&]sslmode=[^&]*/i, '');

const { Client } = pg;
const client = new Client({
  connectionString: url,
  ...(needsSsl ? { ssl: { rejectUnauthorized: false } } : {}),
});

try {
  await client.connect();
  for (const file of files) {
    const sql = readFileSync(resolve(migrationsDir, file), 'utf8');
    process.stdout.write(`→ ${file} ... `);
    await client.query(sql);
    console.log('ok');
  }
  console.log('\nAll migrations applied ✓');
} catch (err) {
  console.error('\nMigration failed:', err.message);
  process.exitCode = 1;
} finally {
  await client.end();
}
