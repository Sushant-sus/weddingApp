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
  'USER_NOT_FOUND',
  'PROVIDER_NOT_FOUND',
  'REQUEST_NOT_FOUND',
  'PITCH_NOT_FOUND',
];

// Stored-procedure error substring → [httpStatus, code, message]
const SP_ERROR_MAP: Array<[string, number, string, string]> = [
  ['EMAIL_ALREADY_EXISTS', 409, 'EMAIL_ALREADY_EXISTS', 'Email is already registered'],
  ['INVALID_OTP', 400, 'INVALID_OTP', 'OTP is invalid or has expired'],
  ['INVALID_REFRESH_TOKEN', 401, 'INVALID_REFRESH_TOKEN', 'Session expired, please log in again'],
  ['USER_INACTIVE', 403, 'USER_INACTIVE', 'Your account is inactive'],
  ['EMAIL_NOT_VERIFIED', 403, 'EMAIL_NOT_VERIFIED', 'Please verify your email first'],
  ['INVALID_CREDENTIALS', 401, 'INVALID_CREDENTIALS', 'Invalid email or password'],
  ['INSUFFICIENT_PERMISSION', 403, 'INSUFFICIENT_PERMISSION', 'You do not have permission for this action'],
  ['INSUFFICIENT_EVENT_ROLE', 403, 'INSUFFICIENT_EVENT_ROLE', 'You do not have permission for this action'],
  ['NOT_A_MEMBER', 403, 'NOT_A_MEMBER', 'You are not a member of this event'],
  ['ALREADY_A_MEMBER', 409, 'ALREADY_A_MEMBER', 'User is already a member of this event'],
  ['INVALID_INVITE', 400, 'INVALID_INVITE', 'Invite is invalid or expired'],
  ['CANNOT_CHANGE_OWNER_ROLE', 403, 'CANNOT_CHANGE_OWNER_ROLE', 'The owner role cannot be changed'],
  ['CANNOT_REMOVE_OWNER', 403, 'CANNOT_REMOVE_OWNER', 'The owner cannot be removed'],
  ['USER_NOT_MEMBER', 400, 'USER_NOT_MEMBER', 'Target user is not a member of this event'],
  ['EVENT_NOT_FOUND_OR_NO_ACCESS', 404, 'EVENT_NOT_FOUND', 'Event not found or you lack access'],
  ['REQUEST_NOT_LIVE', 409, 'REQUEST_NOT_LIVE', 'This request is no longer accepting pitches'],
  ['ALREADY_PITCHED', 409, 'ALREADY_PITCHED', 'You have already pitched for this request'],
  ['NOT_PROVIDER', 403, 'NOT_PROVIDER', 'Create a provider profile first'],
  ['GIVER_REQUIRED', 400, 'GIVER_REQUIRED', 'A guest or giver name is required'],
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

  // Mapped stored-procedure errors (auth, events, permissions).
  for (const [needle, status, code, friendly] of SP_ERROR_MAP) {
    if (message.includes(needle)) {
      return sendError(res, status, code, friendly);
    }
  }

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
