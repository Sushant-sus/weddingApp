import { Router } from 'express';
import { requestController } from './request.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { authenticate } from '../auth/auth.middleware.js';
import {
  createPitchSchema,
  pitchIdParamSchema,
  requestIdParamSchema,
} from './request.schema.js';

// Top-level request- and pitch-scoped marketplace routes. Mounted at /api/v1.
// Authorization is resolved per-request from the resource's event membership
// (see request.controller). Provider actions derive the provider from the caller.
export const requestRouter = Router();

requestRouter.use(authenticate);

requestRouter.get('/service-requests/:id', validate(requestIdParamSchema, 'params'), asyncHandler(requestController.getOne));
requestRouter.post('/service-requests/:id/cancel', validate(requestIdParamSchema, 'params'), asyncHandler(requestController.cancel));

requestRouter.get('/service-requests/:id/pitches', validate(requestIdParamSchema, 'params'), asyncHandler(requestController.listPitches));
requestRouter.post(
  '/service-requests/:id/pitches',
  validate(requestIdParamSchema, 'params'),
  validate(createPitchSchema),
  asyncHandler(requestController.createPitch),
);

requestRouter.post('/pitches/:id/book', validate(pitchIdParamSchema, 'params'), asyncHandler(requestController.bookPitch));
requestRouter.post('/pitches/:id/decline', validate(pitchIdParamSchema, 'params'), asyncHandler(requestController.declinePitch));
