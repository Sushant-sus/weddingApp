import type { Request, Response } from 'express';
import { costService } from './cost.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CostFilters, CreateCostDto, UpdateCostDto } from './cost.schema.js';

const eid = (req: Request) => req.params.eventId ?? null;

export const costController = {
  list: async (req: Request, res: Response) => {
    const data = await costService.getAll(req.query as CostFilters, eid(req));
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  summary: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.getSummary(eid(req)));
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.create(req.body as CreateCostDto, eid(req)), 201);
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.update(req.params.id, req.body as UpdateCostDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.delete(req.params.id));
  },
};
