import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { guestApi } from './guest.api';
import type { GuestCreatePayload, GuestFilters, GuestUpdatePayload } from './guest.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const guestKeys = {
  all: (eventId: string) => ['guests', eventId] as const,
  list: (eventId: string, filters: GuestFilters) => ['guests', eventId, 'list', filters] as const,
  summary: (eventId: string) => ['guests', eventId, 'summary'] as const,
};

export function useGuests(eventId: string, filters: GuestFilters) {
  return useQuery({
    queryKey: guestKeys.list(eventId, filters),
    queryFn: () => guestApi.list(eventId, filters),
  });
}

export function useGuestSummary(eventId: string) {
  return useQuery({
    queryKey: guestKeys.summary(eventId),
    queryFn: () => guestApi.summary(eventId),
  });
}

function invalidate(qc: ReturnType<typeof useQueryClient>, eventId: string) {
  qc.invalidateQueries({ queryKey: ['guests', eventId] });
}

export function useCreateGuest(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: GuestCreatePayload) => guestApi.create(eventId, payload),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Guest added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useBatchUpdateGuests(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (updates: GuestUpdatePayload[]) => guestApi.batchUpdate(eventId, updates),
    onSuccess: (res) => {
      invalidate(qc, eventId);
      toast(`Saved ${res.updated} row${res.updated === 1 ? '' : 's'}`, 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteGuest(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => guestApi.remove(eventId, id),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Guest deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
