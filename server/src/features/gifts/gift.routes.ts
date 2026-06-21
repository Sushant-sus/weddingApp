import { Router } from 'express';
import { giftController } from './gift.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import {
  createGiftSchema,
  giftIdParamSchema,
  guestIdParamSchema,
  updateGiftSchema,
} from './gift.schema.js';

// Mounted at /api/v1 so it can own both the /gifts and /guests/:id/gifts paths.
export const giftRouter = Router();

giftRouter.get('/gifts/summary', asyncHandler(giftController.summary));
giftRouter.get('/gifts', asyncHandler(giftController.list));
giftRouter.patch(
  '/gifts/:id',
  validate(giftIdParamSchema, 'params'),
  validate(updateGiftSchema),
  asyncHandler(giftController.update),
);
giftRouter.delete(
  '/gifts/:id',
  validate(giftIdParamSchema, 'params'),
  asyncHandler(giftController.remove),
);

giftRouter.get(
  '/guests/:guestId/gifts',
  validate(guestIdParamSchema, 'params'),
  asyncHandler(giftController.listForGuest),
);
giftRouter.post(
  '/guests/:guestId/gifts',
  validate(guestIdParamSchema, 'params'),
  validate(createGiftSchema),
  asyncHandler(giftController.create),
);
