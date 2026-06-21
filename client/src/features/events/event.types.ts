export type EventRole = 'OWNER' | 'LEADER' | 'EDITOR' | 'CONTRIBUTOR' | 'VIEWER';

export interface WeddingEvent {
  id: string;
  name: string;
  wedding_date: string;
  venue: string | null;
  description: string | null;
  created_by?: string;
  is_active: boolean;
  created_at: string;
  my_role: EventRole;
  invite_status?: string;
  member_count: number;
  guest_count?: number;
}

export interface EventMember {
  id: string;
  event_role: EventRole;
  invite_status: 'PENDING' | 'ACCEPTED' | 'DECLINED';
  joined_at: string | null;
  user_id: string;
  full_name: string;
  email: string;
  invited_by_name: string | null;
}

export interface ActivityEntry {
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  full_name: string;
  email: string;
}

export interface CreateEventPayload {
  name: string;
  weddingDate: string;
  venue?: string | null;
  description?: string | null;
}

export const EVENT_ROLE_OPTIONS = [
  { label: 'Leader', value: 'LEADER' },
  { label: 'Editor', value: 'EDITOR' },
  { label: 'Contributor', value: 'CONTRIBUTOR' },
  { label: 'Viewer', value: 'VIEWER' },
];

export const ROLE_RANK: Record<EventRole, number> = {
  OWNER: 5,
  LEADER: 4,
  EDITOR: 3,
  CONTRIBUTOR: 2,
  VIEWER: 1,
};
