import type { Request, Response } from 'express';
import { itineraryService } from './itinerary.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CreateEventDto, ReorderDto, SetStatusDto, UpdateEventDto } from './itinerary.schema.js';

const eid = (req: Request) => req.params.eventId ?? null;

export const itineraryController = {
  list: async (req: Request, res: Response) => {
    const data = await itineraryService.getAll(eid(req));
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.create(req.body as CreateEventDto, eid(req)), 201);
  },

  reorder: async (req: Request, res: Response) => {
    const { order } = req.body as ReorderDto;
    sendSuccess(res, await itineraryService.reorder(order));
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.update(req.params.id, req.body as UpdateEventDto));
  },

  setStatus: async (req: Request, res: Response) => {
    const { status } = req.body as SetStatusDto;
    sendSuccess(res, await itineraryService.setStatus(req.params.id, status));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await itineraryService.delete(req.params.id));
  },
};
