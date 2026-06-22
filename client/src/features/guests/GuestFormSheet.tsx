import { useEffect, useState } from 'react';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select } from '@/components/ui/select';
import {
  FAMILY_TYPE_OPTIONS,
  RSVP_OPTIONS,
  SIDE_OPTIONS,
  type FamilyType,
  type Guest,
  type RsvpStatus,
  type Side,
} from './guest.types';
import { useCreateGuest, useUpdateGuest } from './guest.hooks';

interface Props {
  eventId: string;
  guest: Guest | null; // null = add mode
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const emptyForm = {
  familyName: '',
  familyType: 'CHULEY',
  side: 'BRIDE',
  attendeeCount: '1',
  confirmedCount: '',
  contactPhone: '',
  remarks: '',
  rsvpStatus: 'PENDING',
};

export function GuestFormSheet({ eventId, guest, open, onOpenChange }: Props) {
  const isEdit = !!guest;
  const createGuest = useCreateGuest(eventId);
  const updateGuest = useUpdateGuest(eventId);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    if (guest) {
      setForm({
        familyName: guest.family_name,
        familyType: guest.family_type,
        side: guest.side,
        attendeeCount: String(guest.attendee_count ?? ''),
        confirmedCount: guest.confirmed_count == null ? '' : String(guest.confirmed_count),
        contactPhone: guest.contact_phone ?? '',
        remarks: guest.remarks ?? '',
        rsvpStatus: guest.rsvp_status,
      });
    } else {
      setForm(emptyForm);
    }
  }, [guest, open]);

  const set = (k: keyof typeof form, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const onSubmit = async () => {
    if (!form.familyName.trim()) return;
    if (isEdit && guest) {
      await updateGuest.mutateAsync({
        id: guest.id,
        payload: {
          familyName: form.familyName.trim(),
          familyType: form.familyType as FamilyType,
          side: form.side as Side,
          attendeeCount: Number(form.attendeeCount) || 0,
          confirmedCount: form.confirmedCount === '' ? null : Number(form.confirmedCount),
          contactPhone: form.contactPhone || null,
          remarks: form.remarks || null,
          rsvpStatus: form.rsvpStatus as RsvpStatus,
        },
      });
    } else {
      await createGuest.mutateAsync({
        familyName: form.familyName.trim(),
        familyType: form.familyType as FamilyType,
        side: form.side as Side,
        attendeeCount: Number(form.attendeeCount) || 0,
        contactPhone: form.contactPhone || null,
        remarks: form.remarks || null,
      });
    }
    onOpenChange(false);
  };

  const pending = createGuest.isPending || updateGuest.isPending;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="overflow-y-auto">
        <SheetHeader>
          <SheetTitle>{isEdit ? 'Edit Guest' : 'Add Guest'}</SheetTitle>
          <SheetDescription>{isEdit ? guest?.family_name : 'Add a new family or guest.'}</SheetDescription>
        </SheetHeader>

        <div className="space-y-3">
          <div>
            <Label>Family Name</Label>
            <Input value={form.familyName} onChange={(e) => set('familyName', e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Family Type</Label>
              <Select options={FAMILY_TYPE_OPTIONS} value={form.familyType} onChange={(e) => set('familyType', e.target.value)} />
            </div>
            <div>
              <Label>Side</Label>
              <Select options={SIDE_OPTIONS} value={form.side} onChange={(e) => set('side', e.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Est. Attendees</Label>
              <Input type="number" min={0} value={form.attendeeCount} onChange={(e) => set('attendeeCount', e.target.value)} />
            </div>
            {isEdit && (
              <div>
                <Label>Confirmed</Label>
                <Input type="number" min={0} value={form.confirmedCount} onChange={(e) => set('confirmedCount', e.target.value)} />
              </div>
            )}
          </div>
          <div>
            <Label>Contact Phone</Label>
            <Input value={form.contactPhone} onChange={(e) => set('contactPhone', e.target.value)} />
          </div>
          {isEdit && (
            <div>
              <Label>RSVP Status</Label>
              <Select options={RSVP_OPTIONS} value={form.rsvpStatus} onChange={(e) => set('rsvpStatus', e.target.value)} />
            </div>
          )}
          <div>
            <Label>Remarks</Label>
            <Input value={form.remarks} onChange={(e) => set('remarks', e.target.value)} />
          </div>

          <div className="flex gap-2 pt-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button className="flex-1" onClick={onSubmit} disabled={!form.familyName.trim() || pending}>
              {pending ? 'Saving…' : isEdit ? 'Save' : 'Add Guest'}
            </Button>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
