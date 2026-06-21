import { useMemo, useState } from 'react';
import {
  flexRender,
  getCoreRowModel,
  useReactTable,
  type ColumnDef,
} from '@tanstack/react-table';
import { Save, Trash2, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { cn } from '@/lib/utils';
import {
  FAMILY_TYPE_OPTIONS,
  RSVP_OPTIONS,
  SIDE_OPTIONS,
  type Guest,
  type GuestUpdatePayload,
  type RsvpStatus,
} from './guest.types';
import { useBatchUpdateGuests, useCreateGuest, useDeleteGuest } from './guest.hooks';

type Draft = Record<string, Partial<Record<keyof Guest, string | number | null>>>;

// Maps a snake_case Guest field to the camelCase key the API batch expects.
const FIELD_TO_PAYLOAD: Partial<Record<keyof Guest, keyof GuestUpdatePayload>> = {
  family_name: 'familyName',
  family_type: 'familyType',
  side: 'side',
  attendee_count: 'attendeeCount',
  confirmed_count: 'confirmedCount',
  contact_phone: 'contactPhone',
  remarks: 'remarks',
  rsvp_status: 'rsvpStatus',
};

const rsvpVariant: Record<RsvpStatus, 'success' | 'warning' | 'destructive'> = {
  CONFIRMED: 'success',
  PENDING: 'warning',
  DECLINED: 'destructive',
};

interface Props {
  eventId: string;
  guests: Guest[];
  onGiftsClick: (guest: Guest) => void;
}

export function EditableGuestGrid({ eventId, guests, onGiftsClick }: Props) {
  const [draft, setDraft] = useState<Draft>({});
  const [toDelete, setToDelete] = useState<Guest | null>(null);
  const [newRow, setNewRow] = useState({
    familyName: '',
    familyType: 'CHULEY',
    side: 'BRIDE',
    attendeeCount: '1',
    contactPhone: '',
    remarks: '',
  });

  const batchUpdate = useBatchUpdateGuests(eventId);
  const createGuest = useCreateGuest(eventId);
  const deleteGuest = useDeleteGuest(eventId);

  const dirtyIds = Object.keys(draft).filter(
    (id) => Object.keys(draft[id] ?? {}).length > 0,
  );

  const setCell = (id: string, field: keyof Guest, value: string | number | null) => {
    setDraft((prev) => {
      const original = guests.find((g) => g.id === id);
      const next = { ...(prev[id] ?? {}) };
      if (original && String(original[field] ?? '') === String(value ?? '')) {
        delete next[field]; // reverted to original → no longer dirty
      } else {
        next[field] = value;
      }
      return { ...prev, [id]: next };
    });
  };

  const valueOf = (row: Guest, field: keyof Guest) => {
    const d = draft[row.id]?.[field];
    return d !== undefined ? d : row[field];
  };

  const handleSaveAll = async () => {
    const updates: GuestUpdatePayload[] = dirtyIds.map((id) => {
      const payload: GuestUpdatePayload = { id };
      const changes = draft[id]!;
      for (const [field, val] of Object.entries(changes)) {
        const key = FIELD_TO_PAYLOAD[field as keyof Guest];
        if (!key) continue;
        if (field === 'attendee_count' || field === 'confirmed_count') {
          (payload as unknown as Record<string, unknown>)[key] =
            val === '' || val === null ? null : Number(val);
        } else {
          (payload as unknown as Record<string, unknown>)[key] = val;
        }
      }
      return payload;
    });
    if (updates.length === 0) return;
    await batchUpdate.mutateAsync(updates);
    setDraft({});
  };

  const handleAddRow = async () => {
    if (!newRow.familyName.trim()) return;
    await createGuest.mutateAsync({
      familyName: newRow.familyName.trim(),
      familyType: newRow.familyType as 'CHULEY' | 'SINGLE',
      side: newRow.side as 'BRIDE' | 'GROOM' | 'BOTH',
      attendeeCount: Number(newRow.attendeeCount) || 0,
      contactPhone: newRow.contactPhone || null,
      remarks: newRow.remarks || null,
    });
    setNewRow({
      familyName: '',
      familyType: 'CHULEY',
      side: 'BRIDE',
      attendeeCount: '1',
      contactPhone: '',
      remarks: '',
    });
  };

  const columns = useMemo<ColumnDef<Guest>[]>(
    () => [
      {
        id: 'index',
        header: '#',
        cell: ({ row }) => <span className="text-muted-foreground">{row.index + 1}</span>,
        size: 40,
      },
      {
        accessorKey: 'family_name',
        header: 'Family Name',
        cell: ({ row }) => (
          <Input
            value={String(valueOf(row.original, 'family_name') ?? '')}
            onChange={(e) => setCell(row.original.id, 'family_name', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input focus-visible:border-input"
          />
        ),
      },
      {
        accessorKey: 'family_type',
        header: 'Family Type',
        cell: ({ row }) => (
          <Select
            options={FAMILY_TYPE_OPTIONS}
            value={String(valueOf(row.original, 'family_type') ?? '')}
            onChange={(e) => setCell(row.original.id, 'family_type', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input"
          />
        ),
      },
      {
        accessorKey: 'side',
        header: 'Side',
        cell: ({ row }) => (
          <Select
            options={SIDE_OPTIONS}
            value={String(valueOf(row.original, 'side') ?? '')}
            onChange={(e) => setCell(row.original.id, 'side', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input"
          />
        ),
      },
      {
        accessorKey: 'attendee_count',
        header: 'Est.',
        cell: ({ row }) => (
          <Input
            type="number"
            min={0}
            value={String(valueOf(row.original, 'attendee_count') ?? '')}
            onChange={(e) => setCell(row.original.id, 'attendee_count', e.target.value)}
            className="h-8 w-16 border-transparent bg-transparent text-center hover:border-input"
          />
        ),
        size: 70,
      },
      {
        accessorKey: 'confirmed_count',
        header: 'Conf.',
        cell: ({ row }) => (
          <Input
            type="number"
            min={0}
            value={String(valueOf(row.original, 'confirmed_count') ?? '')}
            onChange={(e) => setCell(row.original.id, 'confirmed_count', e.target.value)}
            className="h-8 w-16 border-transparent bg-transparent text-center hover:border-input"
          />
        ),
        size: 70,
      },
      {
        accessorKey: 'contact_phone',
        header: 'Contact',
        cell: ({ row }) => (
          <Input
            value={String(valueOf(row.original, 'contact_phone') ?? '')}
            onChange={(e) => setCell(row.original.id, 'contact_phone', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input"
          />
        ),
      },
      {
        accessorKey: 'remarks',
        header: 'Remarks',
        cell: ({ row }) => (
          <Input
            value={String(valueOf(row.original, 'remarks') ?? '')}
            onChange={(e) => setCell(row.original.id, 'remarks', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input"
          />
        ),
      },
      {
        accessorKey: 'rsvp_status',
        header: 'RSVP',
        cell: ({ row }) => (
          <Select
            options={RSVP_OPTIONS}
            value={String(valueOf(row.original, 'rsvp_status') ?? '')}
            onChange={(e) => setCell(row.original.id, 'rsvp_status', e.target.value)}
            className="h-8 border-transparent bg-transparent hover:border-input"
          />
        ),
      },
      {
        id: 'actions',
        header: 'Actions',
        cell: ({ row }) => (
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="sm"
              className="h-8 px-2"
              onClick={() => onGiftsClick(row.original)}
            >
              Gifts
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-destructive"
              onClick={() => setToDelete(row.original)}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        ),
        size: 130,
      },
    ],
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [draft, guests],
  );

  const table = useReactTable({
    data: guests,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Click any cell to edit. {dirtyIds.length > 0 && (
            <span className="font-medium text-primary">{dirtyIds.length} unsaved row(s)</span>
          )}
        </p>
        <Button onClick={handleSaveAll} disabled={dirtyIds.length === 0 || batchUpdate.isPending}>
          <Save className="h-4 w-4" />
          {batchUpdate.isPending ? 'Saving...' : 'Save All Changes'}
        </Button>
      </div>

      <div className="overflow-x-auto rounded-lg border bg-card">
        <table className="w-full border-collapse text-sm">
          <thead className="bg-secondary">
            {table.getHeaderGroups().map((hg) => (
              <tr key={hg.id}>
                {hg.headers.map((header) => (
                  <th
                    key={header.id}
                    className="border-b px-2 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                  >
                    {flexRender(header.column.columnDef.header, header.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {table.getRowModel().rows.map((row) => (
              <tr
                key={row.id}
                className={cn(
                  'border-b last:border-0 hover:bg-secondary/40',
                  draft[row.original.id] && Object.keys(draft[row.original.id]!).length > 0
                    ? 'bg-amber-50'
                    : '',
                )}
              >
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-2 py-1 align-middle">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}

            {/* Excel-style empty row to add a new guest */}
            <tr className="border-t-2 bg-secondary/30">
              <td className="px-2 py-1 text-center text-muted-foreground">
                <Plus className="mx-auto h-4 w-4" />
              </td>
              <td className="px-2 py-1">
                <Input
                  placeholder="New family name…"
                  value={newRow.familyName}
                  onChange={(e) => setNewRow((s) => ({ ...s, familyName: e.target.value }))}
                  onKeyDown={(e) => e.key === 'Enter' && handleAddRow()}
                  className="h-8"
                />
              </td>
              <td className="px-2 py-1">
                <Select
                  options={FAMILY_TYPE_OPTIONS}
                  value={newRow.familyType}
                  onChange={(e) => setNewRow((s) => ({ ...s, familyType: e.target.value }))}
                  className="h-8"
                />
              </td>
              <td className="px-2 py-1">
                <Select
                  options={SIDE_OPTIONS}
                  value={newRow.side}
                  onChange={(e) => setNewRow((s) => ({ ...s, side: e.target.value }))}
                  className="h-8"
                />
              </td>
              <td className="px-2 py-1">
                <Input
                  type="number"
                  min={0}
                  value={newRow.attendeeCount}
                  onChange={(e) => setNewRow((s) => ({ ...s, attendeeCount: e.target.value }))}
                  className="h-8 w-16 text-center"
                />
              </td>
              <td className="px-2 py-1 text-center text-muted-foreground">—</td>
              <td className="px-2 py-1">
                <Input
                  placeholder="Phone"
                  value={newRow.contactPhone}
                  onChange={(e) => setNewRow((s) => ({ ...s, contactPhone: e.target.value }))}
                  className="h-8"
                />
              </td>
              <td className="px-2 py-1">
                <Input
                  placeholder="Remarks"
                  value={newRow.remarks}
                  onChange={(e) => setNewRow((s) => ({ ...s, remarks: e.target.value }))}
                  className="h-8"
                />
              </td>
              <td className="px-2 py-1">
                <Badge variant="warning">PENDING</Badge>
              </td>
              <td className="px-2 py-1">
                <Button
                  size="sm"
                  className="h-8"
                  onClick={handleAddRow}
                  disabled={!newRow.familyName.trim() || createGuest.isPending}
                >
                  <Plus className="h-4 w-4" /> Add
                </Button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <Dialog open={!!toDelete} onOpenChange={(o) => !o && setToDelete(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete guest?</DialogTitle>
            <DialogDescription>
              This will remove <strong>{toDelete?.family_name}</strong>. This action can be undone
              only by a DBA (soft delete).
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setToDelete(null)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={async () => {
                if (toDelete) await deleteGuest.mutateAsync(toDelete.id);
                setToDelete(null);
              }}
            >
              Delete
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
