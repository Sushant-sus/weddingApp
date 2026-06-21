import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { adminApi } from './admin.api';
import type { UserFilters } from './admin.types';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export const adminKeys = {
  users: (f: UserFilters) => ['admin', 'users', f] as const,
  roles: ['admin', 'roles'] as const,
};

export function useAdminUsers(filters: UserFilters) {
  return useQuery({ queryKey: adminKeys.users(filters), queryFn: () => adminApi.listUsers(filters) });
}

export function useRoles() {
  return useQuery({ queryKey: adminKeys.roles, queryFn: adminApi.listRoles });
}

export function useAssignRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, roleId }: { userId: string; roleId: string }) =>
      adminApi.assignRole(userId, roleId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'users'] });
      toast('Role updated', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}

export function useToggleStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => adminApi.toggleStatus(userId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'users'] });
      toast('Status updated', 'success');
    },
    onError: (e: ApiError) => toast(e.message, 'error'),
  });
}
