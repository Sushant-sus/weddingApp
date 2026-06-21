// Tiny typed fetch wrapper around the backend's consistent JSON envelope.
const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:4000/api/v1';

interface ApiErrorShape {
  code: string;
  message: string;
  details?: unknown;
}

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

type SuccessEnvelope<T> = { success: true; data: T; meta?: Record<string, unknown> };
type ErrorEnvelope = { success: false; error: ApiErrorShape };

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(options.headers ?? {}) },
    ...options,
  });

  let body: SuccessEnvelope<T> | ErrorEnvelope;
  try {
    body = await res.json();
  } catch {
    throw new ApiError(res.status, 'PARSE_ERROR', 'Failed to parse server response');
  }

  if (!res.ok || body.success === false) {
    const err = (body as ErrorEnvelope).error ?? {
      code: 'UNKNOWN',
      message: 'Request failed',
    };
    throw new ApiError(res.status, err.code, err.message, err.details);
  }

  return (body as SuccessEnvelope<T>).data;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, data?: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(data ?? {}) }),
  patch: <T>(path: string, data?: unknown) =>
    request<T>(path, { method: 'PATCH', body: JSON.stringify(data ?? {}) }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
};
