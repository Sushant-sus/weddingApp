import { Router } from 'express';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { requireEventRole, ROLE } from './event.middleware.js';

import { guestController } from '../guests/guest.controller.js';
import { giftController } from '../gifts/gift.controller.js';
import { itineraryController } from '../itinerary/itinerary.controller.js';
import { costController } from '../costs/cost.controller.js';
import { requestController } from '../requests/request.controller.js';

import {
  batchUpdateSchema,
  createGuestSchema,
  guestFiltersSchema,
  idParamSchema as guestIdParam,
  updateGuestSchema,
} from '../guests/guest.schema.js';
import { createGiftSchema, giftIdParamSchema, guestIdParamSchema, quickGiftSchema, updateGiftSchema } from '../gifts/gift.schema.js';
import { createEventSchema as createItinerarySchema, eventIdParamSchema as itineraryIdParam, reorderSchema, setStatusSchema, updateEventSchema as updateItinerarySchema } from '../itinerary/itinerary.schema.js';
import { costFiltersSchema, costIdParamSchema, createCostSchema, updateCostSchema } from '../costs/cost.schema.js';
import { createRequestSchema } from '../requests/request.schema.js';

// All routes are mounted under /events/:eventId — mergeParams exposes eventId.
export const eventScopedRouter = Router({ mergeParams: true });

// ---------------- GUESTS ----------------
eventScopedRouter.get('/guests/summary', requireEventRole(...ROLE.ALL), asyncHandler(guestController.summary));
eventScopedRouter.get('/guests', requireEventRole(...ROLE.ALL), validate(guestFiltersSchema, 'query'), asyncHandler(guestController.list));
eventScopedRouter.post('/guests', requireEventRole(...ROLE.CONTRIBUTE), validate(createGuestSchema), asyncHandler(guestController.create));
eventScopedRouter.patch('/guests/batch', requireEventRole(...ROLE.EDIT), validate(batchUpdateSchema), asyncHandler(guestController.batchUpdate));
eventScopedRouter.get('/guests/:id', requireEventRole(...ROLE.ALL), validate(guestIdParam, 'params'), asyncHandler(guestController.getOne));
eventScopedRouter.patch('/guests/:id', requireEventRole(...ROLE.EDIT), validate(guestIdParam, 'params'), validate(updateGuestSchema), asyncHandler(guestController.update));
eventScopedRouter.delete('/guests/:id', requireEventRole(...ROLE.EDIT), validate(guestIdParam, 'params'), asyncHandler(guestController.remove));

// ---------------- GIFTS ----------------
eventScopedRouter.get('/gifts/summary', requireEventRole(...ROLE.ALL), asyncHandler(giftController.summary));
eventScopedRouter.get('/gifts', requireEventRole(...ROLE.ALL), asyncHandler(giftController.list));
// Fast gift-desk entry: guest-linked OR free-text giver name.
eventScopedRouter.post('/gifts', requireEventRole(...ROLE.CONTRIBUTE), validate(quickGiftSchema), asyncHandler(giftController.quickCreate));
eventScopedRouter.patch('/gifts/:id', requireEventRole(...ROLE.EDIT), validate(giftIdParamSchema, 'params'), validate(updateGiftSchema), asyncHandler(giftController.update));
eventScopedRouter.delete('/gifts/:id', requireEventRole(...ROLE.MANAGE), validate(giftIdParamSchema, 'params'), asyncHandler(giftController.remove));
eventScopedRouter.get('/guests/:guestId/gifts', requireEventRole(...ROLE.ALL), validate(guestIdParamSchema, 'params'), asyncHandler(giftController.listForGuest));
eventScopedRouter.post('/guests/:guestId/gifts', requireEventRole(...ROLE.CONTRIBUTE), validate(guestIdParamSchema, 'params'), validate(createGiftSchema), asyncHandler(giftController.create));

// ---------------- ITINERARY ----------------
eventScopedRouter.get('/itinerary', requireEventRole(...ROLE.ALL), asyncHandler(itineraryController.list));
eventScopedRouter.post('/itinerary', requireEventRole(...ROLE.EDIT), validate(createItinerarySchema), asyncHandler(itineraryController.create));
eventScopedRouter.patch('/itinerary/reorder', requireEventRole(...ROLE.EDIT), validate(reorderSchema), asyncHandler(itineraryController.reorder));
eventScopedRouter.patch('/itinerary/:id/status', requireEventRole(...ROLE.EDIT), validate(itineraryIdParam, 'params'), validate(setStatusSchema), asyncHandler(itineraryController.setStatus));
eventScopedRouter.patch('/itinerary/:id', requireEventRole(...ROLE.EDIT), validate(itineraryIdParam, 'params'), validate(updateItinerarySchema), asyncHandler(itineraryController.update));
eventScopedRouter.delete('/itinerary/:id', requireEventRole(...ROLE.MANAGE), validate(itineraryIdParam, 'params'), asyncHandler(itineraryController.remove));

// ---------------- SERVICE MARKETPLACE (host side) ----------------
// Itinerary with each item's active service request (the "service pill").
eventScopedRouter.get('/itinerary-services', requireEventRole(...ROLE.ALL), asyncHandler(requestController.itineraryServices));
eventScopedRouter.get('/service-requests', requireEventRole(...ROLE.ALL), asyncHandler(requestController.listForEvent));
eventScopedRouter.post('/service-requests', requireEventRole(...ROLE.CONTRIBUTE), validate(createRequestSchema), asyncHandler(requestController.create));

// ---------------- COSTS (financial privacy → OWNER/LEADER only) ----------------
eventScopedRouter.get('/costs/summary', requireEventRole(...ROLE.MANAGE), asyncHandler(costController.summary));
eventScopedRouter.get('/costs', requireEventRole(...ROLE.MANAGE), validate(costFiltersSchema, 'query'), asyncHandler(costController.list));
eventScopedRouter.post('/costs', requireEventRole(...ROLE.MANAGE), validate(createCostSchema), asyncHandler(costController.create));
eventScopedRouter.patch('/costs/:id', requireEventRole(...ROLE.MANAGE), validate(costIdParamSchema, 'params'), validate(updateCostSchema), asyncHandler(costController.update));
eventScopedRouter.delete('/costs/:id', requireEventRole(...ROLE.MANAGE), validate(costIdParamSchema, 'params'), asyncHandler(costController.remove));
