export type FamilyType = 'CHULEY' | 'SINGLE';
export type Side = 'BRIDE' | 'GROOM' | 'BOTH';
export type RsvpStatus = 'PENDING' | 'CONFIRMED' | 'DECLINED';

export interface Guest {
  id: string;
  family_name: string;
  family_type: FamilyType;
  side: Side;
  attendee_count: number;
  confirmed_count: number | null;
  contact_phone: string | null;
  address: string | null;
  remarks: string | null;
  rsvp_status: RsvpStatus;
  created_at: string;
  updated_at: string;
}

export interface GuestSummary {
  total_families: number;
  total_estimated_attendees: number;
  total_confirmed_attendees: number;
  chuley_count: number;
  single_count: number;
  rsvp_confirmed: number;
  rsvp_declined: number;
  rsvp_pending: number;
}

// camelCase payload the API expects when writing.
export interface GuestUpdatePayload {
  id: string;
  familyName?: string;
  familyType?: FamilyType;
  side?: Side;
  attendeeCount?: number | null;
  confirmedCount?: number | null;
  contactPhone?: string | null;
  remarks?: string | null;
  rsvpStatus?: RsvpStatus;
}

export interface GuestCreatePayload {
  familyName: string;
  familyType: FamilyType;
  side: Side;
  attendeeCount: number;
  contactPhone?: string | null;
  address?: string | null;
  remarks?: string | null;
}

export interface GuestFilters {
  familyType?: FamilyType;
  rsvpStatus?: RsvpStatus;
  side?: Side;
}

export const FAMILY_TYPE_OPTIONS = [
  { label: 'Chuley', value: 'CHULEY' },
  { label: 'Single', value: 'SINGLE' },
];
export const SIDE_OPTIONS = [
  { label: 'Bride', value: 'BRIDE' },
  { label: 'Groom', value: 'GROOM' },
  { label: 'Both', value: 'BOTH' },
];
export const RSVP_OPTIONS = [
  { label: 'Pending', value: 'PENDING' },
  { label: 'Confirmed', value: 'CONFIRMED' },
  { label: 'Declined', value: 'DECLINED' },
];
