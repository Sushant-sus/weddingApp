import { api } from '@/lib/api';
import type { AdminUser, Role, UserFilters } from './admin.types';

function qs(filters: UserFilters) {
  const p = new URLSearchParams();
  if (filters.role) p.set('role', filters.role);
  if (filters.isActive !== undefined) p.set('isActive', String(filters.isActive));
  const s = p.toString();
  return s ? `?${s}` : '';
}

export const adminApi = {
  listUsers: (filters: UserFilters = {}) => api.get<AdminUser[]>(`/admin/users${qs(filters)}`),
  listRoles: () => api.get<Role[]>('/admin/roles'),
  assignRole: (userId: string, roleId: string) =>
    api.patch<{ role_assigned: boolean }>(`/admin/users/${userId}/role`, { roleId }),
  toggleStatus: (userId: string) =>
    api.patch<{ is_active: boolean }>(`/admin/users/${userId}/status`),
};
