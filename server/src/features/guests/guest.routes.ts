import { Router } from 'express';
import { guestController } from './guest.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import {
  batchUpdateSchema,
  createGuestSchema,
  guestFiltersSchema,
  idParamSchema,
  updateGuestSchema,
} from './guest.schema.js';

export const guestRouter = Router();

// Static/specific routes BEFORE the dynamic :id routes.
guestRouter.get('/summary', asyncHandler(guestController.summary));
guestRouter.get('/', validate(guestFiltersSchema, 'query'), asyncHandler(guestController.list));
guestRouter.post('/', validate(createGuestSchema), asyncHandler(guestController.create));
guestRouter.patch('/batch', validate(batchUpdateSchema), asyncHandler(guestController.batchUpdate));

guestRouter.get('/:id', validate(idParamSchema, 'params'), asyncHandler(guestController.getOne));
guestRouter.patch(
  '/:id',
  validate(idParamSchema, 'params'),
  validate(updateGuestSchema),
  asyncHandler(guestController.update),
);
guestRouter.delete('/:id', validate(idParamSchema, 'params'), asyncHandler(guestController.remove));
