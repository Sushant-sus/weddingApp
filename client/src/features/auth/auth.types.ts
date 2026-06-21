export interface AuthUser {
  id: string;
  fullName?: string;
  email: string;
  role: string;
  permissions: string[];
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

export interface RegisterPayload {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
}
