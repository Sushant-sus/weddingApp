import { useState } from 'react';
import { UserPlus } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select } from '@/components/ui/select';
import { EVENT_ROLE_OPTIONS, type EventRole } from '../event.types';
import { useInviteMember } from '../event.hooks';

export function InviteMemberModal({
  eventId,
  open,
  onOpenChange,
  canAssignLeader,
}: {
  eventId: string;
  open: boolean;
  onOpenChange: (o: boolean) => void;
  canAssignLeader: boolean;
}) {
  const invite = useInviteMember(eventId);
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<EventRole>('VIEWER');

  const options = canAssignLeader
    ? EVENT_ROLE_OPTIONS
    : EVENT_ROLE_OPTIONS.filter((o) => o.value !== 'LEADER');

  const onSubmit = async () => {
    if (!email.trim()) return;
    await invite.mutateAsync({ email: email.trim(), role });
    setEmail('');
    setRole('VIEWER');
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <UserPlus className="h-5 w-5 text-primary" /> Invite Member
          </DialogTitle>
          <DialogDescription>
            They must already have an account. An invite email will be sent.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <div>
            <Label>Email</Label>
            <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <Label>Event Role</Label>
            <Select options={options} value={role} onChange={(e) => setRole(e.target.value as EventRole)} />
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button onClick={onSubmit} disabled={!email.trim() || invite.isPending}>
              {invite.isPending ? 'Sending…' : 'Send Invite'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
