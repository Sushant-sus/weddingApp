import type { AccessTokenPayload } from '../lib/security.js';

// Augment Express Request with the authenticated user and event role.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AccessTokenPayload;
      eventRole?: string;
    }
  }
}

export {};
