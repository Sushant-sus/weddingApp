import type { Request, Response } from 'express';
import { requestService } from './request.service.js';
import { providerService } from '../providers/provider.service.js';
import { sendSuccess } from '../../utils/response.js';
import { AppError } from '../../utils/AppError.js';
import type { CreatePitchDto, CreateRequestDto } from './request.schema.js';

// Event roles permitted to manage a request/booking (mirrors ROLE.EDIT on the
// event-scoped router). SUPERADMIN always passes.
const EDIT_ROLES = ['OWNER', 'LEADER', 'EDITOR'];
const isSuperadmin = (req: Request) => req.user?.role === 'SUPERADMIN';

function assertMember(role: string | null, req: Request) {
  if (isSuperadmin(req)) return;
  if (!role) throw new AppError(403, 'NOT_A_MEMBER', 'You are not a member of this event');
}
function assertCanEdit(role: string | null, req: Request) {
  if (isSuperadmin(req)) return;
  if (!role) throw new AppError(403, 'NOT_A_MEMBER', 'You are not a member of this event');
  if (!EDIT_ROLES.includes(role)) {
    throw new AppError(403, 'INSUFFICIENT_EVENT_ROLE', 'You do not have permission for this action');
  }
}

export const requestController = {
  // ---- Event-scoped (guarded upstream by requireEventRole) ----
  listForEvent: async (req: Request, res: Response) => {
    const data = await requestService.listForEvent(req.params.eventId);
    sendSuccess(res, data, 200, { total: Array.isArray(data) ? data.length : 0 });
  },

  itineraryServices: async (req: Request, res: Response) => {
    sendSuccess(res, await requestService.itineraryWithServices(req.params.eventId ?? null));
  },

  create: async (req: Request, res: Response) => {
    const data = await requestService.create(req.params.eventId, req.user!.userId, req.body as CreateRequestDto);
    sendSuccess(res, data, 201);
  },

  // ---- Request-scoped (top-level; authorize via the request's event role) ----
  getOne: async (req: Request, res: Response) => {
    const role = await requestService.eventRoleForRequest(req.params.id, req.user!.userId);
    assertMember(role, req);
    sendSuccess(res, await requestService.getById(req.params.id));
  },

  cancel: async (req: Request, res: Response) => {
    const role = await requestService.eventRoleForRequest(req.params.id, req.user!.userId);
    assertCanEdit(role, req);
    sendSuccess(res, await requestService.cancel(req.params.id));
  },

  listPitches: async (req: Request, res: Response) => {
    const role = await requestService.eventRoleForRequest(req.params.id, req.user!.userId);
    assertMember(role, req);
    sendSuccess(res, await requestService.listPitches(req.params.id));
  },

  // Provider submits a pitch — the provider identity is derived from the caller.
  createPitch: async (req: Request, res: Response) => {
    const provider = (await providerService.getByUser(req.user!.userId)) as { id: string } | null;
    if (!provider) throw new AppError(403, 'NOT_PROVIDER', 'Create a provider profile first');
    const data = await requestService.createPitch(req.params.id, provider.id, req.body as CreatePitchDto);
    sendSuccess(res, data, 201);
  },

  // ---- Pitch-scoped booking actions (host, EDIT role) ----
  bookPitch: async (req: Request, res: Response) => {
    const role = await requestService.eventRoleForPitch(req.params.id, req.user!.userId);
    assertCanEdit(role, req);
    sendSuccess(res, await requestService.bookPitch(req.params.id));
  },

  declinePitch: async (req: Request, res: Response) => {
    const role = await requestService.eventRoleForPitch(req.params.id, req.user!.userId);
    assertCanEdit(role, req);
    sendSuccess(res, await requestService.declinePitch(req.params.id));
  },
};
