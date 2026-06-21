// Cross-platform SQL file runner — an alternative to psql.
// Usage: node scripts/run-sql.mjs <path-to-sql-file>
// Reads DATABASE_URL from server/.env
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { config } from 'dotenv';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, '..', '.env') });

const file = process.argv[2];
if (!file) {
  console.error('Usage: node scripts/run-sql.mjs <file.sql>');
  process.exit(1);
}

const sql = readFileSync(resolve(__dirname, '..', file), 'utf8');

const { Client } = pg;
const client = new Client({ connectionString: process.env.DATABASE_URL });

try {
  await client.connect();
  console.log(`Running ${file} ...`);
  await client.query(sql);
  console.log('Done ✓');
} catch (err) {
  console.error('SQL execution failed:\n', err.message);
  process.exitCode = 1;
} finally {
  await client.end();
}
