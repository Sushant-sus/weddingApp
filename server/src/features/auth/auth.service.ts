import { prisma } from '../../prisma/client.js';
import { AppError } from '../../utils/AppError.js';
import {
  comparePassword,
  compareOtp,
  generateOtp,
  hashOtp,
  hashPassword,
  hashToken,
  refreshTokenExpiryDate,
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} from '../../lib/security.js';
import { sendResetPasswordOtp, sendVerifyEmailOtp } from '../../lib/mailer.js';
import type { LoginDto, RegisterDto } from './auth.schema.js';

interface UserRow {
  id: string;
  full_name: string;
  email: string;
  password_hash: string;
  is_active: boolean;
  is_email_verified: boolean;
  role_name: string | null;
  role_id: string | null;
  permissions: string[];
}

// --- SP call helpers ---
async function getUserByEmail(email: string): Promise<UserRow> {
  const rows = await prisma.$queryRaw<[{ sp_auth_get_user_by_email: UserRow }]>`
    SELECT wedding.sp_auth_get_user_by_email(${email}::TEXT)
  `;
  return rows[0].sp_auth_get_user_by_email;
}

async function saveOtp(email: string, type: 'VERIFY_EMAIL' | 'RESET_PASSWORD') {
  const otp = generateOtp();
  const otpHash = await hashOtp(otp);
  await prisma.$queryRaw`SELECT wedding.sp_auth_save_otp(${email}::TEXT, ${otpHash}::TEXT, ${type}::TEXT)`;
  return otp;
}

async function consumeOtp(email: string, otp: string, type: 'VERIFY_EMAIL' | 'RESET_PASSWORD') {
  const rows = await prisma.$queryRaw<[{ sp_auth_get_active_otp: { id: string; code_hash: string } }]>`
    SELECT wedding.sp_auth_get_active_otp(${email}::TEXT, ${type}::TEXT)
  `;
  const active = rows[0].sp_auth_get_active_otp;
  const matches = await compareOtp(otp, active.code_hash);
  if (!matches) throw new AppError(400, 'INVALID_OTP', 'OTP is invalid or has expired');
  await prisma.$queryRaw`SELECT wedding.sp_auth_consume_otp(${active.id}::UUID, ${email}::TEXT, ${type}::TEXT)`;
}

function buildSession(user: UserRow) {
  const accessToken = signAccessToken({
    userId: user.id,
    email: user.email,
    role: user.role_name ?? 'VIEWER',
    permissions: user.permissions ?? [],
  });
  const refreshToken = signRefreshToken({ userId: user.id });
  return { accessToken, refreshToken };
}

export const authService = {
  register: async (data: RegisterDto) => {
    const passwordHash = await hashPassword(data.password);
    await prisma.$queryRaw`
      SELECT wedding.sp_auth_register(${data.fullName}::TEXT, ${data.email}::TEXT, ${passwordHash}::TEXT)
    `;
    const otp = await saveOtp(data.email, 'VERIFY_EMAIL');
    await sendVerifyEmailOtp(data.email, otp);
    return { message: 'OTP sent to your email. Please verify.' };
  },

  verifyEmail: async (email: string, otp: string) => {
    await consumeOtp(email, otp, 'VERIFY_EMAIL');
    return { message: 'Email verified successfully. You can now login.' };
  },

  login: async (data: LoginDto) => {
    let user: UserRow;
    try {
      user = await getUserByEmail(data.email);
    } catch {
      // Generic message to prevent user enumeration.
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    if (!user.is_active) throw new AppError(403, 'USER_INACTIVE', 'Your account is inactive');
    if (!user.is_email_verified)
      throw new AppError(403, 'EMAIL_NOT_VERIFIED', 'Please verify your email before logging in');

    const ok = await comparePassword(data.password, user.password_hash);
    if (!ok) throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');

    const { accessToken, refreshToken } = buildSession(user);
    await prisma.$queryRaw`
      SELECT wedding.sp_auth_save_refresh_token(
        ${user.id}::UUID, ${hashToken(refreshToken)}::TEXT, ${refreshTokenExpiryDate()}::TIMESTAMPTZ)
    `;
    await prisma.$queryRaw`SELECT wedding.sp_auth_update_last_login(${user.id}::UUID)`;

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        role: user.role_name,
        permissions: user.permissions ?? [],
      },
    };
  },

  refresh: async (token: string) => {
    let payload: { userId: string };
    try {
      payload = verifyRefreshToken(token);
    } catch {
      throw new AppError(401, 'INVALID_REFRESH_TOKEN', 'Token is invalid or expired');
    }
    const rows = await prisma.$queryRaw<
      [{ sp_auth_validate_refresh_token: { user_id: string; email: string; role_name: string; permissions: string[] } }]
    >`SELECT wedding.sp_auth_validate_refresh_token(${hashToken(token)}::TEXT)`;
    const v = rows[0].sp_auth_validate_refresh_token;
    if (v.user_id !== payload.userId)
      throw new AppError(401, 'INVALID_REFRESH_TOKEN', 'Token is invalid or expired');

    const accessToken = signAccessToken({
      userId: v.user_id,
      email: v.email,
      role: v.role_name ?? 'VIEWER',
      permissions: v.permissions ?? [],
    });
    return { accessToken };
  },

  logout: async (userId: string) => {
    await prisma.$queryRaw`SELECT wedding.sp_auth_revoke_refresh_token(${userId}::UUID)`;
    return { message: 'Logged out successfully' };
  },

  forgotPassword: async (email: string) => {
    // Don't reveal whether the email exists.
    try {
      await getUserByEmail(email);
      const otp = await saveOtp(email, 'RESET_PASSWORD');
      await sendResetPasswordOtp(email, otp);
    } catch {
      /* swallow — generic response below */
    }
    return { message: 'If that email exists, a password reset OTP has been sent.' };
  },

  resetPassword: async (email: string, otp: string, newPassword: string) => {
    await consumeOtp(email, otp, 'RESET_PASSWORD');
    const passwordHash = await hashPassword(newPassword);
    await prisma.$queryRaw`SELECT wedding.sp_auth_reset_password(${email}::TEXT, ${passwordHash}::TEXT)`;
    return { message: 'Password reset successfully' };
  },
};
