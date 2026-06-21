import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authController } from './auth.controller.js';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { authenticate } from './auth.middleware.js';
import {
  forgotPasswordSchema,
  loginSchema,
  registerSchema,
  resetPasswordSchema,
  verifyEmailSchema,
} from './auth.schema.js';

const limiter = (windowMs: number, max: number, message: string) =>
  rateLimit({
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: { code: 'RATE_LIMITED', message } },
  });

const MIN = 60 * 1000;

export const authRouter = Router();

authRouter.post(
  '/register',
  limiter(60 * MIN, 3, 'Too many registration attempts. Try again later.'),
  validate(registerSchema),
  asyncHandler(authController.register),
);

authRouter.post(
  '/verify-email',
  limiter(10 * MIN, 5, 'Too many verification attempts. Try again later.'),
  validate(verifyEmailSchema),
  asyncHandler(authController.verifyEmail),
);

authRouter.post(
  '/login',
  limiter(15 * MIN, 5, 'Too many login attempts. Try again later.'),
  validate(loginSchema),
  asyncHandler(authController.login),
);

authRouter.post('/refresh-token', asyncHandler(authController.refresh));
authRouter.post('/logout', asyncHandler(authController.logout));
authRouter.get('/me', authenticate, asyncHandler(authController.me));

authRouter.post(
  '/forgot-password',
  limiter(60 * MIN, 3, 'Too many requests. Try again later.'),
  validate(forgotPasswordSchema),
  asyncHandler(authController.forgotPassword),
);

authRouter.post(
  '/reset-password',
  limiter(60 * MIN, 5, 'Too many requests. Try again later.'),
  validate(resetPasswordSchema),
  asyncHandler(authController.resetPassword),
);
