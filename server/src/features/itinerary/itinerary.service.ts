import { prisma } from '../../prisma/client.js';
import type { CreateEventDto, ReorderDto, UpdateEventDto } from './itinerary.schema.js';

const toDateString = (d: Date) => d.toISOString().slice(0, 10); // YYYY-MM-DD

export const itineraryService = {
  getAll: async (eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_itinerary_get_all: unknown }]>`
      SELECT wedding.sp_itinerary_get_all(${eventId}::UUID)
    `;
    return result[0].sp_itinerary_get_all;
  },

  create: async (data: CreateEventDto, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_itinerary_create: unknown }]>`
      SELECT wedding.sp_itinerary_create(
        ${data.title}::TEXT,
        ${toDateString(data.eventDate)}::DATE,
        ${data.startTime}::TEXT,
        ${data.description ?? null}::TEXT,
        ${data.endTime ?? null}::TEXT,
        ${data.location ?? null}::TEXT,
        ${data.responsible ?? null}::TEXT,
        ${data.category}::TEXT,
        ${data.orderIndex ?? null}::INT,
        ${eventId}::UUID
      )
    `;
    return result[0].sp_itinerary_create;
  },

  update: async (id: string, data: UpdateEventDto) => {
    const result = await prisma.$queryRaw<[{ sp_itinerary_update: unknown }]>`
      SELECT wedding.sp_itinerary_update(
        ${id}::UUID,
        ${data.title ?? null}::TEXT,
        ${data.description ?? null}::TEXT,
        ${data.eventDate ? toDateString(data.eventDate) : null}::DATE,
        ${data.startTime ?? null}::TEXT,
        ${data.endTime ?? null}::TEXT,
        ${data.location ?? null}::TEXT,
        ${data.responsible ?? null}::TEXT,
        ${data.category ?? null}::TEXT,
        ${data.orderIndex ?? null}::INT
      )
    `;
    return result[0].sp_itinerary_update;
  },

  reorder: async (order: ReorderDto['order']) => {
    const result = await prisma.$queryRaw<[{ sp_itinerary_reorder: unknown }]>`
      SELECT wedding.sp_itinerary_reorder(${JSON.stringify(order)}::JSONB)
    `;
    return result[0].sp_itinerary_reorder;
  },

  delete: async (id: string) => {
    const result = await prisma.$queryRaw<[{ sp_itinerary_delete: unknown }]>`
      SELECT wedding.sp_itinerary_delete(${id}::UUID)
    `;
    return result[0].sp_itinerary_delete;
  },
};
