import { useEffect, useState } from 'react';
import {
  DndContext,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  arrayMove,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { GripVertical, Plus, Pencil, Trash2, Printer, MapPin, User, Clock } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/button';
import { cn, formatDate } from '@/lib/utils';
import {
  CATEGORY_STYLES,
  CATEGORY_OPTIONS,
  type ItineraryEvent,
} from './itinerary.types';
import { useItinerary, useDeleteEvent, useReorderEvents } from './itinerary.hooks';
import { EventFormDialog } from './EventFormDialog';
import { useEventContext } from '@/context/EventContext';

function SortableEvent({
  event,
  index,
  onEdit,
  onDelete,
}: {
  event: ItineraryEvent;
  index: number;
  onEdit: (e: ItineraryEvent) => void;
  onDelete: (e: ItineraryEvent) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: event.id,
  });
  const style = { transform: CSS.Transform.toString(transform), transition };
  const cat = CATEGORY_STYLES[event.category];
  const label = CATEGORY_OPTIONS.find((c) => c.value === event.category)?.label ?? event.category;

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        'flex items-stretch gap-3 rounded-lg border border-l-4 bg-card p-4 shadow-sm',
        cat.border,
        isDragging && 'opacity-60 ring-2 ring-primary',
      )}
    >
      <button
        className="no-print flex cursor-grab items-center text-muted-foreground active:cursor-grabbing"
        {...attributes}
        {...listeners}
        aria-label="Drag to reorder"
      >
        <GripVertical className="h-5 w-5" />
      </button>

      <div className="flex w-20 shrink-0 flex-col items-center justify-center rounded-md bg-secondary/60 px-2 py-1 text-center">
        <span className="text-xs text-muted-foreground">#{index + 1}</span>
        <span className="text-sm font-semibold leading-tight">{event.start_time}</span>
        {event.end_time && <span className="text-xs text-muted-foreground">{event.end_time}</span>}
      </div>

      <div className="flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <h3 className="font-semibold">{event.title}</h3>
          <span className={cn('rounded-full px-2 py-0.5 text-xs font-medium', cat.chip)}>{label}</span>
        </div>
        {event.description && (
          <p className="mt-1 text-sm text-muted-foreground">{event.description}</p>
        )}
        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
          <span className="flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" /> {formatDate(event.event_date)}
          </span>
          {event.location && (
            <span className="flex items-center gap-1">
              <MapPin className="h-3.5 w-3.5" /> {event.location}
            </span>
          )}
          {event.responsible && (
            <span className="flex items-center gap-1">
              <User className="h-3.5 w-3.5" /> {event.responsible}
            </span>
          )}
        </div>
      </div>

      <div className="no-print flex flex-col gap-1">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => onEdit(event)}>
          <Pencil className="h-4 w-4" />
        </Button>
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 text-destructive"
          onClick={() => onDelete(event)}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

export function ItineraryPage() {
  const { eventId } = useEventContext();
  const { data: serverEvents = [], isLoading } = useItinerary(eventId);
  const reorder = useReorderEvents(eventId);
  const deleteEvent = useDeleteEvent(eventId);

  const [items, setItems] = useState<ItineraryEvent[]>([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<ItineraryEvent | null>(null);

  // Keep local order in sync with server (drag updates local immediately).
  useEffect(() => setItems(serverEvents), [serverEvents]);

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }));

  const handleDragEnd = (e: DragEndEvent) => {
    const { active, over } = e;
    if (!over || active.id === over.id) return;
    const oldIndex = items.findIndex((i) => i.id === active.id);
    const newIndex = items.findIndex((i) => i.id === over.id);
    const next = arrayMove(items, oldIndex, newIndex);
    setItems(next);
    reorder.mutate(next.map((it, idx) => ({ id: it.id, orderIndex: idx })));
  };

  const openCreate = () => {
    setEditing(null);
    setDialogOpen(true);
  };
  const openEdit = (ev: ItineraryEvent) => {
    setEditing(ev);
    setDialogOpen(true);
  };

  return (
    <div>
      <PageHeader
        title="Wedding Itinerary"
        description="Drag to reorder. Color-coded by category."
        actions={
          <>
            <Button variant="outline" onClick={() => window.print()}>
              <Printer className="h-4 w-4" /> Print / PDF
            </Button>
            <Button onClick={openCreate}>
              <Plus className="h-4 w-4" /> Add Event
            </Button>
          </>
        }
      />

      <div className="print-area space-y-3">
        <h2 className="hidden text-xl font-bold print:block">Wedding Itinerary</h2>
        {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
        {!isLoading && items.length === 0 && (
          <div className="rounded-lg border border-dashed p-10 text-center text-muted-foreground">
            No events yet. Click “Add Event” to start building your timeline.
          </div>
        )}

        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
          <SortableContext items={items.map((i) => i.id)} strategy={verticalListSortingStrategy}>
            <div className="space-y-3">
              {items.map((ev, idx) => (
                <SortableEvent
                  key={ev.id}
                  event={ev}
                  index={idx}
                  onEdit={openEdit}
                  onDelete={(e) => deleteEvent.mutate(e.id)}
                />
              ))}
            </div>
          </SortableContext>
        </DndContext>
      </div>

      <EventFormDialog eventId={eventId} open={dialogOpen} onOpenChange={setDialogOpen} event={editing} />
    </div>
  );
}
