import { Router } from 'express';
import { providerController } from './provider.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { authenticate } from '../auth/auth.middleware.js';
import {
  addPortfolioSchema,
  addReviewSchema,
  providerIdParamSchema,
  providerListQuerySchema,
  upsertProviderSchema,
} from './provider.schema.js';

// Marketplace provider directory + the caller's own provider profile.
// Mounted at /api/v1 so it owns /service-categories and /providers/*.
export const providerRouter = Router();

providerRouter.use(authenticate);

providerRouter.get('/service-categories', asyncHandler(providerController.categories));

// Caller's own provider profile + matched dashboard feed (before /:id).
providerRouter.get('/providers/me', asyncHandler(providerController.me));
providerRouter.put('/providers/me', validate(upsertProviderSchema), asyncHandler(providerController.upsertMe));
providerRouter.get('/providers/me/dashboard', asyncHandler(providerController.dashboard));

providerRouter.get('/providers', validate(providerListQuerySchema, 'query'), asyncHandler(providerController.list));
providerRouter.get('/providers/:id', validate(providerIdParamSchema, 'params'), asyncHandler(providerController.getOne));
providerRouter.post(
  '/providers/:id/portfolio',
  validate(providerIdParamSchema, 'params'),
  validate(addPortfolioSchema),
  asyncHandler(providerController.addPortfolio),
);
providerRouter.post(
  '/providers/:id/reviews',
  validate(providerIdParamSchema, 'params'),
  validate(addReviewSchema),
  asyncHandler(providerController.addReview),
);
