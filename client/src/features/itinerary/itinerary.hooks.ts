import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { itineraryApi } from './itinerary.api';
import type { EventPayload } from './itinerary.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const itineraryKeys = {
  all: ['itinerary'] as const,
  list: ['itinerary', 'list'] as const,
};

export function useItinerary() {
  return useQuery({ queryKey: itineraryKeys.list, queryFn: itineraryApi.list });
}

function invalidate(qc: ReturnType<typeof useQueryClient>) {
  qc.invalidateQueries({ queryKey: itineraryKeys.all });
}

export function useCreateEvent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: EventPayload) => itineraryApi.create(payload),
    onSuccess: () => {
      invalidate(qc);
      toast('Event added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useUpdateEvent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<EventPayload> }) =>
      itineraryApi.update(id, payload),
    onSuccess: () => {
      invalidate(qc);
      toast('Event updated', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteEvent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => itineraryApi.remove(id),
    onSuccess: () => {
      invalidate(qc);
      toast('Event deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useReorderEvents() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (order: { id: string; orderIndex: number }[]) => itineraryApi.reorder(order),
    onSuccess: () => invalidate(qc),
    onError: (e: ApiError) => {
      toast(e.message, 'error');
      invalidate(qc);
    },
  });
}
