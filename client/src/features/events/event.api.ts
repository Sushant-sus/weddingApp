import { api } from '@/lib/api';
import type {
  ActivityEntry,
  CreateEventPayload,
  EventMember,
  EventRole,
  WeddingEvent,
} from './event.types';

export const eventApi = {
  list: () => api.get<WeddingEvent[]>('/events'),
  get: (eventId: string) => api.get<WeddingEvent>(`/events/${eventId}`),
  create: (payload: CreateEventPayload) => api.post<WeddingEvent>('/events', payload),
  update: (eventId: string, payload: Partial<CreateEventPayload>) =>
    api.patch<WeddingEvent>(`/events/${eventId}`, payload),
  remove: (eventId: string) => api.delete<{ deleted: boolean }>(`/events/${eventId}`),

  members: (eventId: string) => api.get<EventMember[]>(`/events/${eventId}/members`),
  invite: (eventId: string, email: string, eventRole: EventRole) =>
    api.post<{ message: string }>(`/events/${eventId}/members/invite`, { email, eventRole }),
  changeRole: (eventId: string, userId: string, eventRole: EventRole) =>
    api.patch(`/events/${eventId}/members/${userId}/role`, { eventRole }),
  removeMember: (eventId: string, userId: string) =>
    api.delete(`/events/${eventId}/members/${userId}`),
  transferOwnership: (eventId: string, newOwnerId: string) =>
    api.post(`/events/${eventId}/transfer-ownership`, { newOwnerId }),

  acceptInvite: (token: string) => api.post<WeddingEvent>('/events/invite/accept', { token }),
  declineInvite: (token: string) => api.post('/events/invite/decline', { token }),

  activity: (eventId: string) => api.get<ActivityEntry[]>(`/events/${eventId}/activity`),
};
