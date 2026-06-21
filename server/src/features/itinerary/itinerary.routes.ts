import { Router } from 'express';
import { itineraryController } from './itinerary.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import {
  createEventSchema,
  eventIdParamSchema,
  reorderSchema,
  updateEventSchema,
} from './itinerary.schema.js';

export const itineraryRouter = Router();

itineraryRouter.get('/', asyncHandler(itineraryController.list));
itineraryRouter.post('/', validate(createEventSchema), asyncHandler(itineraryController.create));
itineraryRouter.patch('/reorder', validate(reorderSchema), asyncHandler(itineraryController.reorder));
itineraryRouter.patch(
  '/:id',
  validate(eventIdParamSchema, 'params'),
  validate(updateEventSchema),
  asyncHandler(itineraryController.update),
);
itineraryRouter.delete(
  '/:id',
  validate(eventIdParamSchema, 'params'),
  asyncHandler(itineraryController.remove),
);
