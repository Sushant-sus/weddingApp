import { z } from 'zod';

export const paymentStatusEnum = z.enum(['UNPAID', 'PARTIAL', 'PAID']);

export const costFiltersSchema = z.object({
  category: z.string().optional(),
});

export const createCostSchema = z.object({
  category: z.string().min(1, 'Category is required'),
  itemName: z.string().min(1, 'Item name is required'),
  estimatedCost: z.coerce.number().nonnegative(),
  actualCost: z.coerce.number().nonnegative().nullish(),
  vendor: z.string().nullish(),
  paymentStatus: paymentStatusEnum.optional(),
  notes: z.string().nullish(),
});

export const updateCostSchema = z.object({
  category: z.string().min(1).optional(),
  itemName: z.string().min(1).optional(),
  estimatedCost: z.coerce.number().nonnegative().nullish(),
  actualCost: z.coerce.number().nonnegative().nullish(),
  vendor: z.string().nullish(),
  paymentStatus: paymentStatusEnum.optional(),
  notes: z.string().nullish(),
});

export const costIdParamSchema = z.object({ id: z.string().uuid() });

export type CostFilters = z.infer<typeof costFiltersSchema>;
export type CreateCostDto = z.infer<typeof createCostSchema>;
export type UpdateCostDto = z.infer<typeof updateCostSchema>;
