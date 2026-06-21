import { api } from '@/lib/api';
import type { Gift, GiftCreatePayload, GiftSummary } from './gift.types';

const base = (eventId: string) => `/events/${eventId}`;

export const giftApi = {
  list: (eventId: string) => api.get<Gift[]>(`${base(eventId)}/gifts`),
  summary: (eventId: string) => api.get<GiftSummary>(`${base(eventId)}/gifts/summary`),
  listForGuest: (eventId: string, guestId: string) =>
    api.get<Gift[]>(`${base(eventId)}/guests/${guestId}/gifts`),
  create: (eventId: string, guestId: string, payload: GiftCreatePayload) =>
    api.post<Gift>(`${base(eventId)}/guests/${guestId}/gifts`, payload),
  remove: (eventId: string, id: string) =>
    api.delete<{ deleted: boolean; id: string }>(`${base(eventId)}/gifts/${id}`),
};
