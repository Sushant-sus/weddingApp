import type { Request, Response } from 'express';
import { giftService } from './gift.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CreateGiftDto, UpdateGiftDto } from './gift.schema.js';

export const giftController = {
  list: async (req: Request, res: Response) => {
    const data = await giftService.getAll();
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  listForGuest: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.getAll(req.params.guestId));
  },

  summary: async (_req: Request, res: Response) => {
    sendSuccess(res, await giftService.getSummary());
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.create(req.params.guestId, req.body as CreateGiftDto), 201);
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.update(req.params.id, req.body as UpdateGiftDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await giftService.delete(req.params.id));
  },
};
