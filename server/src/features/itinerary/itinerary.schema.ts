import { z } from 'zod';

export const eventCategoryEnum = z.enum([
  'CEREMONY',
  'RECEPTION',
  'RITUAL',
  'MEAL',
  'ENTERTAINMENT',
  'OTHER',
]);

export const createEventSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().nullish(),
  eventDate: z.coerce.date(),
  startTime: z.string().min(1, 'Start time is required'),
  endTime: z.string().nullish(),
  location: z.string().nullish(),
  responsible: z.string().nullish(),
  category: eventCategoryEnum.default('OTHER'),
  orderIndex: z.coerce.number().int().nullish(),
});

export const updateEventSchema = z.object({
  title: z.string().min(1).optional(),
  description: z.string().nullish(),
  eventDate: z.coerce.date().optional(),
  startTime: z.string().min(1).optional(),
  endTime: z.string().nullish(),
  location: z.string().nullish(),
  responsible: z.string().nullish(),
  category: eventCategoryEnum.optional(),
  orderIndex: z.coerce.number().int().nullish(),
});

export const reorderSchema = z.object({
  order: z
    .array(z.object({ id: z.string().uuid(), orderIndex: z.coerce.number().int() }))
    .min(1, 'At least one item is required'),
});

export const eventIdParamSchema = z.object({ id: z.string().uuid() });

export type CreateEventDto = z.infer<typeof createEventSchema>;
export type UpdateEventDto = z.infer<typeof updateEventSchema>;
export type ReorderDto = z.infer<typeof reorderSchema>;
