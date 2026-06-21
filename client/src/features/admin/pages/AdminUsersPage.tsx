import { useMemo, useState } from 'react';
import { CheckCircle2, XCircle, ShieldCheck } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { cn, formatDate } from '@/lib/utils';
import { useAdminUsers, useAssignRole, useRoles, useToggleStatus } from '../admin.hooks';
import type { AdminUser, UserFilters } from '../admin.types';

const roleBadge: Record<string, string> = {
  SUPERADMIN: 'bg-red-100 text-red-800',
  ADMIN: 'bg-orange-100 text-orange-800',
  EDITOR: 'bg-sky-100 text-sky-800',
  VIEWER: 'bg-slate-100 text-slate-700',
};

export function AdminUsersPage() {
  const [filters, setFilters] = useState<UserFilters>({});
  const [search, setSearch] = useState('');
  const [assignFor, setAssignFor] = useState<AdminUser | null>(null);

  const { data: users = [], isLoading } = useAdminUsers(filters);
  const { data: roles = [] } = useRoles();
  const assignRole = useAssignRole();
  const toggleStatus = useToggleStatus();

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) => u.full_name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q),
    );
  }, [users, search]);

  return (
    <div>
      <PageHeader title="User Management" description="Manage users, roles and access." />

      <div className="mb-4 flex flex-wrap items-end gap-3">
        <div className="w-48">
          <label className="mb-1 block text-xs text-muted-foreground">Search</label>
          <Input placeholder="Name or email" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <div className="w-40">
          <label className="mb-1 block text-xs text-muted-foreground">Role</label>
          <Select
            placeholder="All roles"
            value={filters.role ?? ''}
            options={roles.map((r) => ({ label: r.name, value: r.name }))}
            onChange={(e) => setFilters((f) => ({ ...f, role: e.target.value || undefined }))}
          />
        </div>
        <div className="w-40">
          <label className="mb-1 block text-xs text-muted-foreground">Status</label>
          <Select
            placeholder="All"
            value={filters.isActive === undefined ? '' : String(filters.isActive)}
            options={[
              { label: 'Active', value: 'true' },
              { label: 'Inactive', value: 'false' },
            ]}
            onChange={(e) =>
              setFilters((f) => ({
                ...f,
                isActive: e.target.value === '' ? undefined : e.target.value === 'true',
              }))
            }
          />
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-secondary text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 text-left">Name</th>
                  <th className="px-4 py-3 text-left">Email</th>
                  <th className="px-4 py-3 text-left">Role</th>
                  <th className="px-4 py-3 text-left">Status</th>
                  <th className="px-4 py-3 text-left">Verified</th>
                  <th className="px-4 py-3 text-left">Last Login</th>
                  <th className="px-4 py-3 text-left">Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading && (
                  <tr><td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">Loading…</td></tr>
                )}
                {!isLoading && filtered.length === 0 && (
                  <tr><td colSpan={7} className="px-4 py-6 text-center text-muted-foreground">No users found.</td></tr>
                )}
                {filtered.map((u) => (
                  <tr key={u.id} className="border-b last:border-0 hover:bg-secondary/40">
                    <td className="px-4 py-2 font-medium">{u.full_name}</td>
                    <td className="px-4 py-2 text-muted-foreground">{u.email}</td>
                    <td className="px-4 py-2">
                      <span className={cn('rounded-full px-2.5 py-0.5 text-xs font-medium', roleBadge[u.role_name ?? ''] ?? 'bg-slate-100 text-slate-700')}>
                        {u.role_name ?? '—'}
                      </span>
                    </td>
                    <td className="px-4 py-2">
                      <button
                        onClick={() => toggleStatus.mutate(u.id)}
                        className={cn(
                          'inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium',
                          u.is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800',
                        )}
                        title="Toggle status"
                      >
                        <span className={cn('h-1.5 w-1.5 rounded-full', u.is_active ? 'bg-emerald-600' : 'bg-red-600')} />
                        {u.is_active ? 'Active' : 'Inactive'}
                      </button>
                    </td>
                    <td className="px-4 py-2">
                      {u.is_email_verified ? (
                        <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                      ) : (
                        <XCircle className="h-4 w-4 text-red-500" />
                      )}
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">
                      {u.last_login_at ? formatDate(u.last_login_at) : 'Never'}
                    </td>
                    <td className="px-4 py-2">
                      <Button variant="outline" size="sm" onClick={() => setAssignFor(u)}>
                        Assign Role
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Dialog open={!!assignFor} onOpenChange={(o) => !o && setAssignFor(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ShieldCheck className="h-5 w-5 text-primary" /> Assign Role
            </DialogTitle>
            <DialogDescription>
              Set the global role for <strong>{assignFor?.full_name}</strong>.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2">
            {roles.map((r) => (
              <button
                key={r.id}
                onClick={async () => {
                  if (assignFor) await assignRole.mutateAsync({ userId: assignFor.id, roleId: r.id });
                  setAssignFor(null);
                }}
                className={cn(
                  'flex w-full items-center justify-between rounded-md border p-3 text-left hover:border-primary',
                  assignFor?.role_id === r.id && 'border-primary bg-primary/5',
                )}
              >
                <div>
                  <div className="font-medium">{r.name}</div>
                  <div className="text-xs text-muted-foreground">{r.description}</div>
                </div>
                <Badge variant="secondary">{r.permissions.length} perms</Badge>
              </button>
            ))}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
