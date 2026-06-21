import { useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { CATEGORY_OPTIONS, type EventPayload, type ItineraryEvent } from './itinerary.types';
import { useCreateEvent, useUpdateEvent } from './itinerary.hooks';

interface Props {
  eventId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  event: ItineraryEvent | null; // null = create mode
}

const empty: EventPayload = {
  title: '',
  description: '',
  eventDate: new Date().toISOString().slice(0, 10),
  startTime: '',
  endTime: '',
  location: '',
  responsible: '',
  category: 'CEREMONY',
};

export function EventFormDialog({ eventId, open, onOpenChange, event }: Props) {
  const [form, setForm] = useState<EventPayload>(empty);
  const createEvent = useCreateEvent(eventId);
  const updateEvent = useUpdateEvent(eventId);

  useEffect(() => {
    if (event) {
      setForm({
        title: event.title,
        description: event.description ?? '',
        eventDate: event.event_date.slice(0, 10),
        startTime: event.start_time,
        endTime: event.end_time ?? '',
        location: event.location ?? '',
        responsible: event.responsible ?? '',
        category: event.category,
      });
    } else {
      setForm(empty);
    }
  }, [event, open]);

  const set = (k: keyof EventPayload, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const handleSubmit = async () => {
    if (!form.title.trim() || !form.startTime.trim()) return;
    if (event) {
      await updateEvent.mutateAsync({ id: event.id, payload: form });
    } else {
      await createEvent.mutateAsync(form);
    }
    onOpenChange(false);
  };

  const pending = createEvent.isPending || updateEvent.isPending;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{event ? 'Edit Event' : 'Add Event'}</DialogTitle>
          <DialogDescription>Schedule a moment in the wedding timeline.</DialogDescription>
        </DialogHeader>

        <div className="grid gap-3">
          <div>
            <Label>Title</Label>
            <Input value={form.title} onChange={(e) => set('title', e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Date</Label>
              <Input type="date" value={form.eventDate} onChange={(e) => set('eventDate', e.target.value)} />
            </div>
            <div>
              <Label>Category</Label>
              <Select
                options={CATEGORY_OPTIONS}
                value={form.category}
                onChange={(e) => set('category', e.target.value)}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Start Time</Label>
              <Input
                placeholder="10:00 AM"
                value={form.startTime}
                onChange={(e) => set('startTime', e.target.value)}
              />
            </div>
            <div>
              <Label>End Time</Label>
              <Input
                placeholder="11:30 AM"
                value={form.endTime ?? ''}
                onChange={(e) => set('endTime', e.target.value)}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label>Location</Label>
              <Input value={form.location ?? ''} onChange={(e) => set('location', e.target.value)} />
            </div>
            <div>
              <Label>Responsible</Label>
              <Input
                value={form.responsible ?? ''}
                onChange={(e) => set('responsible', e.target.value)}
              />
            </div>
          </div>
          <div>
            <Label>Description</Label>
            <Textarea
              value={form.description ?? ''}
              onChange={(e) => set('description', e.target.value)}
            />
          </div>
        </div>

        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={pending}>
            {pending ? 'Saving…' : event ? 'Save Changes' : 'Add Event'}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
