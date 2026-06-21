import { api } from '@/lib/api';
import type {
  Guest,
  GuestCreatePayload,
  GuestFilters,
  GuestSummary,
  GuestUpdatePayload,
} from './guest.types';

function buildQuery(filters: GuestFilters): string {
  const params = new URLSearchParams();
  if (filters.familyType) params.set('familyType', filters.familyType);
  if (filters.rsvpStatus) params.set('rsvpStatus', filters.rsvpStatus);
  if (filters.side) params.set('side', filters.side);
  const qs = params.toString();
  return qs ? `?${qs}` : '';
}

export const guestApi = {
  list: (filters: GuestFilters = {}) => api.get<Guest[]>(`/guests${buildQuery(filters)}`),
  summary: () => api.get<GuestSummary>('/guests/summary'),
  create: (payload: GuestCreatePayload) => api.post<Guest>('/guests', payload),
  batchUpdate: (updates: GuestUpdatePayload[]) =>
    api.patch<{ updated: number }>('/guests/batch', { updates }),
  remove: (id: string) => api.delete<{ deleted: boolean; id: string }>(`/guests/${id}`),
};
