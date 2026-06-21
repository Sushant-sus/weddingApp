import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  LayoutDashboard,
  Users,
  Gift,
  CalendarClock,
  Wallet,
  UserCog,
  Activity,
} from 'lucide-react';
import { cn, formatDate } from '@/lib/utils';
import { EventProvider, useEventContext } from '@/context/EventContext';
import { useEvent } from '../event.hooks';
import { RoleBadge } from '../components/RoleBadge';
import { ActivityLog } from '../components/ActivityLog';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { GuestsPage } from '@/features/guests/GuestsPage';
import { GiftsPage } from '@/features/gifts/GiftsPage';
import { ItineraryPage } from '@/features/itinerary/ItineraryPage';
import { CostsPage } from '@/features/costs/CostsPage';
import { EventMembersPage } from './EventMembersPage';

type TabId = 'overview' | 'guests' | 'gifts' | 'itinerary' | 'costs' | 'members' | 'activity';

function EventWorkspace() {
  const { currentEvent, canViewCosts, eventId } = useEventContext();
  const [tab, setTab] = useState<TabId>('overview');

  const tabs: { id: TabId; label: string; icon: typeof Users; show: boolean }[] = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard, show: true },
    { id: 'guests', label: 'Guests', icon: Users, show: true },
    { id: 'gifts', label: 'Gifts', icon: Gift, show: true },
    { id: 'itinerary', label: 'Itinerary', icon: CalendarClock, show: true },
    { id: 'costs', label: 'Costs', icon: Wallet, show: canViewCosts },
    { id: 'members', label: 'Members', icon: UserCog, show: true },
    { id: 'activity', label: 'Activity', icon: Activity, show: true },
  ];

  return (
    <div>
      <Link to="/events" className="mb-2 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> All events
      </Link>

      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold tracking-tight">{currentEvent.name}</h1>
            <RoleBadge role={currentEvent.my_role} />
          </div>
          <p className="mt-1 text-sm text-muted-foreground">
            {formatDate(currentEvent.wedding_date)}
            {currentEvent.venue ? ` · ${currentEvent.venue}` : ''}
          </p>
        </div>
      </div>

      <div className="mb-6 flex gap-1 overflow-x-auto border-b">
        {tabs.filter((t) => t.show).map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={cn(
              'flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-2 text-sm font-medium transition-colors',
              tab === t.id
                ? 'border-primary text-primary'
                : 'border-transparent text-muted-foreground hover:text-foreground',
            )}
          >
            <t.icon className="h-4 w-4" /> {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <DashboardPage />}
      {tab === 'guests' && <GuestsPage />}
      {tab === 'gifts' && <GiftsPage />}
      {tab === 'itinerary' && <ItineraryPage />}
      {tab === 'costs' && canViewCosts && <CostsPage />}
      {tab === 'members' && <EventMembersPage />}
      {tab === 'activity' && <ActivityLog eventId={eventId} />}
    </div>
  );
}

export function EventDetailPage() {
  const { eventId } = useParams<{ eventId: string }>();
  const { data: event, isLoading, isError } = useEvent(eventId);

  if (isLoading) {
    return <div className="flex h-screen items-center justify-center text-muted-foreground">Loading event…</div>;
  }
  if (isError || !event) {
    return (
      <div className="flex h-screen flex-col items-center justify-center gap-3 text-center">
        <p className="text-muted-foreground">Event not found or you don't have access.</p>
        <Link to="/events" className="text-primary hover:underline">Back to my events</Link>
      </div>
    );
  }

  return (
    <EventProvider event={event}>
      <EventWorkspace />
    </EventProvider>
  );
}
