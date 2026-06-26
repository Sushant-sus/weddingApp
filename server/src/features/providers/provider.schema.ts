import { z } from 'zod';

export const providerListQuerySchema = z.object({
  category: z.string().min(1).optional(),
  search: z.string().min(1).optional(),
});

export const upsertProviderSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  bio: z.string().nullish(),
  categories: z.array(z.string().min(1)).default([]),
  basePrice: z.coerce.number().nonnegative().nullish(),
  city: z.string().nullish(),
  distanceKm: z.coerce.number().nonnegative().nullish(),
});

export const providerIdParamSchema = z.object({ id: z.string().uuid() });

export const addPortfolioSchema = z.object({
  imageUrl: z.string().min(1, 'Image URL is required'),
  caption: z.string().nullish(),
  sortOrder: z.coerce.number().int().default(0),
});

export const addReviewSchema = z.object({
  rating: z.coerce.number().int().min(1).max(5),
  body: z.string().nullish(),
});

export type ProviderListQuery = z.infer<typeof providerListQuerySchema>;
export type UpsertProviderDto = z.infer<typeof upsertProviderSchema>;
export type AddPortfolioDto = z.infer<typeof addPortfolioSchema>;
export type AddReviewDto = z.infer<typeof addReviewSchema>;
