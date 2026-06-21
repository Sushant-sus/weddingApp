import { z } from 'zod';

export const familyTypeEnum = z.enum(['CHULEY', 'SINGLE']);
export const sideEnum = z.enum(['BRIDE', 'GROOM', 'BOTH']);
export const rsvpStatusEnum = z.enum(['PENDING', 'CONFIRMED', 'DECLINED']);

export const guestFiltersSchema = z.object({
  familyType: familyTypeEnum.optional(),
  rsvpStatus: rsvpStatusEnum.optional(),
  side: sideEnum.optional(),
});

export const createGuestSchema = z.object({
  familyName: z.string().min(1, 'Family name is required'),
  familyType: familyTypeEnum,
  side: sideEnum,
  attendeeCount: z.coerce.number().int().min(0).default(0),
  contactPhone: z.string().nullish(),
  address: z.string().nullish(),
  remarks: z.string().nullish(),
});

export const updateGuestSchema = z.object({
  familyName: z.string().min(1).optional(),
  familyType: familyTypeEnum.optional(),
  side: sideEnum.optional(),
  attendeeCount: z.coerce.number().int().min(0).nullish(),
  confirmedCount: z.coerce.number().int().min(0).nullish(),
  contactPhone: z.string().nullish(),
  address: z.string().nullish(),
  remarks: z.string().nullish(),
  rsvpStatus: rsvpStatusEnum.optional(),
});

// Each row in the batch must carry an id; the rest is the partial update.
export const batchUpdateSchema = z.object({
  updates: z
    .array(updateGuestSchema.extend({ id: z.string().uuid() }))
    .min(1, 'At least one row is required'),
});

export const idParamSchema = z.object({ id: z.string().uuid() });

export type GuestFilters = z.infer<typeof guestFiltersSchema>;
export type CreateGuestDto = z.infer<typeof createGuestSchema>;
export type UpdateGuestDto = z.infer<typeof updateGuestSchema>;
export type BatchUpdateDto = z.infer<typeof batchUpdateSchema>;
