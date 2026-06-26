import type { Request, Response } from 'express';
import { giftService } from './gift.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CreateGiftDto, QuickGiftDto, UpdateGiftDto } from './gift.schema.js';

const eid = (req: Request) => req.params.eventId ?? null;

export const giftController = {
  list: async (req: Request, res: Response) => {
    const data = await giftService.getAll(null, eid(req));
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  listForGuest: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.getAll(req.params.guestId, eid(req)));
  },

  summary: async (_req: Request, res: Response) => {
    sendSuccess(res, await giftService.getSummary(eid(_req)));
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.create(req.params.guestId, req.body as CreateGiftDto, eid(req)), 201);
  },

  // Fast gift-desk entry (guest-linked or free-text giver).
  quickCreate: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.quickCreate(req.params.eventId, req.body as QuickGiftDto), 201);
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.update(req.params.id, req.body as UpdateGiftDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.delete(req.params.id));
  },
};
