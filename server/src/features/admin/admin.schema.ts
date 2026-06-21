import { z } from 'zod';

export const userFiltersSchema = z.object({
  role: z.string().optional(),
  isActive: z
    .union([z.literal('true'), z.literal('false')])
    .transform((v) => v === 'true')
    .optional(),
});

export const assignRoleSchema = z.object({
  roleId: z.string().uuid(),
});

export const userIdParamSchema = z.object({ id: z.string().uuid() });
