import type { Request, Response } from 'express';
import { itineraryService } from './itinerary.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CreateEventDto, ReorderDto, UpdateEventDto } from './itinerary.schema.js';

export const itineraryController = {
  list: async (_req: Request, res: Response) => {
    const data = await itineraryService.getAll();
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.create(req.body as CreateEventDto), 201);
  },

  reorder: async (req: Request, res: Response) => {
    const { order } = req.body as ReorderDto;
    sendSuccess(res, await itineraryService.reorder(order));
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.update(req.params.id, req.body as UpdateEventDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.delete(req.params.id));
  },
};
