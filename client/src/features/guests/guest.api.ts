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

// All guest data is scoped to a wedding event.
const base = (eventId: string) => `/events/${eventId}/guests`;

export const guestApi = {
  list: (eventId: string, filters: GuestFilters = {}) =>
    api.get<Guest[]>(`${base(eventId)}${buildQuery(filters)}`),
  summary: (eventId: string) => api.get<GuestSummary>(`${base(eventId)}/summary`),
  create: (eventId: string, payload: GuestCreatePayload) => api.post<Guest>(base(eventId), payload),
  update: (eventId: string, id: string, payload: Omit<GuestUpdatePayload, 'id'>) =>
    api.patch<Guest>(`${base(eventId)}/${id}`, payload),
  batchUpdate: (eventId: string, updates: GuestUpdatePayload[]) =>
    api.patch<{ updated: number }>(`${base(eventId)}/batch`, { updates }),
  remove: (eventId: string, id: string) =>
    api.delete<{ deleted: boolean; id: string }>(`${base(eventId)}/${id}`),
};
