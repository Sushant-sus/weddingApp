import { cn } from '@/lib/utils';
import type { EventRole } from '../event.types';

// OWNER=gold, LEADER=purple, EDITOR=blue, CONTRIBUTOR=green, VIEWER=gray
const styles: Record<EventRole, string> = {
  OWNER: 'bg-amber-100 text-amber-800',
  LEADER: 'bg-purple-100 text-purple-800',
  EDITOR: 'bg-sky-100 text-sky-800',
  CONTRIBUTOR: 'bg-emerald-100 text-emerald-800',
  VIEWER: 'bg-slate-100 text-slate-700',
};

export function RoleBadge({ role, className }: { role: EventRole; className?: string }) {
  return (
    <span
      className={cn('rounded-full px-2.5 py-0.5 text-xs font-semibold', styles[role] ?? styles.VIEWER, className)}
    >
      {role}
    </span>
  );
}
