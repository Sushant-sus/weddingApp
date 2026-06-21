import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { apiRouter } from './router/index.js';
import { errorHandler } from './middleware/errorHandler.js';
import { notFound } from './middleware/notFound.js';

// CORS_ORIGIN may be a comma-separated list; normalize by trimming and
// dropping any trailing slash so a stray "/" (a very common mistake) or an
// extra domain doesn't break browser requests.
const normalize = (o: string) => o.trim().replace(/\/+$/, '');
const allowedOrigins = env.corsOrigin.split(',').map(normalize).filter(Boolean);

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin(origin, callback) {
        // Allow non-browser clients (curl, health checks) that send no Origin.
        if (!origin || allowedOrigins.includes(normalize(origin))) {
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
