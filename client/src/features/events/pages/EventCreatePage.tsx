import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { useCreateEvent } from '../event.hooks';
import type { WeddingEvent } from '../event.types';

export function EventCreatePage() {
  const navigate = useNavigate();
  const createEvent = useCreateEvent();
  const [form, setForm] = useState({
    name: '',
    weddingDate: '',
    venue: '',
    description: '',
  });

  const set = (k: keyof typeof form, v: string) => setForm((f) => ({ ...f, [k]: v }));

  const onSubmit = async () => {
    if (!form.name.trim() || !form.weddingDate) return;
    const ev = (await createEvent.mutateAsync({
      name: form.name.trim(),
      weddingDate: form.weddingDate,
      venue: form.venue || null,
      description: form.description || null,
    })) as WeddingEvent;
    navigate(`/events/${ev.id}`);
  };

  return (
    <div className="mx-auto max-w-xl">
      <Button variant="ghost" size="sm" className="mb-2" onClick={() => navigate('/events')}>
        <ArrowLeft className="h-4 w-4" /> Back
      </Button>
      <PageHeader title="Create Wedding Event" description="You'll be the owner of this event." />
      <Card>
        <CardContent className="space-y-3 p-6">
          <div>
            <Label>Event Name</Label>
            <Input placeholder="Ram & Sita Wedding 2026" value={form.name} onChange={(e) => set('name', e.target.value)} />
          </div>
          <div>
            <Label>Wedding Date</Label>
            <Input type="date" value={form.weddingDate} onChange={(e) => set('weddingDate', e.target.value)} />
          </div>
          <div>
            <Label>Venue</Label>
            <Input value={form.venue} onChange={(e) => set('venue', e.target.value)} />
          </div>
          <div>
            <Label>Description</Label>
            <Textarea value={form.description} onChange={(e) => set('description', e.target.value)} />
          </div>
          <Button
            className="w-full"
            onClick={onSubmit}
            disabled={!form.name.trim() || !form.weddingDate || createEvent.isPending}
          >
            {createEvent.isPending ? 'Creating…' : 'Create Event'}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
