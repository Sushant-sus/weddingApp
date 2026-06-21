import { api } from '@/lib/api';
import type { EventPayload, ItineraryEvent } from './itinerary.types';

const base = (eventId: string) => `/events/${eventId}/itinerary`;

export const itineraryApi = {
  list: (eventId: string) => api.get<ItineraryEvent[]>(base(eventId)),
  create: (eventId: string, payload: EventPayload) =>
    api.post<ItineraryEvent>(base(eventId), payload),
  update: (eventId: string, id: string, payload: Partial<EventPayload>) =>
    api.patch<ItineraryEvent>(`${base(eventId)}/${id}`, payload),
  remove: (eventId: string, id: string) =>
    api.delete<{ deleted: boolean; id: string }>(`${base(eventId)}/${id}`),
  reorder: (eventId: string, order: { id: string; orderIndex: number }[]) =>
    api.patch<{ reordered: number }>(`${base(eventId)}/reorder`, { order }),
};
