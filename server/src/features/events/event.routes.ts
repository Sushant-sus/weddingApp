import { Router } from 'express';
import { eventController } from './event.controller.js';
import { eventScopedRouter } from './event.dataRoutes.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { authenticate } from '../auth/auth.middleware.js';
import { requireEventRole, ROLE } from './event.middleware.js';
import {
  changeRoleSchema,
  createEventSchema,
  eventIdParamSchema,
  inviteMemberSchema,
  inviteTokenSchema,
  memberParamSchema,
  transferOwnershipSchema,
  updateEventSchema,
} from './event.schema.js';

export const eventRouter = Router();

// Every event route requires an authenticated user.
eventRouter.use(authenticate);

// Invite responses (token-based, no event guard) — declare before /:eventId.
eventRouter.post('/invite/accept', validate(inviteTokenSchema), asyncHandler(eventController.acceptInvite));
eventRouter.post('/invite/decline', validate(inviteTokenSchema), asyncHandler(eventController.declineInvite));

// Event collection
eventRouter.post('/', validate(createEventSchema), asyncHandler(eventController.create));
eventRouter.get('/', asyncHandler(eventController.list));

// Single event
eventRouter.get('/:eventId', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.ALL), asyncHandler(eventController.getOne));
eventRouter.patch('/:eventId', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.MANAGE), validate(updateEventSchema), asyncHandler(eventController.update));
eventRouter.delete('/:eventId', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.OWNER_ONLY), asyncHandler(eventController.remove));

// Members
eventRouter.get('/:eventId/members', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.ALL), asyncHandler(eventController.members));
eventRouter.post('/:eventId/members/invite', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.MANAGE), validate(inviteMemberSchema), asyncHandler(eventController.invite));
eventRouter.patch('/:eventId/members/:userId/role', validate(memberParamSchema, 'params'), requireEventRole(...ROLE.MANAGE), validate(changeRoleSchema), asyncHandler(eventController.changeRole));
eventRouter.delete('/:eventId/members/:userId', validate(memberParamSchema, 'params'), requireEventRole(...ROLE.MANAGE), asyncHandler(eventController.removeMember));
eventRouter.post('/:eventId/transfer-ownership', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.OWNER_ONLY), validate(transferOwnershipSchema), asyncHandler(eventController.transferOwnership));

// Activity log
eventRouter.get('/:eventId/activity', validate(eventIdParamSchema, 'params'), requireEventRole(...ROLE.ALL), asyncHandler(eventController.activity));

// Event-scoped data (guests, gifts, itinerary, costs)
eventRouter.use('/:eventId', eventScopedRouter);
