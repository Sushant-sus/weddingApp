import { Router } from 'express';
import { adminController } from './admin.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { authenticate, requireRole } from '../auth/auth.middleware.js';
import { assignRoleSchema, userFiltersSchema, userIdParamSchema } from './admin.schema.js';

export const adminRouter = Router();

// Everything here requires an authenticated SUPERADMIN or ADMIN.
adminRouter.use(authenticate, requireRole('SUPERADMIN', 'ADMIN'));

adminRouter.get('/users', validate(userFiltersSchema, 'query'), asyncHandler(adminController.listUsers));
adminRouter.get('/roles', asyncHandler(adminController.listRoles));
adminRouter.patch(
  '/users/:id/role',
  validate(userIdParamSchema, 'params'),
  validate(assignRoleSchema),
  asyncHandler(adminController.assignRole),
);
adminRouter.patch(
  '/users/:id/status',
  validate(userIdParamSchema, 'params'),
  asyncHandler(adminController.toggleStatus),
);
