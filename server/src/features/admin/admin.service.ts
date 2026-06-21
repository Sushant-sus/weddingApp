import { prisma } from '../../prisma/client.js';

export const adminService = {
  getUsers: async (roleName?: string, isActive?: boolean) => {
    const rows = await prisma.$queryRaw<[{ sp_admin_get_users: unknown }]>`
      SELECT wedding.sp_admin_get_users(
        ${roleName ?? null}::TEXT,
        ${isActive ?? null}::BOOLEAN
      )
    `;
    return rows[0].sp_admin_get_users;
  },

  assignRole: async (userId: string, roleId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_admin_assign_role: unknown }]>`
      SELECT wedding.sp_admin_assign_role(${userId}::UUID, ${roleId}::UUID)
    `;
    return rows[0].sp_admin_assign_role;
  },

  toggleStatus: async (userId: string) => {
    const rows = await prisma.$queryRaw<[{ sp_admin_toggle_user_status: unknown }]>`
      SELECT wedding.sp_admin_toggle_user_status(${userId}::UUID)
    `;
    return rows[0].sp_admin_toggle_user_status;
  },

  getRoles: async () => {
    const rows = await prisma.$queryRaw<[{ sp_admin_get_roles: unknown }]>`
      SELECT wedding.sp_admin_get_roles()
    `;
    return rows[0].sp_admin_get_roles;
  },
};
