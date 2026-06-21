import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { itineraryApi } from './itinerary.api';
import type { EventPayload } from './itinerary.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const itineraryKeys = {
  all: (eventId: string) => ['itinerary', eventId] as const,
  list: (eventId: string) => ['itinerary', eventId, 'list'] as const,
};

export function useItinerary(eventId: string) {
  return useQuery({ queryKey: itineraryKeys.list(eventId), queryFn: () => itineraryApi.list(eventId) });
}

function invalidate(qc: ReturnType<typeof useQueryClient>, eventId: string) {
  qc.invalidateQueries({ queryKey: ['itinerary', eventId] });
}

export function useCreateEvent(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: EventPayload) => itineraryApi.create(eventId, payload),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Event added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useUpdateEvent(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<EventPayload> }) =>
      itineraryApi.update(eventId, id, payload),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Event updated', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteEvent(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => itineraryApi.remove(eventId, id),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Event deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useReorderEvents(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (order: { id: string; orderIndex: number }[]) => itineraryApi.reorder(eventId, order),
    onSuccess: () => invalidate(qc, eventId),
    onError: (e: ApiError) => {
      toast(e.message, 'error');
      invalidate(qc, eventId);
    },
  });
}
