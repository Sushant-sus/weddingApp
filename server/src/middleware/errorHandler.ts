import type { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError.js';
import { sendError } from '../utils/response.js';

// Maps known Postgres stored-procedure error strings to HTTP responses, and
// produces the consistent JSON error shape for everything else.
const NOT_FOUND_CODES = [
  'GUEST_NOT_FOUND',
  'GIFT_NOT_FOUND',
  'EVENT_NOT_FOUND',
  'COST_ITEM_NOT_FOUND',
];

export const errorHandler = (
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
) => {
  // Explicit application errors win.
  if (err instanceof AppError) {
    return sendError(res, err.statusCode, err.code, err.message, err.details);
  }

  const message = err instanceof Error ? err.message : String(err);

  // Stored-procedure "not found" errors → 404 with the matching code.
  for (const code of NOT_FOUND_CODES) {
    if (message.includes(code)) {
      const label = code
        .replace(/_/g, ' ')
        .toLowerCase()
        .replace(/^\w/, (c) => c.toUpperCase());
      return sendError(res, 404, code, label.replace('Not found', 'not found'));
    }
  }

  // Unique violation surfaced from Postgres.
  if (message.includes('duplicate key value') || (err as { code?: string })?.code === '23505') {
    return sendError(res, 409, 'CONFLICT', 'Resource already exists');
  }

  console.error('[Unhandled Error]', err);
  return sendError(res, 500, 'INTERNAL_ERROR', 'Something went wrong');
};
