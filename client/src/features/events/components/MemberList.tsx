import { Trash2, Clock } from 'lucide-react';
import { Select } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatDate } from '@/lib/utils';
import { RoleBadge } from './RoleBadge';
import { EVENT_ROLE_OPTIONS, type EventMember, type EventRole } from '../event.types';
import { useChangeMemberRole, useRemoveMember } from '../event.hooks';
import { useAuth } from '@/context/AuthContext';

export function MemberList({
  eventId,
  members,
  canManage,
}: {
  eventId: string;
  members: EventMember[];
  canManage: boolean;
}) {
  const changeRole = useChangeMemberRole(eventId);
  const removeMember = useRemoveMember(eventId);
  const { user } = useAuth();

  return (
    <div className="overflow-x-auto rounded-lg border bg-card">
      <table className="w-full text-sm">
        <thead className="bg-secondary text-xs uppercase tracking-wide text-muted-foreground">
          <tr>
            <th className="px-4 py-3 text-left">Member</th>
            <th className="px-4 py-3 text-left">Role</th>
            <th className="px-4 py-3 text-left">Status</th>
            <th className="px-4 py-3 text-left">Joined</th>
            {canManage && <th className="px-4 py-3 text-left">Actions</th>}
          </tr>
        </thead>
        <tbody>
          {members.map((m) => {
            const isOwner = m.event_role === 'OWNER';
            const isSelf = m.user_id === user?.id;
            return (
              <tr key={m.id} className="border-b last:border-0 hover:bg-secondary/40">
                <td className="px-4 py-2">
                  <div className="font-medium">{m.full_name}</div>
                  <div className="text-xs text-muted-foreground">{m.email}</div>
                </td>
                <td className="px-4 py-2">
                  {canManage && !isOwner ? (
                    <Select
                      className="h-8 w-36"
                      options={EVENT_ROLE_OPTIONS}
                      value={m.event_role}
                      onChange={(e) =>
                        changeRole.mutate({ userId: m.user_id, role: e.target.value as EventRole })
                      }
                    />
                  ) : (
                    <RoleBadge role={m.event_role} />
                  )}
                </td>
                <td className="px-4 py-2">
                  {m.invite_status === 'ACCEPTED' ? (
                    <Badge variant="success">Active</Badge>
                  ) : m.invite_status === 'PENDING' ? (
                    <Badge variant="warning"><Clock className="mr-1 h-3 w-3" />Pending</Badge>
                  ) : (
                    <Badge variant="destructive">Declined</Badge>
                  )}
                </td>
                <td className="px-4 py-2 text-muted-foreground">
                  {m.joined_at ? formatDate(m.joined_at) : '—'}
                </td>
                {canManage && (
                  <td className="px-4 py-2">
                    {!isOwner && !isSelf && (
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive"
                        onClick={() => removeMember.mutate(m.user_id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    )}
                  </td>
                )}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
