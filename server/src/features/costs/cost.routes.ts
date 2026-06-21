import { Router } from 'express';
import { costController } from './cost.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import {
  costFiltersSchema,
  costIdParamSchema,
  createCostSchema,
  updateCostSchema,
} from './cost.schema.js';

export const costRouter = Router();

costRouter.get('/summary', asyncHandler(costController.summary));
costRouter.get('/', validate(costFiltersSchema, 'query'), asyncHandler(costController.list));
costRouter.post('/', validate(createCostSchema), asyncHandler(costController.create));
costRouter.patch(
  '/:id',
  validate(costIdParamSchema, 'params'),
  validate(updateCostSchema),
  asyncHandler(costController.update),
);
costRouter.delete(
  '/:id',
  validate(costIdParamSchema, 'params'),
  asyncHandler(costController.remove),
);
