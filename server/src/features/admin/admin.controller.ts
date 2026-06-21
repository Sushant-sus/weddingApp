import type { Request, Response } from 'express';
import { adminService } from './admin.service.js';
import { sendSuccess } from '../../utils/response.js';

export const adminController = {
  listUsers: async (req: Request, res: Response) => {
    const { role, isActive } = req.query as { role?: string; isActive?: boolean };
    const data = await adminService.getUsers(role, isActive as boolean | undefined);
    const total = Array.isArray(data) ? data.length : 0;
    sendSuccess(res, data, 200, { total });
  },

  assignRole: async (req: Request, res: Response) => {
    sendSuccess(res, await adminService.assignRole(req.params.id, req.body.roleId));
  },

  toggleStatus: async (req: Request, res: Response) => {
    sendSuccess(res, await adminService.toggleStatus(req.params.id));
  },

  listRoles: async (_req: Request, res: Response) => {
    sendSuccess(res, await adminService.getRoles());
  },
};
