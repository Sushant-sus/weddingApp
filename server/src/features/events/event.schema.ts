import { z } from 'zod';

export const eventRoleEnum = z.enum(['OWNER', 'LEADER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER']);

export const createEventSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  weddingDate: z.coerce.date(),
  venue: z.string().nullish(),
  description: z.string().nullish(),
});

export const updateEventSchema = z.object({
  name: z.string().min(2).optional(),
  weddingDate: z.coerce.date().optional(),
  venue: z.string().nullish(),
  description: z.string().nullish(),
});

export const inviteMemberSchema = z.object({
  email: z.string().email(),
  // OWNER cannot be assigned via invite.
  eventRole: z.enum(['LEADER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER']),
});

export const changeRoleSchema = z.object({
  eventRole: z.enum(['LEADER', 'EDITOR', 'CONTRIBUTOR', 'VIEWER']),
});

export const transferOwnershipSchema = z.object({
  newOwnerId: z.string().uuid(),
});

export const inviteTokenSchema = z.object({
  token: z.string().min(1),
});

export const eventIdParamSchema = z.object({ eventId: z.string().uuid() });
export const memberParamSchema = z.object({
  eventId: z.string().uuid(),
  userId: z.string().uuid(),
});

export type CreateEventDto = z.infer<typeof createEventSchema>;
export type UpdateEventDto = z.infer<typeof updateEventSchema>;
export type InviteMemberDto = z.infer<typeof inviteMemberSchema>;
