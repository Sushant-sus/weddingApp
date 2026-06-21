import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { apiRouter } from './router/index.js';
import { errorHandler } from './middleware/errorHandler.js';
import { notFound } from './middleware/notFound.js';

// CORS_ORIGIN is a comma-separated list. Each entry is normalized (trimmed,
// trailing slash dropped) and may contain `*` wildcards, e.g.
//   https://*.vercel.app           (any Vercel deployment URL)
//   https://wedding-*-me.vercel.app (only this project's preview URLs)
// This avoids chasing Vercel's per-deployment URLs in env config.
const normalize = (o: string) => o.trim().replace(/\/+$/, '');

const originMatchers = env.corsOrigin
  .split(',')
  .map(normalize)
  .filter(Boolean)
  .map((pattern) => {
    if (!pattern.includes('*')) return (o: string) => o === pattern;
    const regex = new RegExp(
      '^' + pattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^.]*') + '$',
    );
    return (o: string) => regex.test(o);
  });

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin(origin, callback) {
        // Allow non-browser clients (curl, health checks) that send no Origin.
        if (!origin || originMatchers.some((match) => match(normalize(origin)))) {
          return callback(null, true);
        }
        return callback(new Error(`Origin not allowed by CORS: ${origin}`));
      },
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));
  if (!env.isProd) app.use(morgan('dev'));

  app.use('/api/v1', apiRouter);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
