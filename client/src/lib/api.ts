import axios, { AxiosError, type InternalAxiosRequestConfig } from 'axios';
import { tokenStore } from './tokenStore';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:4000/api/v1';

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

const client = axios.create({ baseURL: BASE_URL });

// Attach the access token to every request.
client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = tokenStore.getAccessToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Called by AuthContext to fully clear session on unrecoverable 401.
let onSessionExpired: (() => void) | null = null;
export const setSessionExpiredHandler = (fn: () => void) => {
  onSessionExpired = fn;
};

let refreshing: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = tokenStore.getRefreshToken();
  if (!refreshToken) return null;
  try {
    const res = await axios.post(`${BASE_URL}/auth/refresh-token`, { refreshToken });
    const newToken = res.data?.data?.accessToken as string | undefined;
    if (newToken) {
      tokenStore.setAccessToken(newToken);
      return newToken;
    }
    return null;
  } catch {
    return null;
  }
}

// On 401, try a single refresh + retry; otherwise surface the error / log out.
client.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const original = error.config as InternalAxiosRequestConfig & { _retry?: boolean };
    const status = error.response?.status;
    // Allow refresh on protected endpoints (incl. /auth/me), but never on the
    // auth flows themselves (login/refresh/etc.) to avoid loops.
    const url = original?.url ?? '';
    const noRefresh = url.includes('/auth/') && !url.includes('/auth/me');

    if (status === 401 && original && !original._retry && !noRefresh) {
      original._retry = true;
      if (!refreshing) refreshing = refreshAccessToken().finally(() => (refreshing = null));
      const newToken = await refreshing;
      if (newToken) {
        original.headers.Authorization = `Bearer ${newToken}`;
        return client(original);
      }
      onSessionExpired?.();
    }

    const body = error.response?.data as { error?: { code: string; message: string; details?: unknown } } | undefined;
    const err = body?.error;
    return Promise.reject(
      new ApiError(
        status ?? 0,
        err?.code ?? 'NETWORK_ERROR',
        err?.message ?? error.message ?? 'Request failed',
        err?.details,
      ),
    );
  },
);

// Unwrap the { success, data } envelope.
export const api = {
  get: async <T>(path: string) => (await client.get(path)).data.data as T,
  post: async <T>(path: string, data?: unknown) => (await client.post(path, data ?? {})).data.data as T,
  patch: async <T>(path: string, data?: unknown) => (await client.patch(path, data ?? {})).data.data as T,
  delete: async <T>(path: string) => (await client.delete(path)).data.data as T,
};
