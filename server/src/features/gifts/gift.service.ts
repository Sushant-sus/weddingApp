import { prisma } from '../../prisma/client.js';
import type { CreateGiftDto, QuickGiftDto, UpdateGiftDto } from './gift.schema.js';

export const giftService = {
  getAll: async (guestId?: string | null, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_gift_get_all: unknown }]>`
      SELECT wedding.sp_gift_get_all(${guestId ?? null}::UUID, ${eventId}::UUID)
    `;
    return result[0].sp_gift_get_all;
  },

  create: async (guestId: string, data: CreateGiftDto, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_gift_create: unknown }]>`
      SELECT wedding.sp_gift_create(
        ${guestId}::UUID,
        ${data.giftType}::TEXT,
        ${data.amount ?? null}::NUMERIC,
        ${data.description ?? null}::TEXT,
        ${data.receivedAt ?? new Date()}::TIMESTAMPTZ,
        ${data.remarks ?? null}::TEXT,
        ${eventId}::UUID
      )
    `;
    return result[0].sp_gift_create;
  },

  // Fast gift-desk entry: link to a guest or record a free-text giver name.
  quickCreate: async (eventId: string, data: QuickGiftDto) => {
    const result = await prisma.$queryRaw<[{ sp_gift_quick_create: unknown }]>`
      SELECT wedding.sp_gift_quick_create(
        ${eventId}::UUID,
        ${data.guestId ?? null}::UUID,
        ${data.giverName ?? null}::TEXT,
        ${data.giftType}::TEXT,
        ${data.amount ?? null}::NUMERIC,
        ${data.description ?? null}::TEXT,
        ${data.remarks ?? null}::TEXT
      )
    `;
    return result[0].sp_gift_quick_create;
  },

  update: async (id: string, data: UpdateGiftDto) => {
    const result = await prisma.$queryRaw<[{ sp_gift_update: unknown }]>`
      SELECT wedding.sp_gift_update(
        ${id}::UUID,
        ${data.giftType ?? null}::TEXT,
        ${data.amount ?? null}::NUMERIC,
        ${data.description ?? null}::TEXT,
        ${data.remarks ?? null}::TEXT
      )
    `;
    return result[0].sp_gift_update;
  },

  delete: async (id: string) => {
    const result = await prisma.$queryRaw<[{ sp_gift_delete: unknown }]>`
      SELECT wedding.sp_gift_delete(${id}::UUID)
    `;
    return result[0].sp_gift_delete;
  },

  getSummary: async (eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_gift_get_summary: unknown }]>`
      SELECT wedding.sp_gift_get_summary(${eventId}::UUID)
    `;
    return result[0].sp_gift_get_summary;
  },
};
