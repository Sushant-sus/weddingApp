export type EventCategory =
  | 'CEREMONY'
  | 'RECEPTION'
  | 'RITUAL'
  | 'MEAL'
  | 'ENTERTAINMENT'
  | 'OTHER';

export interface ItineraryEvent {
  id: string;
  title: string;
  description: string | null;
  event_date: string;
  start_time: string;
  end_time: string | null;
  location: string | null;
  responsible: string | null;
  category: EventCategory;
  order_index: number;
  created_at: string;
  updated_at: string;
}

export interface EventPayload {
  title: string;
  description?: string | null;
  eventDate: string;
  startTime: string;
  endTime?: string | null;
  location?: string | null;
  responsible?: string | null;
  category: EventCategory;
}

export const CATEGORY_OPTIONS = [
  { label: 'Ceremony', value: 'CEREMONY' },
  { label: 'Reception', value: 'RECEPTION' },
  { label: 'Ritual', value: 'RITUAL' },
  { label: 'Meal', value: 'MEAL' },
  { label: 'Entertainment', value: 'ENTERTAINMENT' },
  { label: 'Other', value: 'OTHER' },
];

// Color coding per category (Tailwind classes).
export const CATEGORY_STYLES: Record<EventCategory, { dot: string; chip: string; border: string }> = {
  CEREMONY: { dot: 'bg-amber-500', chip: 'bg-amber-100 text-amber-800', border: 'border-l-amber-500' },
  RECEPTION: { dot: 'bg-rose-500', chip: 'bg-rose-100 text-rose-800', border: 'border-l-rose-500' },
  RITUAL: { dot: 'bg-orange-500', chip: 'bg-orange-100 text-orange-800', border: 'border-l-orange-500' },
  MEAL: { dot: 'bg-emerald-500', chip: 'bg-emerald-100 text-emerald-800', border: 'border-l-emerald-500' },
  ENTERTAINMENT: { dot: 'bg-purple-500', chip: 'bg-purple-100 text-purple-800', border: 'border-l-purple-500' },
  OTHER: { dot: 'bg-slate-400', chip: 'bg-slate-100 text-slate-700', border: 'border-l-slate-400' },
};
