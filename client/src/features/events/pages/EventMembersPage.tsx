import { useState } from 'react';
import { UserPlus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useEventContext } from '@/context/EventContext';
import { useEventMembers } from '../event.hooks';
import { MemberList } from '../components/MemberList';
import { InviteMemberModal } from '../components/InviteMemberModal';

export function EventMembersPage() {
  const { eventId, canManageMembers, isOwner } = useEventContext();
  const { data: members = [], isLoading } = useEventMembers(eventId);
  const [inviteOpen, setInviteOpen] = useState(false);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {members.length} member{members.length === 1 ? '' : 's'}
        </p>
        {canManageMembers && (
          <Button onClick={() => setInviteOpen(true)}>
            <UserPlus className="h-4 w-4" /> Invite Member
          </Button>
        )}
      </div>

      {isLoading ? (
        <p className="text-sm text-muted-foreground">Loading members…</p>
      ) : (
        <MemberList eventId={eventId} members={members} canManage={canManageMembers} />
      )}

      <InviteMemberModal
        eventId={eventId}
        open={inviteOpen}
        onOpenChange={setInviteOpen}
        canAssignLeader={isOwner}
      />
    </div>
  );
}
