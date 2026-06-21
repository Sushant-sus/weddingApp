import type { Request, Response, NextFunction } from 'express';
import { prisma } from '../../prisma/client.js';
import { AppError } from '../../utils/AppError.js';

interface Membership {
  event_role: string;
  invite_status: string;
}

// Guards an event-scoped route: the authenticated user must be an ACCEPTED
// member of req.params.eventId with one of the allowed event roles.
// SUPERADMIN bypasses event-role checks (global override).
export function requireEventRole(...allowedRoles: string[]) {
  return async (req: Request, _res: Response, next: NextFunction) => {
    try {
      if (!req.user) throw new AppError(401, 'UNAUTHENTICATED', 'Authentication required');
      const eventId = req.params.eventId;
      if (!eventId) throw new AppError(400, 'EVENT_ID_REQUIRED', 'Event id is required');

      const rows = await prisma.$queryRaw<[{ sp_event_get_my_membership: Membership | null }]>`
        SELECT wedding.sp_event_get_my_membership(${eventId}::UUID, ${req.user.userId}::UUID)
      `;
      const member = rows[0].sp_event_get_my_membership;

      if (req.user.role === 'SUPERADMIN') {
        req.eventRole = member?.event_role ?? 'OWNER';
        return next();
      }

      if (!member || member.invite_status !== 'ACCEPTED') {
        throw new AppError(403, 'NOT_A_MEMBER', 'You are not a member of this event');
      }
      if (!allowedRoles.includes(member.event_role)) {
        throw new AppError(403, 'INSUFFICIENT_EVENT_ROLE', 'You do not have permission for this action');
      }

      req.eventRole = member.event_role;
      next();
    } catch (err) {
      next(err);
    }
  };
}

// Convenience role groups matching the permission matrix.
export const ROLE = {
  ALL: ['OWNER', 'LEADER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER'],
  CONTRIBUTE: ['OWNER', 'LEADER', 'EDITOR', 'CONTRIBUTOR'],
  EDIT: ['OWNER', 'LEADER', 'EDITOR'],
  MANAGE: ['OWNER', 'LEADER'],
  OWNER_ONLY: ['OWNER'],
} as const;
