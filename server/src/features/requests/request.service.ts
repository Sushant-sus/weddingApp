import { prisma } from '../../prisma/client.js';
import type { CreatePitchDto, CreateRequestDto } from './request.schema.js';

export const requestService = {
  listForEvent: async (eventId: string) => {
    const r = await prisma.$queryRaw<[{ sp_service_request_list_for_event: unknown }]>`
      SELECT wedding.sp_service_request_list_for_event(${eventId}::UUID)
    `;
    return r[0].sp_service_request_list_for_event;
  },

  itineraryWithServices: async (eventId: string | null) => {
    const r = await prisma.$queryRaw<[{ sp_itinerary_with_services: unknown }]>`
      SELECT wedding.sp_itinerary_with_services(${eventId}::UUID)
    `;
    return r[0].sp_itinerary_with_services;
  },

  create: async (eventId: string, createdBy: string, data: CreateRequestDto) => {
    const targets =
      data.audience === 'TARGETED' && data.targetProviderIds?.length ? data.targetProviderIds : null;
    const r = await prisma.$queryRaw<[{ sp_service_request_create: unknown }]>`
      SELECT wedding.sp_service_request_create(
        ${eventId}::UUID,
        ${data.category}::TEXT,
        ${data.title}::TEXT,
        ${createdBy}::UUID,
        ${data.itineraryItemId ?? null}::UUID,
        ${data.budgetMin ?? null}::NUMERIC,
        ${data.budgetMax ?? null}::NUMERIC,
        ${data.audience}::TEXT,
        ${targets}::UUID[]
      )
    `;
    return r[0].sp_service_request_create;
  },

  getById: async (id: string) => {
    const r = await prisma.$queryRaw<[{ sp_service_request_get_by_id: unknown }]>`
      SELECT wedding.sp_service_request_get_by_id(${id}::UUID)
    `;
    return r[0].sp_service_request_get_by_id;
  },

  cancel: async (id: string) => {
    const r = await prisma.$queryRaw<[{ sp_service_request_cancel: unknown }]>`
      SELECT wedding.sp_service_request_cancel(${id}::UUID)
    `;
    return r[0].sp_service_request_cancel;
  },

  // Authorization helpers — return the caller's event role (or null) for the resource.
  eventRoleForRequest: async (requestId: string, userId: string) => {
    const r = await prisma.$queryRaw<[{ sp_request_event_role: string | null }]>`
      SELECT wedding.sp_request_event_role(${requestId}::UUID, ${userId}::UUID)
    `;
    return r[0].sp_request_event_role;
  },

  eventRoleForPitch: async (pitchId: string, userId: string) => {
    const r = await prisma.$queryRaw<[{ sp_pitch_event_role: string | null }]>`
      SELECT wedding.sp_pitch_event_role(${pitchId}::UUID, ${userId}::UUID)
    `;
    return r[0].sp_pitch_event_role;
  },

  listPitches: async (requestId: string) => {
    const r = await prisma.$queryRaw<[{ sp_pitch_list_for_request: unknown }]>`
      SELECT wedding.sp_pitch_list_for_request(${requestId}::UUID)
    `;
    return r[0].sp_pitch_list_for_request;
  },

  createPitch: async (requestId: string, providerId: string, data: CreatePitchDto) => {
    const r = await prisma.$queryRaw<[{ sp_pitch_create: unknown }]>`
      SELECT wedding.sp_pitch_create(
        ${requestId}::UUID,
        ${providerId}::UUID,
        ${data.price}::NUMERIC,
        ${data.message ?? null}::TEXT,
        ${data.availableOnDate}::BOOLEAN
      )
    `;
    return r[0].sp_pitch_create;
  },

  bookPitch: async (pitchId: string) => {
    const r = await prisma.$queryRaw<[{ sp_pitch_book: unknown }]>`
      SELECT wedding.sp_pitch_book(${pitchId}::UUID)
    `;
    return r[0].sp_pitch_book;
  },

  declinePitch: async (pitchId: string) => {
    const r = await prisma.$queryRaw<[{ sp_pitch_decline: unknown }]>`
      SELECT wedding.sp_pitch_decline(${pitchId}::UUID)
    `;
    return r[0].sp_pitch_decline;
  },
};
