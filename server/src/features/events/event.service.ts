import { prisma } from '../../prisma/client.js';
import { sendEventInvite } from '../../lib/mailer.js';
import type { CreateEventDto, InviteMemberDto, UpdateEventDto } from './event.schema.js';

const toDateString = (d: Date) => d.toISOString().slice(0, 10);

const ROLE_DESCRIPTIONS: Record<string, string> = {
  LEADER: 'co-organizer with full edit + member management',
  EDITOR: 'full edit access to guests, gifts and itinerary',
  CONTRIBUTOR: 'can add guests and record gifts',
  VIEWER: 'read-only access',
};

export const eventService = {
  create: async (userId: string, data: CreateEventDto) => {
    const rows = await prisma.$queryRaw<[{ sp_event_create: unknown }]>`
      SELECT wedding.sp_event_create(
        ${userId}::UUID, ${data.name}::TEXT, ${toDateString(data.weddingDate)}::DATE,
        ${data.venue ?? null}::TEXT, ${data.description ?? null}::TEXT)
    `;
    return rows[0].sp_event_create;
  },

  listForUser: async (userId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_get_all_for_user: unknown }]>`
      SELECT wedding.sp_event_get_all_for_user(${userId}::UUID)
    `;
    return rows[0].sp_event_get_all_for_user;
  },

  getById: async (eventId: string, userId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_get_by_id: unknown }]>`
      SELECT wedding.sp_event_get_by_id(${eventId}::UUID, ${userId}::UUID)
    `;
    return rows[0].sp_event_get_by_id;
  },

  update: async (eventId: string, data: UpdateEventDto) => {
    const rows = await prisma.$queryRaw<[{ sp_event_update: unknown }]>`
      SELECT wedding.sp_event_update(
        ${eventId}::UUID, ${data.name ?? null}::TEXT,
        ${data.weddingDate ? toDateString(data.weddingDate) : null}::DATE,
        ${data.venue ?? null}::TEXT, ${data.description ?? null}::TEXT)
    `;
    return rows[0].sp_event_update;
  },

  remove: async (eventId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_delete: unknown }]>`
      SELECT wedding.sp_event_delete(${eventId}::UUID)
    `;
    return rows[0].sp_event_delete;
  },

  getMembers: async (eventId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_get_members: unknown }]>`
      SELECT wedding.sp_event_get_members(${eventId}::UUID)
    `;
    return rows[0].sp_event_get_members;
  },

  invite: async (eventId: string, inviterId: string, inviterName: string, data: InviteMemberDto) => {
    const rows = await prisma.$queryRaw<
      [{ sp_event_invite_member: { invite_token: string; invitee_email: string; event_role: string } }]
    >`SELECT wedding.sp_event_invite_member(
        ${eventId}::UUID, ${inviterId}::UUID, ${data.email}::TEXT, ${data.eventRole}::TEXT)`;
    const result = rows[0].sp_event_invite_member;

    // Fetch the event name/date for the email (best-effort).
    const ev = await prisma.$queryRaw<[{ name: string; wedding_date: string }]>`
      SELECT name, wedding_date FROM wedding.wedding_events WHERE id = ${eventId}::UUID
    `;
    await sendEventInvite({
      to: result.invitee_email,
      eventName: ev[0]?.name ?? 'a wedding',
      eventDate: ev[0]?.wedding_date ?? '',
      inviterName,
      role: result.event_role,
      roleDescription: ROLE_DESCRIPTIONS[result.event_role] ?? '',
      token: result.invite_token,
    });
    return { message: `Invite sent to ${result.invitee_email}`, ...result };
  },

  acceptInvite: async (userId: string, token: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_accept_invite: unknown }]>`
      SELECT wedding.sp_event_accept_invite(${userId}::UUID, ${token}::TEXT)
    `;
    return rows[0].sp_event_accept_invite;
  },

  declineInvite: async (userId: string, token: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_decline_invite: unknown }]>`
      SELECT wedding.sp_event_decline_invite(${userId}::UUID, ${token}::TEXT)
    `;
    return rows[0].sp_event_decline_invite;
  },

  changeMemberRole: async (eventId: string, changerId: string, targetUserId: string, newRole: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_change_member_role: unknown }]>`
      SELECT wedding.sp_event_change_member_role(
        ${eventId}::UUID, ${changerId}::UUID, ${targetUserId}::UUID, ${newRole}::TEXT)
    `;
    return rows[0].sp_event_change_member_role;
  },

  removeMember: async (eventId: string, removerId: string, targetUserId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_remove_member: unknown }]>`
      SELECT wedding.sp_event_remove_member(${eventId}::UUID, ${removerId}::UUID, ${targetUserId}::UUID)
    `;
    return rows[0].sp_event_remove_member;
  },

  transferOwnership: async (eventId: string, currentOwnerId: string, newOwnerId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_event_transfer_ownership: unknown }]>`
      SELECT wedding.sp_event_transfer_ownership(${eventId}::UUID, ${currentOwnerId}::UUID, ${newOwnerId}::UUID)
    `;
    return rows[0].sp_event_transfer_ownership;
  },

  getActivity: async (eventId: string, limit = 50) => {
    const rows = await prisma.$queryRaw<[{ sp_event_get_activity_log: unknown }]>`
      SELECT wedding.sp_event_get_activity_log(${eventId}::UUID, ${limit}::INT)
    `;
    return rows[0].sp_event_get_activity_log;
  },
};
