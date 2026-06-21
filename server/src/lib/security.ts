import bcrypt from 'bcryptjs';
import jwt, { type SignOptions } from 'jsonwebtoken';
import { createHash, randomInt } from 'node:crypto';
import { env } from '../config/env.js';

const BCRYPT_ROUNDS = 12;

// ---- Passwords & OTP (bcrypt, salted) ----
export const hashPassword = (plain: string) => bcrypt.hash(plain, BCRYPT_ROUNDS);
export const comparePassword = (plain: string, hash: string) => bcrypt.compare(plain, hash);

export const generateOtp = () => String(randomInt(100000, 1000000)); // 6 digits
export const hashOtp = (otp: string) => bcrypt.hash(otp, BCRYPT_ROUNDS);
export const compareOtp = (otp: string, hash: string) => bcrypt.compare(otp, hash);

// ---- Refresh token hashing (deterministic, for DB lookup) ----
export const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

// ---- JWT ----
export interface AccessTokenPayload {
  userId: string;
  email: string;
  role: string;
  permissions: string[];
}

export function signAccessToken(payload: AccessTokenPayload): string {
  const opts: SignOptions = { expiresIn: env.accessTokenExpires as SignOptions['expiresIn'] };
  return jwt.sign(payload, env.accessTokenSecret, opts);
}

export function signRefreshToken(payload: { userId: string }): string {
  const opts: SignOptions = { expiresIn: env.refreshTokenExpires as SignOptions['expiresIn'] };
  return jwt.sign(payload, env.refreshTokenSecret, opts);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.accessTokenSecret) as AccessTokenPayload;
}

export function verifyRefreshToken(token: string): { userId: string } {
  return jwt.verify(token, env.refreshTokenSecret) as { userId: string };
}

// Convert a token-expiry string (e.g. "7d") into an absolute Date for the DB.
export function refreshTokenExpiryDate(): Date {
  const m = /^(\d+)([smhd])$/.exec(env.refreshTokenExpires);
  const ms: Record<string, number> = { s: 1e3, m: 6e4, h: 36e5, d: 864e5 };
  const extra = m ? Number(m[1]) * ms[m[2]] : 7 * 864e5;
  return new Date(Date.now() + extra);
}
