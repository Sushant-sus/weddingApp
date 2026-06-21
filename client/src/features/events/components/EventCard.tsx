import { Link } from 'react-router-dom';
import { Calendar, MapPin, Users, ArrowRight } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { formatDate } from '@/lib/utils';
import { RoleBadge } from './RoleBadge';
import type { WeddingEvent } from '../event.types';

function daysUntil(date: string): string {
  const diff = Math.ceil((new Date(date).getTime() - Date.now()) / 86400000);
  if (diff > 1) return `in ${diff} days`;
  if (diff === 1) return 'tomorrow';
  if (diff === 0) return 'today';
  return `${Math.abs(diff)} days ago`;
}

export function EventCard({ event }: { event: WeddingEvent }) {
  return (
    <Card className="transition-shadow hover:shadow-md">
      <CardContent className="p-5">
        <div className="flex items-start justify-between gap-2">
          <h3 className="text-lg font-bold leading-tight">{event.name}</h3>
          <RoleBadge role={event.my_role} />
        </div>
        <div className="mt-3 space-y-1.5 text-sm text-muted-foreground">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4" /> {formatDate(event.wedding_date)}
            <span className="text-primary">· {daysUntil(event.wedding_date)}</span>
          </div>
          {event.venue && (
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4" /> {event.venue}
            </div>
          )}
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4" /> {event.member_count} member{event.member_count === 1 ? '' : 's'}
            {event.guest_count != null && ` · ${event.guest_count} guests`}
          </div>
        </div>
        <Link
          to={`/events/${event.id}`}
          className="mt-4 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          Open Event <ArrowRight className="h-4 w-4" />
        </Link>
      </CardContent>
    </Card>
  );
}
