import { z } from 'zod';

export const giftTypeEnum = z.enum(['CASH', 'KIND']);

export const createGiftSchema = z
  .object({
    giftType: giftTypeEnum,
    amount: z.coerce.number().nonnegative().nullish(),
    description: z.string().nullish(),
    receivedAt: z.coerce.date().optional(),
    remarks: z.string().nullish(),
  })
  .refine((d) => (d.giftType === 'CASH' ? d.amount != null : true), {
    message: 'amount is required for CASH gifts',
    path: ['amount'],
  })
  .refine((d) => (d.giftType === 'KIND' ? !!d.description : true), {
    message: 'description is required for in-kind gifts',
    path: ['description'],
  });

export const updateGiftSchema = z.object({
  giftType: giftTypeEnum.optional(),
  amount: z.coerce.number().nonnegative().nullish(),
  description: z.string().nullish(),
  remarks: z.string().nullish(),
});

export const giftIdParamSchema = z.object({ id: z.string().uuid() });
export const guestIdParamSchema = z.object({ guestId: z.string().uuid() });

// Fast gift-desk entry: tie to an existing guest OR a free-text giver name.
export const quickGiftSchema = z
  .object({
    guestId: z.string().uuid().nullish(),
    giverName: z.string().min(1).nullish(),
    giftType: giftTypeEnum,
    amount: z.coerce.number().nonnegative().nullish(),
    description: z.string().nullish(),
    remarks: z.string().nullish(),
  })
  .refine((d) => !!d.guestId || !!d.giverName, {
    message: 'Either a guest or a giver name is required',
    path: ['giverName'],
  })
  .refine((d) => (d.giftType === 'CASH' ? d.amount != null : true), {
    message: 'amount is required for CASH gifts',
    path: ['amount'],
  })
  .refine((d) => (d.giftType === 'KIND' ? !!d.description : true), {
    message: 'description is required for in-kind gifts',
    path: ['description'],
  });

export type CreateGiftDto = z.infer<typeof createGiftSchema>;
export type UpdateGiftDto = z.infer<typeof updateGiftSchema>;
export type QuickGiftDto = z.infer<typeof quickGiftSchema>;
