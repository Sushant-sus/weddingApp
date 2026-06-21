import type { Request, Response } from 'express';
import { authService } from './auth.service.js';
import { sendSuccess } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import { verifyRefreshToken } from '../../lib/security.js';
import type {
  ForgotPasswordDto,
  LoginDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyEmailDto,
} from './auth.schema.js';

// Refresh token comes from the request body (frontend stores it in localStorage).
// This is more reliable than cookies for a split frontend/backend host setup.
function getRefreshToken(req: Request): string | undefined {
  return (req.body?.refreshToken as string | undefined) ?? undefined;
}

export const authController = {
  register: async (req: Request, res: Response) => {
    sendSuccess(res, await authService.register(req.body as RegisterDto), 201);
  },

  verifyEmail: async (req: Request, res: Response) => {
    const { email, otp } = req.body as VerifyEmailDto;
    sendSuccess(res, await authService.verifyEmail(email, otp));
  },

  login: async (req: Request, res: Response) => {
    sendSuccess(res, await authService.login(req.body as LoginDto));
  },

  refresh: async (req: Request, res: Response) => {
    const token = getRefreshToken(req);
    if (!token) throw new AppError(401, 'INVALID_REFRESH_TOKEN', 'Refresh token is required');
    sendSuccess(res, await authService.refresh(token));
  },

  logout: async (req: Request, res: Response) => {
    // Resolve the user id from the access token if present, else the refresh token.
    let userId = req.user?.userId;
    const token = getRefreshToken(req);
    if (!userId && token) {
      try {
        userId = verifyRefreshToken(token).userId;
      } catch {
        /* ignore — logout is idempotent */
      }
    }
    if (userId) return sendSuccess(res, await authService.logout(userId));
    sendSuccess(res, { message: 'Logged out successfully' });
  },

  forgotPassword: async (req: Request, res: Response) => {
    const { email } = req.body as ForgotPasswordDto;
    sendSuccess(res, await authService.forgotPassword(email));
  },

  resetPassword: async (req: Request, res: Response) => {
    const { email, otp, newPassword } = req.body as ResetPasswordDto;
    sendSuccess(res, await authService.resetPassword(email, otp, newPassword));
  },

  me: async (req: Request, res: Response) => {
    sendSuccess(res, {
      id: req.user!.userId,
      email: req.user!.email,
      role: req.user!.role,
      permissions: req.user!.permissions,
    });
  },
};
