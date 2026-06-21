-- 007 — Seed roles, permissions, role-permission matrix, default superadmin (idempotent)

-- Roles
INSERT INTO wedding.roles(name, description) VALUES
  ('SUPERADMIN', 'Full access to everything including admin panel'),
  ('ADMIN',      'Manage users, assign roles, full CRUD'),
  ('EDITOR',     'Create and edit records, no user management'),
  ('VIEWER',     'Read-only access')
ON CONFLICT (name) DO NOTHING;

-- Permissions
INSERT INTO wedding.permissions(name, description) VALUES
  ('guests:read','View guests'),       ('guests:write','Create/update guests'),       ('guests:delete','Delete guests'),
  ('gifts:read','View gifts'),         ('gifts:write','Create/update gifts'),         ('gifts:delete','Delete gifts'),
  ('itinerary:read','View itinerary'), ('itinerary:write','Create/update itinerary'), ('itinerary:delete','Delete itinerary'),
  ('costs:read','View costs'),         ('costs:write','Create/update costs'),         ('costs:delete','Delete costs'),
  ('users:read','View users'),         ('users:write','Create/update users'),         ('users:delete','Delete users'),
  ('roles:assign','Assign roles to users')
ON CONFLICT (name) DO NOTHING;

-- SUPERADMIN → all permissions
INSERT INTO wedding.role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM wedding.roles r CROSS JOIN wedding.permissions p
WHERE r.name = 'SUPERADMIN'
ON CONFLICT DO NOTHING;

-- ADMIN → all except users:delete and roles:assign
INSERT INTO wedding.role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM wedding.roles r CROSS JOIN wedding.permissions p
WHERE r.name = 'ADMIN' AND p.name NOT IN ('users:delete', 'roles:assign')
ON CONFLICT DO NOTHING;

-- EDITOR → :read and :write on data domains (no user/role management, no delete)
INSERT INTO wedding.role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM wedding.roles r CROSS JOIN wedding.permissions p
WHERE r.name = 'EDITOR'
  AND (p.name LIKE '%:read' OR p.name LIKE '%:write')
  AND p.name NOT LIKE 'users:%' AND p.name <> 'roles:assign'
ON CONFLICT DO NOTHING;

-- VIEWER → :read on data domains
INSERT INTO wedding.role_permissions(role_id, permission_id)
SELECT r.id, p.id FROM wedding.roles r CROSS JOIN wedding.permissions p
WHERE r.name = 'VIEWER'
  AND p.name LIKE '%:read'
  AND p.name NOT LIKE 'users:%'
ON CONFLICT DO NOTHING;

-- Default SUPERADMIN user (password: SuperAdmin@123 — bcrypt rounds 12)
INSERT INTO wedding.users(full_name, email, password_hash, role_id, is_email_verified, is_active)
SELECT 'Super Admin', 'superadmin@wedding.com',
       '$2b$12$N.LonfLcIbFPFF2iMHBkc.4j9wZ2a8KSzBEbGZJ8BaeptGtKpMLY2',
       r.id, TRUE, TRUE
FROM wedding.roles r WHERE r.name = 'SUPERADMIN'
ON CONFLICT (email) DO NOTHING;
