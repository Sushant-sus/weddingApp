import { prisma } from '../../prisma/client.js';
import type { AddPortfolioDto, AddReviewDto, UpsertProviderDto } from './provider.schema.js';

export const providerService = {
  listCategories: async () => {
    const r = await prisma.$queryRaw<[{ sp_category_list: unknown }]>`
      SELECT wedding.sp_category_list()
    `;
    return r[0].sp_category_list;
  },

  list: async (category: string | null, search: string | null) => {
    const r = await prisma.$queryRaw<[{ sp_provider_list: unknown }]>`
      SELECT wedding.sp_provider_list(${category}::TEXT, ${search}::TEXT)
    `;
    return r[0].sp_provider_list;
  },

  getById: async (id: string) => {
    const r = await prisma.$queryRaw<[{ sp_provider_get_by_id: unknown }]>`
      SELECT wedding.sp_provider_get_by_id(${id}::UUID)
    `;
    return r[0].sp_provider_get_by_id;
  },

  getByUser: async (userId: string) => {
    const r = await prisma.$queryRaw<[{ sp_provider_get_by_user: unknown }]>`
      SELECT wedding.sp_provider_get_by_user(${userId}::UUID)
    `;
    return r[0].sp_provider_get_by_user; // null if the user has no provider profile
  },

  upsertMine: async (userId: string, data: UpsertProviderDto) => {
    const r = await prisma.$queryRaw<[{ sp_provider_upsert: unknown }]>`
      SELECT wedding.sp_provider_upsert(
        ${userId}::UUID,
        ${data.name}::TEXT,
        ${data.bio ?? null}::TEXT,
        ${data.categories}::TEXT[],
        ${data.basePrice ?? null}::NUMERIC,
        ${data.city ?? null}::TEXT,
        ${data.distanceKm ?? null}::NUMERIC
      )
    `;
    return r[0].sp_provider_upsert;
  },

  addPortfolio: async (providerId: string, data: AddPortfolioDto) => {
    const r = await prisma.$queryRaw<[{ sp_provider_portfolio_add: unknown }]>`
      SELECT wedding.sp_provider_portfolio_add(
        ${providerId}::UUID,
        ${data.imageUrl}::TEXT,
        ${data.caption ?? null}::TEXT,
        ${data.sortOrder}::INT
      )
    `;
    return r[0].sp_provider_portfolio_add;
  },

  addReview: async (providerId: string, authorUserId: string, authorName: string | null, data: AddReviewDto) => {
    const r = await prisma.$queryRaw<[{ sp_provider_review_add: unknown }]>`
      SELECT wedding.sp_provider_review_add(
        ${providerId}::UUID,
        ${authorUserId}::UUID,
        ${authorName}::TEXT,
        ${data.rating}::INT,
        ${data.body ?? null}::TEXT
      )
    `;
    return r[0].sp_provider_review_add;
  },

  dashboardFeed: async (providerId: string) => {
    const r = await prisma.$queryRaw<[{ sp_provider_dashboard_feed: unknown }]>`
      SELECT wedding.sp_provider_dashboard_feed(${providerId}::UUID)
    `;
    return r[0].sp_provider_dashboard_feed;
  },
};
