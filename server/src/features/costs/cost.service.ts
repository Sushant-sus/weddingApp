import { prisma } from '../../prisma/client.js';
import type { CostFilters, CreateCostDto, UpdateCostDto } from './cost.schema.js';

export const costService = {
  getAll: async (filters: CostFilters, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_cost_get_all: unknown }]>`
      SELECT wedding.sp_cost_get_all(${filters.category ?? null}::TEXT, ${eventId}::UUID)
    `;
    return result[0].sp_cost_get_all;
  },

  create: async (data: CreateCostDto, eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_cost_create: unknown }]>`
      SELECT wedding.sp_cost_create(
        ${data.category}::TEXT,
        ${data.itemName}::TEXT,
        ${data.estimatedCost}::NUMERIC,
        ${data.actualCost ?? null}::NUMERIC,
        ${data.vendor ?? null}::TEXT,
        ${data.paymentStatus ?? null}::TEXT,
        ${data.notes ?? null}::TEXT,
        ${eventId}::UUID
      )
    `;
    return result[0].sp_cost_create;
  },

  update: async (id: string, data: UpdateCostDto) => {
    const result = await prisma.$queryRaw<[{ sp_cost_update: unknown }]>`
      SELECT wedding.sp_cost_update(
        ${id}::UUID,
        ${data.category ?? null}::TEXT,
        ${data.itemName ?? null}::TEXT,
        ${data.estimatedCost ?? null}::NUMERIC,
        ${data.actualCost ?? null}::NUMERIC,
        ${data.vendor ?? null}::TEXT,
        ${data.paymentStatus ?? null}::TEXT,
        ${data.notes ?? null}::TEXT
      )
    `;
    return result[0].sp_cost_update;
  },

  delete: async (id: string) => {
    const result = await prisma.$queryRaw<[{ sp_cost_delete: unknown }]>`
      SELECT wedding.sp_cost_delete(${id}::UUID)
    `;
    return result[0].sp_cost_delete;
  },

  getSummary: async (eventId: string | null = null) => {
    const result = await prisma.$queryRaw<[{ sp_cost_get_summary: unknown }]>`
      SELECT wedding.sp_cost_get_summary(${eventId}::UUID)
    `;
    return result[0].sp_cost_get_summary;
  },
};
