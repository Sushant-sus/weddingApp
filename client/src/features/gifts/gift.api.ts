import { api } from '@/lib/api';
import type { Gift, GiftCreatePayload, GiftSummary } from './gift.types';

export const giftApi = {
  list: () => api.get<Gift[]>('/gifts'),
  summary: () => api.get<GiftSummary>('/gifts/summary'),
  listForGuest: (guestId: string) => api.get<Gift[]>(`/guests/${guestId}/gifts`),
  create: (guestId: string, payload: GiftCreatePayload) =>
    api.post<Gift>(`/guests/${guestId}/gifts`, payload),
  remove: (id: string) => api.delete<{ deleted: boolean; id: string }>(`/gifts/${id}`),
};
