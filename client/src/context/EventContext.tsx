import { createContext, useContext, useMemo, type ReactNode } from 'react';
import type { EventRole, WeddingEvent } from '@/features/events/event.types';
import { ROLE_RANK } from '@/features/events/event.types';

interface EventContextValue {
  currentEvent: WeddingEvent;
  eventId: string;
  myEventRole: EventRole;
  canContribute: boolean; // CONTRIBUTOR and above
  canEdit: boolean; // EDITOR and above
  canManageMembers: boolean; // LEADER and above
  canViewCosts: boolean; // LEADER and above
  isOwner: boolean;
  /** True when the user's role rank is >= the highest rank in allowedRoles. */
  hasEventAccess: (allowedRoles: EventRole[]) => boolean;
}

const EventContext = createContext<EventContextValue | null>(null);

export function EventProvider({ event, children }: { event: WeddingEvent; children: ReactNode }) {
  const value = useMemo<EventContextValue>(() => {
    const rank = ROLE_RANK[event.my_role];
    return {
      currentEvent: event,
      eventId: event.id,
      myEventRole: event.my_role,
      canContribute: rank >= ROLE_RANK.CONTRIBUTOR,
      canEdit: rank >= ROLE_RANK.EDITOR,
      canManageMembers: rank >= ROLE_RANK.LEADER,
      canViewCosts: rank >= ROLE_RANK.LEADER,
      isOwner: event.my_role === 'OWNER',
      hasEventAccess: (allowedRoles) =>
        allowedRoles.some((r) => rank >= ROLE_RANK[r]),
    };
  }, [event]);

  return <EventContext.Provider value={value}>{children}</EventContext.Provider>;
}

export function useEventContext() {
  const ctx = useContext(EventContext);
  if (!ctx) throw new Error('useEventContext must be used within an EventProvider');
  return ctx;
}
