import { Activity } from 'lucide-react';
import { useEventActivity } from '../event.hooks';

function timeAgo(date: string): string {
  const s = Math.floor((Date.now() - new Date(date).getTime()) / 1000);
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

const label = (action: string) => action.replace(/_/g, ' ').toLowerCase();

export function ActivityLog({ eventId }: { eventId: string }) {
  const { data: entries = [], isLoading } = useEventActivity(eventId);

  if (isLoading) return <p className="text-sm text-muted-foreground">Loading activity…</p>;
  if (entries.length === 0)
    return <p className="text-sm text-muted-foreground">No activity recorded yet.</p>;

  return (
    <div className="space-y-3">
      {entries.map((e, i) => (
        <div key={i} className="flex items-start gap-3">
          <div className="mt-0.5 flex h-7 w-7 items-center justify-center rounded-full bg-secondary text-xs font-semibold uppercase">
            {(e.full_name || e.email || '?').charAt(0)}
          </div>
          <div className="flex-1 text-sm">
            <div>
              <span className="font-medium">{e.full_name}</span>{' '}
              <span className="text-muted-foreground">{label(e.action)}</span>
              {e.entity_type && <span className="text-muted-foreground"> ({e.entity_type.toLowerCase()})</span>}
            </div>
            <div className="text-xs text-muted-foreground">{timeAgo(e.created_at)}</div>
          </div>
          <Activity className="h-4 w-4 text-muted-foreground" />
        </div>
      ))}
    </div>
  );
}
