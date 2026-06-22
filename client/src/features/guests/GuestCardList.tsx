import { useState } from 'react';
import { Gift, Pencil, Trash2, Phone, Users } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { useDeleteGuest } from './guest.hooks';
import type { Guest, RsvpStatus } from './guest.types';

const rsvpVariant: Record<RsvpStatus, 'success' | 'warning' | 'destructive'> = {
  CONFIRMED: 'success',
  PENDING: 'warning',
  DECLINED: 'destructive',
};

interface Props {
  eventId: string;
  guests: Guest[];
  onGifts: (g: Guest) => void;
  onEdit: (g: Guest) => void;
  canEdit: boolean;
}

export function GuestCardList({ eventId, guests, onGifts, onEdit, canEdit }: Props) {
  const deleteGuest = useDeleteGuest(eventId);
  const [toDelete, setToDelete] = useState<Guest | null>(null);

  if (guests.length === 0) {
    return (
      <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
        No guests match your filters.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {guests.map((g) => (
        <div key={g.id} className="rounded-lg border bg-card p-4 shadow-sm">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-semibold leading-tight">{g.family_name}</h3>
            <Badge variant={rsvpVariant[g.rsvp_status]}>{g.rsvp_status}</Badge>
          </div>

          <div className="mt-2 flex flex-wrap gap-1.5">
            <Badge variant="secondary">{g.family_type === 'CHULEY' ? 'Chuley' : 'Single'}</Badge>
            <Badge variant="info">{g.side}</Badge>
          </div>

          <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
            <div className="flex items-center gap-1.5 text-muted-foreground">
              <Users className="h-3.5 w-3.5" />
              <span>
                {g.attendee_count} est
                {g.confirmed_count != null ? ` · ${g.confirmed_count} conf` : ''}
              </span>
            </div>
            {g.contact_phone && (
              <a
                href={`tel:${g.contact_phone}`}
                className="flex items-center gap-1.5 text-primary"
              >
                <Phone className="h-3.5 w-3.5" /> {g.contact_phone}
              </a>
            )}
          </div>

          {g.remarks && <p className="mt-2 text-sm text-muted-foreground">{g.remarks}</p>}

          <div className="mt-3 flex gap-2">
            <Button variant="outline" size="sm" className="flex-1" onClick={() => onGifts(g)}>
              <Gift className="h-4 w-4" /> Gifts
            </Button>
            {canEdit && (
              <>
                <Button variant="outline" size="sm" className="flex-1" onClick={() => onEdit(g)}>
                  <Pencil className="h-4 w-4" /> Edit
                </Button>
                <Button
                  variant="outline"
                  size="icon"
                  className="text-destructive"
                  onClick={() => setToDelete(g)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </>
            )}
          </div>
        </div>
      ))}

      <Dialog open={!!toDelete} onOpenChange={(o) => !o && setToDelete(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete guest?</DialogTitle>
            <DialogDescription>
              Remove <strong>{toDelete?.family_name}</strong>? This can be undone only by a DBA.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setToDelete(null)}>Cancel</Button>
            <Button
              variant="destructive"
              onClick={async () => {
                if (toDelete) await deleteGuest.mutateAsync(toDelete.id);
                setToDelete(null);
              }}
            >
              Delete
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
