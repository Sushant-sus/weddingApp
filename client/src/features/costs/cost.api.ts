import { api } from '@/lib/api';
import type { CostCreatePayload, CostItem, CostSummary, CostUpdatePayload } from './cost.types';

const base = (eventId: string) => `/events/${eventId}/costs`;

export const costApi = {
  list: (eventId: string) => api.get<CostItem[]>(base(eventId)),
  summary: (eventId: string) => api.get<CostSummary>(`${base(eventId)}/summary`),
  create: (eventId: string, payload: CostCreatePayload) => api.post<CostItem>(base(eventId), payload),
  update: (eventId: string, id: string, payload: CostUpdatePayload) =>
    api.patch<CostItem>(`${base(eventId)}/${id}`, payload),
  remove: (eventId: string, id: string) =>
    api.delete<{ deleted: boolean; id: string }>(`${base(eventId)}/${id}`),
};
