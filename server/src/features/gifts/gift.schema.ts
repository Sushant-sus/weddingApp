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

export type CreateGiftDto = z.infer<typeof createGiftSchema>;
export type UpdateGiftDto = z.infer<typeof updateGiftSchema>;
