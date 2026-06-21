import { Link } from 'react-router-dom';
import { Plus, Mail } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { useMyEvents } from '../event.hooks';
import { EventCard } from '../components/EventCard';
import { RoleBadge } from '../components/RoleBadge';
import { formatDate } from '@/lib/utils';

export function EventListPage() {
  const { data: events = [], isLoading } = useMyEvents();

  const active = events.filter((e) => e.invite_status !== 'PENDING');
  const pending = events.filter((e) => e.invite_status === 'PENDING');

  return (
    <div>
      <PageHeader
        title="My Wedding Events"
        description="All the weddings you're collaborating on."
        actions={
          <Button asChild>
            <Link to="/events/new">
              <Plus className="h-4 w-4" /> Create Event
            </Link>
          </Button>
        }
      />

      {pending.length > 0 && (
        <Card className="mb-6 border-primary/40 bg-primary/5">
          <CardContent className="p-4">
            <div className="mb-2 flex items-center gap-2 text-sm font-medium text-primary">
              <Mail className="h-4 w-4" /> Pending invitations
            </div>
            <div className="space-y-2">
              {pending.map((e) => (
                <div key={e.id} className="flex items-center justify-between rounded-md border bg-card px-3 py-2 text-sm">
                  <div>
                    <span className="font-medium">{e.name}</span>{' '}
                    <span className="text-muted-foreground">· {formatDate(e.wedding_date)}</span>{' '}
                    <RoleBadge role={e.my_role} />
                  </div>
                  <span className="text-xs text-muted-foreground">Respond via your email invite link</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <p className="text-sm text-muted-foreground">Loading events…</p>
      ) : active.length === 0 ? (
        <div className="rounded-lg border border-dashed p-12 text-center">
          <p className="text-muted-foreground">You're not part of any wedding events yet.</p>
          <Button asChild className="mt-4">
            <Link to="/events/new">
              <Plus className="h-4 w-4" /> Create your first event
            </Link>
          </Button>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {active.map((e) => (
            <EventCard key={e.id} event={e} />
          ))}
        </div>
      )}
    </div>
  );
}
