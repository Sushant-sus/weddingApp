import { api } from '@/lib/api';
import type { CostCreatePayload, CostItem, CostSummary, CostUpdatePayload } from './cost.types';

export const costApi = {
  list: () => api.get<CostItem[]>('/costs'),
  summary: () => api.get<CostSummary>('/costs/summary'),
  create: (payload: CostCreatePayload) => api.post<CostItem>('/costs', payload),
  update: (id: string, payload: CostUpdatePayload) => api.patch<CostItem>(`/costs/${id}`, payload),
  remove: (id: string) => api.delete<{ deleted: boolean; id: string }>(`/costs/${id}`),
};
