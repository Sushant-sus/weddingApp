import 'dotenv/config';

function required(key: string, fallback?: string): string {
  const value = process.env[key] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

const isProd = (process.env.NODE_ENV ?? 'development') === 'production';

// JWT secrets: required in production, but fall back to dev-only values locally
// so the app still boots without a full .env during development.
const devAccessSecret = 'dev-access-secret-change-me-min-32-characters-long';
const devRefreshSecret = 'dev-refresh-secret-change-me-min-32-characters-long';

export const env = {
  databaseUrl: required('DATABASE_URL'),
  port: Number(process.env.PORT ?? 4000),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  corsOrigin:
    process.env.CORS_ORIGIN ??
    'http://localhost:5173,http://localhost:5100,http://127.0.0.1:5100,http://localhost:3000,http://127.0.0.1:3000',
  isProd,

  // Public base URL of the frontend (used in invite/verify email links).
  appUrl: process.env.APP_URL ?? 'http://localhost:5173',

  // JWT
  accessTokenSecret: isProd ? required('ACCESS_TOKEN_SECRET') : required('ACCESS_TOKEN_SECRET', devAccessSecret),
  refreshTokenSecret: isProd ? required('REFRESH_TOKEN_SECRET') : required('REFRESH_TOKEN_SECRET', devRefreshSecret),
  accessTokenExpires: process.env.ACCESS_TOKEN_EXPIRES ?? '15m',
  refreshTokenExpires: process.env.REFRESH_TOKEN_EXPIRES ?? '7d',

  // SMTP (optional — falls back to console logging if not configured)
  smtp: {
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT ?? 587),
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    from: process.env.SMTP_FROM ?? 'Wedding App <no-reply@wedding.app>',
    enabled: Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS),
  },
};
