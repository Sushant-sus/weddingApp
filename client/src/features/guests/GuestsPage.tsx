import { useState } from 'react';
import { Download, Users, UserCheck, UserPlus } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/button';
import { Select } from '@/components/ui/select';
import { formatNumber } from '@/lib/utils';
import {
  FAMILY_TYPE_OPTIONS,
  RSVP_OPTIONS,
  SIDE_OPTIONS,
  type Guest,
  type GuestFilters,
} from './guest.types';
import { useGuests, useGuestSummary } from './guest.hooks';
import { EditableGuestGrid } from './EditableGuestGrid';
import { GiftSlideOver } from '../gifts/GiftSlideOver';
import { useEventContext } from '@/context/EventContext';

function exportCsv(guests: Guest[]) {
  const headers = [
    'Family Name',
    'Family Type',
    'Side',
    'Est. Attendees',
    'Confirmed',
    'Contact',
    'Remarks',
    'RSVP Status',
  ];
  const rows = guests.map((g) => [
    g.family_name,
    g.family_type,
    g.side,
    g.attendee_count,
    g.confirmed_count ?? '',
    g.contact_phone ?? '',
    g.remarks ?? '',
    g.rsvp_status,
  ]);
  const csv = [headers, ...rows]
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(','))
    .join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `guests-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

function SummaryStat({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Users;
  label: string;
  value: string | number;
}) {
  return (
    <div className="flex items-center gap-3 rounded-lg border bg-card px-4 py-2">
      <Icon className="h-5 w-5 text-primary" />
      <div>
        <div className="text-xs text-muted-foreground">{label}</div>
        <div className="text-lg font-bold leading-tight">{value}</div>
      </div>
    </div>
  );
}

export function GuestsPage() {
  const { eventId } = useEventContext();
  const [filters, setFilters] = useState<GuestFilters>({});
  const [activeGuest, setActiveGuest] = useState<Guest | null>(null);
  const [sheetOpen, setSheetOpen] = useState(false);

  const { data: guests = [], isLoading } = useGuests(eventId, filters);
  const { data: summary } = useGuestSummary(eventId);

  const openGifts = (guest: Guest) => {
    setActiveGuest(guest);
    setSheetOpen(true);
  };

  return (
    <div>
      <PageHeader
        title="Guest Management"
        description="Excel-style editable grid. Edit freely, then Save All."
        actions={
          <Button variant="outline" onClick={() => exportCsv(guests)}>
            <Download className="h-4 w-4" /> Export CSV
          </Button>
        }
      />

      {/* Sticky summary bar */}
      <div className="sticky top-0 z-20 -mx-1 mb-4 flex flex-wrap gap-3 bg-background/80 px-1 py-2 backdrop-blur">
        <SummaryStat
          icon={Users}
          label="Total Families"
          value={formatNumber(summary?.total_families ?? 0)}
        />
        <SummaryStat
          icon={UserPlus}
          label="Total Estimated Attendees"
          value={formatNumber(summary?.total_estimated_attendees ?? 0)}
        />
        <SummaryStat
          icon={UserCheck}
          label="Total Confirmed"
          value={formatNumber(summary?.total_confirmed_attendees ?? 0)}
        />
      </div>

      {/* Filters */}
      <div className="mb-4 flex flex-wrap items-end gap-3">
        <div className="w-40">
          <label className="mb-1 block text-xs text-muted-foreground">Family Type</label>
          <Select
            options={FAMILY_TYPE_OPTIONS}
            placeholder="All"
            value={filters.familyType ?? ''}
            onChange={(e) =>
              setFilters((f) => ({ ...f, familyType: (e.target.value || undefined) as never }))
            }
          />
        </div>
        <div className="w-40">
          <label className="mb-1 block text-xs text-muted-foreground">RSVP Status</label>
          <Select
            options={RSVP_OPTIONS}
            placeholder="All"
            value={filters.rsvpStatus ?? ''}
            onChange={(e) =>
              setFilters((f) => ({ ...f, rsvpStatus: (e.target.value || undefined) as never }))
            }
          />
        </div>
        <div className="w-40">
          <label className="mb-1 block text-xs text-muted-foreground">Side</label>
          <Select
            options={SIDE_OPTIONS}
            placeholder="All"
            value={filters.side ?? ''}
            onChange={(e) =>
              setFilters((f) => ({ ...f, side: (e.target.value || undefined) as never }))
            }
          />
        </div>
        {(filters.familyType || filters.rsvpStatus || filters.side) && (
          <Button variant="ghost" onClick={() => setFilters({})}>
            Clear filters
          </Button>
        )}
      </div>

      {isLoading ? (
        <p className="text-sm text-muted-foreground">Loading guests…</p>
      ) : (
        <EditableGuestGrid eventId={eventId} guests={guests} onGiftsClick={openGifts} />
      )}

      <GiftSlideOver eventId={eventId} guest={activeGuest} open={sheetOpen} onOpenChange={setSheetOpen} />
    </div>
  );
}
