import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { guestApi } from './guest.api';
import type { GuestCreatePayload, GuestFilters, GuestUpdatePayload } from './guest.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const guestKeys = {
  all: ['guests'] as const,
  list: (filters: GuestFilters) => ['guests', 'list', filters] as const,
  summary: ['guests', 'summary'] as const,
};

export function useGuests(filters: GuestFilters) {
  return useQuery({
    queryKey: guestKeys.list(filters),
    queryFn: () => guestApi.list(filters),
  });
}

export function useGuestSummary() {
  return useQuery({ queryKey: guestKeys.summary, queryFn: guestApi.summary });
}

function invalidate(qc: ReturnType<typeof useQueryClient>) {
  qc.invalidateQueries({ queryKey: guestKeys.all });
  qc.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateGuest() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: GuestCreatePayload) => guestApi.create(payload),
    onSuccess: () => {
      invalidate(qc);
      toast('Guest added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useBatchUpdateGuests() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (updates: GuestUpdatePayload[]) => guestApi.batchUpdate(updates),
    onSuccess: (res) => {
      invalidate(qc);
      toast(`Saved ${res.updated} row${res.updated === 1 ? '' : 's'}`, 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteGuest() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => guestApi.remove(id),
    onSuccess: () => {
      invalidate(qc);
      toast('Guest deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
