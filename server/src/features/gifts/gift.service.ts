import { prisma } from '../../prisma/client.js';
import type { CreateGiftDto, UpdateGiftDto } from './gift.schema.js';

export const giftService = {
  getAll: async (guestId?: string) => {
    const result = await prisma.$queryRaw<[{ sp_gift_get_all: unknown }]>`
      SELECT wedding.sp_gift_get_all(${guestId ?? null}::UUID)
    `;
    return result[0].sp_gift_get_all;
  },

  create: async (guestId: string, data: CreateGiftDto) => {
    const result = await prisma.$queryRaw<[{ sp_gift_create: unknown }]>`
      SELECT wedding.sp_gift_create(
        ${guestId}::UUID,
        ${data.giftType}::TEXT,
        ${data.amount ?? null}::NUMERIC,
        ${data.description ?? null}::TEXT,
        ${data.receivedAt ?? new Date()}::TIMESTAMPTZ,
        ${data.remarks ?? null}::TEXT
      )
    `;
    return result[0].sp_gift_create;
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

  getSummary: async () => {
    const result = await prisma.$queryRaw<[{ sp_gift_get_summary: unknown }]>`
      SELECT wedding.sp_gift_get_summary()
    `;
    return result[0].sp_gift_get_summary;
  },
};
