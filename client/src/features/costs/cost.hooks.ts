import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { costApi } from './cost.api';
import type { CostCreatePayload, CostUpdatePayload } from './cost.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const costKeys = {
  all: ['costs'] as const,
  list: ['costs', 'list'] as const,
  summary: ['costs', 'summary'] as const,
};

export function useCosts() {
  return useQuery({ queryKey: costKeys.list, queryFn: costApi.list });
}

export function useCostSummary() {
  return useQuery({ queryKey: costKeys.summary, queryFn: costApi.summary });
}

function invalidate(qc: ReturnType<typeof useQueryClient>) {
  qc.invalidateQueries({ queryKey: costKeys.all });
  qc.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateCost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CostCreatePayload) => costApi.create(payload),
    onSuccess: () => {
      invalidate(qc);
      toast('Cost item added', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useUpdateCost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: CostUpdatePayload }) =>
      costApi.update(id, payload),
    onSuccess: () => invalidate(qc),
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteCost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => costApi.remove(id),
    onSuccess: () => {
      invalidate(qc);
      toast('Cost item deleted', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
