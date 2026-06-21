import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { eventApi } from './event.api';
import type { CreateEventPayload, EventRole } from './event.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const eventKeys = {
  all: ['events'] as const,
  list: ['events', 'list'] as const,
  detail: (id: string) => ['events', 'detail', id] as const,
  members: (id: string) => ['events', 'members', id] as const,
  activity: (id: string) => ['events', 'activity', id] as const,
};

export function useMyEvents() {
  return useQuery({ queryKey: eventKeys.list, queryFn: eventApi.list });
}

export function useEvent(eventId: string | undefined) {
  return useQuery({
    queryKey: eventKeys.detail(eventId ?? 'none'),
    queryFn: () => eventApi.get(eventId!),
    enabled: !!eventId,
  });
}

export function useEventMembers(eventId: string | undefined) {
  return useQuery({
    queryKey: eventKeys.members(eventId ?? 'none'),
    queryFn: () => eventApi.members(eventId!),
    enabled: !!eventId,
  });
}

export function useEventActivity(eventId: string | undefined) {
  return useQuery({
    queryKey: eventKeys.activity(eventId ?? 'none'),
    queryFn: () => eventApi.activity(eventId!),
    enabled: !!eventId,
  });
}

export function useCreateEvent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateEventPayload) => eventApi.create(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: eventKeys.list });
      toast('Event created', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useInviteMember(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ email, role }: { email: string; role: EventRole }) =>
      eventApi.invite(eventId, email, role),
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: eventKeys.members(eventId) });
      toast(res.message ?? 'Invite sent', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useChangeMemberRole(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, role }: { userId: string; role: EventRole }) =>
      eventApi.changeRole(eventId, userId, role),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: eventKeys.members(eventId) });
      toast('Role updated', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useRemoveMember(eventId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => eventApi.removeMember(eventId, userId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: eventKeys.members(eventId) });
      toast('Member removed', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
