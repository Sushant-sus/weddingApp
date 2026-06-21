export interface AdminUser {
  id: string;
  full_name: string;
  email: string;
  is_active: boolean;
  is_email_verified: boolean;
  last_login_at: string | null;
  created_at: string;
  role_name: string | null;
  role_id: string | null;
}

export interface Role {
  id: string;
  name: string;
  description: string | null;
  permissions: string[];
}

export interface UserFilters {
  role?: string;
  isActive?: boolean;
}
