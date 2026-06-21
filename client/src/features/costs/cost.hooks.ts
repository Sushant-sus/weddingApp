import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { costApi } from './cost.api';
import type { CostCreatePayload, CostUpdatePayload } from './cost.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const costKeys = {
  all: (eventId: string) => ['costs', eventId] as const,
  list: (eventId: string) => ['costs', eventId, 'list'] as const,
  summary: (eventId: string) => ['costs', eventId, 'summary'] as const,
};

export function useCosts(eventId: string) {
  return useQuery({ queryKey: costKeys.list(eventId), queryFn: () => costApi.list(eventId) });
}

export function useCostSummary(eventId: string, enabled = true) {
  return useQuery({
    queryKey: costKeys.summary(eventId),
    queryFn: () => costApi.summary(eventId),
    enabled: enabled && !!eventId,
  });
}

function invalidate(qc: ReturnType<typeof useQueryClient>, eventId: string) {
  qc.invalidateQueries({ queryKey: ['costs', eventId] });
}

export function useCreateCost(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CostCreatePayload) => costApi.create(eventId, payload),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Cost item added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useUpdateCost(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: CostUpdatePayload }) =>
      costApi.update(eventId, id, payload),
    onSuccess: () => invalidate(qc, eventId),
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteCost(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => costApi.remove(eventId, id),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Cost item deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
