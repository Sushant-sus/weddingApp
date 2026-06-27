import type { Request, Response } from 'express';
import { eventService } from './event.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CreateEventDto, InviteMemberDto, UpdateEventDto } from './event.schema.js';

export const eventController = {
  create: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.create(req.user!.userId, req.body as CreateEventDto), 201);
  },

  list: async (req: Request, res: Response) => {
    const data = await eventService.listForUser(req.user!.userId);
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  getOne: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.getById(req.params.eventId, req.user!.userId));
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.update(req.params.eventId, req.body as UpdateEventDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.remove(req.params.eventId));
  },

  members: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.getMembers(req.params.eventId));
  },

  invite: async (req: Request, res: Response) => {
    const data = await eventService.invite(
      req.params.eventId,
      req.user!.userId,
      req.user!.email,
      req.body as InviteMemberDto,
    );
    sendSuccess(res, data, 201);
  },

  changeRole: async (req: Request, res: Response) => {
    sendSuccess(
      res,
      await eventService.changeMemberRole(
        req.params.eventId,
        req.user!.userId,
        req.params.userId,
        req.body.eventRole,
      ),
    );
  },

  removeMember: async (req: Request, res: Response) => {
    sendSuccess(
      res,
      await eventService.removeMember(req.params.eventId, req.user!.userId, req.params.userId),
    );
  },

  transferOwnership: async (req: Request, res: Response) => {
    sendSuccess(
      res,
      await eventService.transferOwnership(req.params.eventId, req.user!.userId, req.body.newOwnerId),
    );
  },

  acceptInvite: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.acceptInvite(req.user!.userId, req.body.token));
  },

  declineInvite: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.declineInvite(req.user!.userId, req.body.token));
  },

  acceptInviteByEvent: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.acceptInviteByEvent(req.user!.userId, req.params.eventId));
  },

  declineInviteByEvent: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.declineInviteByEvent(req.user!.userId, req.params.eventId));
  },

  activity: async (req: Request, res: Response) => {
    sendSuccess(res, await eventService.getActivity(req.params.eventId));
  },
};
