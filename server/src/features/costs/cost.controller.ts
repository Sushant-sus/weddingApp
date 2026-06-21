import type { Request, Response } from 'express';
import { costService } from './cost.service.js';
import { sendSuccess } from '../../utils/response.js';
import type { CostFilters, CreateCostDto, UpdateCostDto } from './cost.schema.js';

export const costController = {
  list: async (req: Request, res: Response) => {
    const data = await costService.getAll(req.query as CostFilters);
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  summary: async (_req: Request, res: Response) => {
    sendSuccess(res, await costService.getSummary());
  },

  create: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.create(req.body as CreateCostDto), 201);
  },

  update: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.update(req.params.id, req.body as UpdateCostDto));
  },

  remove: async (req: Request, res: Response) => {
    sendSuccess(res, await costService.delete(req.params.id));
  },
};
