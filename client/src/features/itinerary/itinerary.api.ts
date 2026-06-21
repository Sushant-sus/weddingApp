import { api } from '@/lib/api';
import type { EventPayload, ItineraryEvent } from './itinerary.types';

export const itineraryApi = {
  list: () => api.get<ItineraryEvent[]>('/itinerary'),
  create: (payload: EventPayload) => api.post<ItineraryEvent>('/itinerary', payload),
  update: (id: string, payload: Partial<EventPayload>) =>
    api.patch<ItineraryEvent>(`/itinerary/${id}`, payload),
  remove: (id: string) => api.delete<{ deleted: boolean; id: string }>(`/itinerary/${id}`),
  reorder: (order: { id: string; orderIndex: number }[]) =>
    api.patch<{ reordered: number }>('/itinerary/reorder', { order }),
};
