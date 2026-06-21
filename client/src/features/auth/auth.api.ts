import { api } from '@/lib/api';
import type { AuthUser, LoginResponse, RegisterPayload } from './auth.types';

export const authApi = {
  register: (payload: RegisterPayload) => api.post<{ message: string }>('/auth/register', payload),
  verifyEmail: (email: string, otp: string) =>
    api.post<{ message: string }>('/auth/verify-email', { email, otp }),
  login: (email: string, password: string) =>
    api.post<LoginResponse>('/auth/login', { email, password }),
  logout: (refreshToken: string | null) => api.post('/auth/logout', { refreshToken }),
  me: () => api.get<AuthUser>('/auth/me'),
  forgotPassword: (email: string) =>
    api.post<{ message: string }>('/auth/forgot-password', { email }),
  resetPassword: (email: string, otp: string, newPassword: string) =>
    api.post<{ message: string }>('/auth/reset-password', { email, otp, newPassword }),
};
