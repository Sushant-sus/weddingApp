import { z } from 'zod';

export const createRequestSchema = z
  .object({
    category: z.string().min(1, 'Category is required'),
    title: z.string().min(1, 'Title is required'),
    itineraryItemId: z.string().uuid().nullish(),
    budgetMin: z.coerce.number().nonnegative().nullish(),
    budgetMax: z.coerce.number().nonnegative().nullish(),
    audience: z.enum(['BROADCAST', 'TARGETED']).default('BROADCAST'),
    targetProviderIds: z.array(z.string().uuid()).nullish(),
  })
  .refine(
    (v) => v.budgetMin == null || v.budgetMax == null || v.budgetMax >= v.budgetMin,
    { message: 'Max budget must be greater than or equal to min budget', path: ['budgetMax'] },
  );

export const createPitchSchema = z.object({
  price: z.coerce.number().nonnegative('Price is required'),
  message: z.string().nullish(),
  availableOnDate: z.coerce.boolean().default(true),
});

export const requestIdParamSchema = z.object({ id: z.string().uuid() });
export const pitchIdParamSchema = z.object({ id: z.string().uuid() });

export type CreateRequestDto = z.infer<typeof createRequestSchema>;
export type CreatePitchDto = z.infer<typeof createPitchSchema>;
