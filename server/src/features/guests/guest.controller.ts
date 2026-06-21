import type { Request, Response } from 'express';
import { guestService } from './guest.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { BatchUpdateDto, CreateGuestDto, GuestFilters, UpdateGuestDto } from './guest.schema.js';

export const guestController = {
  list: async (req: Request, res: Response) => {
    const data = await guestService.getAll(req.query as GuestFilters);
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  summary: async (_req: Request, res: Response) => {
    sendSuccess(res, await guestService.getSummary());
  },

  getOne: async (req: Request, res: Response) => {
    sendSuccess(res, await guestService.getById(req.params.id));
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await guestService.create(req.body as CreateGuestDto), 201);
  },

  batchUpdate: async (req: Request, res: Response) => {
    const { updates } = req.body as BatchUpdateDto;
    sendSuccess(res, await guestService.batchUpdate(updates));
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await guestService.update(req.params.id, req.body as UpdateGuestDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await guestService.delete(req.params.id));
  },
};
