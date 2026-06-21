import type { Request, Response, NextFunction } from 'express';
import { AppError } from '../../utils/AppError.js';
import { verifyAccessToken } from '../../lib/security.js';

// Verify the Bearer access token and attach the decoded user to req.user.
export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new AppError(401, 'UNAUTHENTICATED', 'Authentication required'));
  }
  try {
    req.user = verifyAccessToken(header.slice(7));
    next();
  } catch {
    next(new AppError(401, 'INVALID_ACCESS_TOKEN', 'Access token is invalid or expired'));
  }
}

// Require the user's global role to be one of the allowed roles.
export function requireRole(...roles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) return next(new AppError(401, 'UNAUTHENTICATED', 'Authentication required'));
    if (!roles.includes(req.user.role)) {
      return next(new AppError(403, 'FORBIDDEN', 'You do not have access to this resource'));
    }
    next();
  };
}

// Require the user to hold ALL of the given permissions.
export function requirePermission(...permissions: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) return next(new AppError(401, 'UNAUTHENTICATED', 'Authentication required'));
    const held = new Set(req.user.permissions ?? []);
    // SUPERADMIN bypasses granular permission checks.
    if (req.user.role === 'SUPERADMIN') return next();
    const missing = permissions.filter((p) => !held.has(p));
    if (missing.length > 0) {
      return next(new AppError(403, 'FORBIDDEN', `Missing permission: ${missing.join(', ')}`));
    }
    next();
  };
}
