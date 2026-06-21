import pg from 'pg';
const { Client } = pg;
const admin = new Client({ connectionString: 'postgresql://postgres:postgres@localhost:5433/postgres' });
try {
  await admin.connect();
  const r = await admin.query("SELECT 1 FROM pg_database WHERE datname='wedding_db'");
  if (r.rowCount === 0) {
    await admin.query('CREATE DATABASE wedding_db');
    console.log('Created database wedding_db');
  } else {
    console.log('Database wedding_db already exists');
  }
} catch (e) {
  console.error('FAILED:', e.message);
  process.exitCode = 1;
} finally {
  await admin.end();
}
