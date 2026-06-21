import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { giftApi } from './gift.api';
import type { GiftCreatePayload } from './gift.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const giftKeys = {
  all: (eventId: string) => ['gifts', eventId] as const,
  list: (eventId: string) => ['gifts', eventId, 'list'] as const,
  summary: (eventId: string) => ['gifts', eventId, 'summary'] as const,
  forGuest: (eventId: string, guestId: string) => ['gifts', eventId, 'guest', guestId] as const,
};

export function useGifts(eventId: string) {
  return useQuery({ queryKey: giftKeys.list(eventId), queryFn: () => giftApi.list(eventId) });
}

export function useGiftSummary(eventId: string) {
  return useQuery({ queryKey: giftKeys.summary(eventId), queryFn: () => giftApi.summary(eventId) });
}

export function useGuestGifts(eventId: string, guestId: string | null) {
  return useQuery({
    queryKey: giftKeys.forGuest(eventId, guestId ?? 'none'),
    queryFn: () => giftApi.listForGuest(eventId, guestId!),
    enabled: !!guestId,
  });
}

function invalidate(qc: ReturnType<typeof useQueryClient>, eventId: string) {
  qc.invalidateQueries({ queryKey: ['gifts', eventId] });
}

export function useCreateGift(eventId: string, guestId: string | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: GiftCreatePayload) => giftApi.create(eventId, guestId!, payload),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Gift recorded', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useDeleteGift(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => giftApi.remove(eventId, id),
    onSuccess: () => {
      invalidate(qc, eventId);
      toast('Gift removed', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
