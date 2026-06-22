import { useMemo, useState } from 'react';
import { Download, Users, UserCheck, UserPlus, Plus, Search, X } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
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
import { GuestCardList } from './GuestCardList';
import { GuestFormSheet } from './GuestFormSheet';
import { GiftSlideOver } from '../gifts/GiftSlideOver';
import { useEventContext } from '@/context/EventContext';

function exportCsv(guests: Guest[]) {
  const headers = ['Family Name', 'Family Type', 'Side', 'Est. Attendees', 'Confirmed', 'Contact', 'Remarks', 'RSVP Status'];
  const rows = guests.map((g) => [
    g.family_name, g.family_type, g.side, g.attendee_count,
    g.confirmed_count ?? '', g.contact_phone ?? '', g.remarks ?? '', g.rsvp_status,
  ]);
  const csv = [headers, ...rows].map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `guests-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

function SummaryStat({ icon: Icon, label, value }: { icon: typeof Users; label: string; value: string | number }) {
  return (
    <div className="flex items-center gap-2 rounded-lg border bg-card px-3 py-2">
      <Icon className="h-4 w-4 shrink-0 text-primary sm:h-5 sm:w-5" />
      <div className="min-w-0">
        <div className="truncate text-[11px] text-muted-foreground sm:text-xs">{label}</div>
        <div className="text-base font-bold leading-tight sm:text-lg">{value}</div>
      </div>
    </div>
  );
}

export function GuestsPage() {
  const { eventId, canContribute, canEdit } = useEventContext();
  const [filters, setFilters] = useState<GuestFilters>({});
  const [search, setSearch] = useState('');
  const [activeGuest, setActiveGuest] = useState<Guest | null>(null);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [formOpen, setFormOpen] = useState(false);
  const [editingGuest, setEditingGuest] = useState<Guest | null>(null);

  const { data: guests = [], isLoading } = useGuests(eventId, filters);
  const { data: summary } = useGuestSummary(eventId);

  // Client-side search across name / contact / remarks.
  const visibleGuests = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return guests;
    return guests.filter((g) =>
      [g.family_name, g.contact_phone, g.remarks].some((v) => v?.toLowerCase().includes(q)),
    );
  }, [guests, search]);

  const openGifts = (guest: Guest) => {
    setActiveGuest(guest);
    setSheetOpen(true);
  };
  const openAdd = () => {
    setEditingGuest(null);
    setFormOpen(true);
  };
  const openEdit = (guest: Guest) => {
    setEditingGuest(guest);
    setFormOpen(true);
  };

  const hasFilters = !!(filters.familyType || filters.rsvpStatus || filters.side || search);

  return (
    <div>
      <PageHeader
        title="Guest Management"
        description="Search, filter, and manage your guest list."
        actions={
          <>
            {canContribute && (
              <Button onClick={openAdd}>
                <Plus className="h-4 w-4" /> Add Guest
              </Button>
            )}
            <Button variant="outline" onClick={() => exportCsv(visibleGuests)}>
              <Download className="h-4 w-4" /> <span className="hidden sm:inline">Export</span> CSV
            </Button>
          </>
        }
      />

      {/* Summary bar — 3-up grid on mobile, inline on larger screens */}
      <div className="sticky top-0 z-20 -mx-1 mb-4 grid grid-cols-3 gap-2 bg-background/80 px-1 py-2 backdrop-blur sm:flex sm:flex-wrap">
        <SummaryStat icon={Users} label="Families" value={formatNumber(summary?.total_families ?? 0)} />
        <SummaryStat icon={UserPlus} label="Est. Attendees" value={formatNumber(summary?.total_estimated_attendees ?? 0)} />
        <SummaryStat icon={UserCheck} label="Confirmed" value={formatNumber(summary?.total_confirmed_attendees ?? 0)} />
      </div>

      {/* Search + filters */}
      <div className="mb-4 space-y-3">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            className="pl-9"
            placeholder="Search by name, phone, or remarks…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="grid grid-cols-2 gap-2 sm:flex sm:flex-wrap sm:items-end">
          <div className="sm:w-40">
            <label className="mb-1 block text-xs text-muted-foreground">Family Type</label>
            <Select options={FAMILY_TYPE_OPTIONS} placeholder="All" value={filters.familyType ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, familyType: (e.target.value || undefined) as never }))} />
          </div>
          <div className="sm:w-40">
            <label className="mb-1 block text-xs text-muted-foreground">RSVP Status</label>
            <Select options={RSVP_OPTIONS} placeholder="All" value={filters.rsvpStatus ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, rsvpStatus: (e.target.value || undefined) as never }))} />
          </div>
          <div className="sm:w-40">
            <label className="mb-1 block text-xs text-muted-foreground">Side</label>
            <Select options={SIDE_OPTIONS} placeholder="All" value={filters.side ?? ''}
              onChange={(e) => setFilters((f) => ({ ...f, side: (e.target.value || undefined) as never }))} />
          </div>
          {hasFilters && (
            <Button variant="ghost" className="col-span-2 sm:col-auto" onClick={() => { setFilters({}); setSearch(''); }}>
              <X className="h-4 w-4" /> Clear
            </Button>
          )}
        </div>
        <p className="text-xs text-muted-foreground">
          Showing {visibleGuests.length} of {guests.length} families
        </p>
      </div>

      {isLoading ? (
        <p className="text-sm text-muted-foreground">Loading guests…</p>
      ) : (
        <>
          {/* Desktop: Excel-style editable grid */}
          <div className="hidden md:block">
            <EditableGuestGrid eventId={eventId} guests={visibleGuests} onGiftsClick={openGifts} />
          </div>
          {/* Mobile: card list */}
          <div className="md:hidden">
            <GuestCardList eventId={eventId} guests={visibleGuests} onGifts={openGifts} onEdit={openEdit} canEdit={canEdit} />
          </div>
        </>
      )}

      <GiftSlideOver eventId={eventId} guest={activeGuest} open={sheetOpen} onOpenChange={setSheetOpen} />
      <GuestFormSheet eventId={eventId} guest={editingGuest} open={formOpen} onOpenChange={setFormOpen} />
    </div>
  );
}
