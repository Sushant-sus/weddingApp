import { prisma } from '../../prisma/client.js';
import type { CreateGuestDto, GuestFilters, UpdateGuestDto } from './guest.schema.js';

// All methods call PostgreSQL stored procedures via $queryRaw — never prisma.model.*.
export const guestService = {
  getAll: async (filters: GuestFilters, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_guest_get_all: unknown }]>`
      SELECT wedding.sp_guest_get_all(
        ${filters.familyType ?? null}::TEXT,
        ${filters.rsvpStatus ?? null}::TEXT,
        ${filters.side ?? null}::TEXT,
        ${eventId}::UUID
      )
    `;
    return result[0].sp_guest_get_all;
  },

  getById: async (id: string) => {
    const result = await prisma.$queryRaw<[{ sp_guest_get_by_id: unknown }]>`
      SELECT wedding.sp_guest_get_by_id(${id}::UUID)
    `;
    return result[0].sp_guest_get_by_id;
  },

  create: async (data: CreateGuestDto, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_guest_create: unknown }]>`
      SELECT wedding.sp_guest_create(
        ${data.familyName}::TEXT,
        ${data.familyType}::TEXT,
        ${data.side}::TEXT,
        ${data.attendeeCount}::INT,
        ${data.contactPhone ?? null}::TEXT,
        ${data.address ?? null}::TEXT,
        ${data.remarks ?? null}::TEXT,
        ${eventId}::UUID
      )
    `;
    return result[0].sp_guest_create;
  },

  update: async (id: string, data: UpdateGuestDto) => {
    const result = await prisma.$queryRaw<[{ sp_guest_update: unknown }]>`
      SELECT wedding.sp_guest_update(
        ${id}::UUID,
        ${data.familyName ?? null}::TEXT,
        ${data.familyType ?? null}::TEXT,
        ${data.side ?? null}::TEXT,
        ${data.attendeeCount ?? null}::INT,
        ${data.confirmedCount ?? null}::INT,
        ${data.contactPhone ?? null}::TEXT,
        ${data.address ?? null}::TEXT,
        ${data.remarks ?? null}::TEXT,
        ${data.rsvpStatus ?? null}::TEXT
      )
    `;
    return result[0].sp_guest_update;
  },

  batchUpdate: async (updates: (UpdateGuestDto & { id: string })[]) => {
    const result = await prisma.$queryRaw<[{ sp_guest_batch_update: unknown }]>`
      SELECT wedding.sp_guest_batch_update(${JSON.stringify(updates)}::JSONB)
    `;
    return result[0].sp_guest_batch_update;
  },

  delete: async (id: string) => {
    const result = await prisma.$queryRaw<[{ sp_guest_delete: unknown }]>`
      SELECT wedding.sp_guest_delete(${id}::UUID)
    `;
    return result[0].sp_guest_delete;
  },

  getSummary: async (eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_guest_get_summary: unknown }]>`
      SELECT wedding.sp_guest_get_summary(${eventId}::UUID)
    `;
    return result[0].sp_guest_get_summary;
  },
};
