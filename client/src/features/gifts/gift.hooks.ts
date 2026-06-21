import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { giftApi } from './gift.api';
import type { GiftCreatePayload } from './gift.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const giftKeys = {
  all: ['gifts'] as const,
  list: ['gifts', 'list'] as const,
  summary: ['gifts', 'summary'] as const,
  forGuest: (guestId: string) => ['gifts', 'guest', guestId] as const,
};

export function useGifts() {
  return useQuery({ queryKey: giftKeys.list, queryFn: giftApi.list });
}

export function useGiftSummary() {
  return useQuery({ queryKey: giftKeys.summary, queryFn: giftApi.summary });
}

export function useGuestGifts(guestId: string | null) {
  return useQuery({
    queryKey: giftKeys.forGuest(guestId ?? 'none'),
    queryFn: () => giftApi.listForGuest(guestId!),
    enabled: !!guestId,
  });
}

function invalidate(qc: ReturnType<typeof useQueryClient>) {
  qc.invalidateQueries({ queryKey: giftKeys.all });
  qc.invalidateQueries({ queryKey: ['dashboard'] });
}

export function useCreateGift(guestId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: GiftCreatePayload) => giftApi.create(guestId!, payload),
    onSuccess: () => {
      invalidate(qc);
      toast('Gift recorded', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteGift() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => giftApi.remove(id),
    onSuccess: () => {
      invalidate(qc);
      toast('Gift removed', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
