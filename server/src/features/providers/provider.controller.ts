import type { Request, Response } from 'express';
import { providerService } from './provider.service.js';
import { sendSuccess } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import type { AddPortfolioDto, AddReviewDto, ProviderListQuery, UpsertProviderDto } from './provider.schema.js';

// Resolve the caller's provider profile or throw NOT_PROVIDER.
async function requireMyProvider(userId: string): Promise<{ id: string }> {
  const provider = (await providerService.getByUser(userId)) as { id: string } | null;
  if (!provider) {
    throw new AppError(403, 'NOT_PROVIDER', 'Create a provider profile first');
  }
  return provider;
}

export const providerController = {
  categories: async (_req: Request, res: Response) => {
    sendSuccess(res, await providerService.listCategories());
  },

  list: async (req: Request, res: Response) => {
    const { category, search } = req.query as ProviderListQuery;
    const data = await providerService.list(category ?? null, search ?? null);
    sendSuccess(res, data, 200, { total: Array.isArray(data) ? data.length : 0 });
  },

  getOne: async (req: Request, res: Response) => {
    sendSuccess(res, await providerService.getById(req.params.id));
  },

  me: async (req: Request, res: Response) => {
    // null when the user hasn't set up a provider profile yet.
    sendSuccess(res, await providerService.getByUser(req.user!.userId));
  },

  upsertMe: async (req: Request, res: Response) => {
    sendSuccess(res, await providerService.upsertMine(req.user!.userId, req.body as UpsertProviderDto));
  },

  dashboard: async (req: Request, res: Response) => {
    const provider = await requireMyProvider(req.user!.userId);
    sendSuccess(res, await providerService.dashboardFeed(provider.id));
  },

  addPortfolio: async (req: Request, res: Response) => {
    sendSuccess(res, await providerService.addPortfolio(req.params.id, req.body as AddPortfolioDto), 201);
  },

  addReview: async (req: Request, res: Response) => {
    sendSuccess(
      res,
      await providerService.addReview(req.params.id, req.user!.userId, null, req.body as AddReviewDto),
      201,
    );
  },
};
