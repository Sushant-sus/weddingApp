import type { Request, Response, NextFunction } from 'express';
import { ZodError, type ZodTypeAny } from 'zod';
import { sendError } from '../utils/response.js';

type Source = 'body' | 'query' | 'params';

// Zod validation middleware. Parses the chosen request part and replaces it
// with the typed/coerced result, or returns a 400 with field details.
export const validate =
  (schema: ZodTypeAny, source: Source = 'body') =>
  (req: Request, res: Response, next: NextFunction) => {
    try {
      const parsed = schema.parse(req[source]);
      if (source === 'params') {
        // Merge so other route params (e.g. :eventId from a parent router) survive.
        Object.assign(req.params, parsed);
      } else {
        // query/params can be read-only getters in some Express setups; assign safely
        (req as unknown as Record<string, unknown>)[source] = parsed;
      }
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        return sendError(res, 400, 'VALIDATION_ERROR', 'Request validation failed', err.flatten());
      }
      next(err);
    }
  };
