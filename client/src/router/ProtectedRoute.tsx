import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';

interface Props {
  children: ReactNode;
  allowedRoles?: string[];
  allowedPermissions?: string[];
}

export function ProtectedRoute({ children, allowedRoles, allowedPermissions }: Props) {
  const { status, user, hasRole, hasPermission } = useAuth();
  const location = useLocation();

  if (status === 'loading') {
    return (
      <div className="flex h-screen items-center justify-center text-muted-foreground">
        Loading…
      </div>
    );
  }

  if (status === 'unauthenticated' || !user) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (allowedRoles && !hasRole(...allowedRoles)) {
    return <Navigate to="/forbidden" replace />;
  }

  if (allowedPermissions && !allowedPermissions.every((p) => hasPermission(p))) {
    return <Navigate to="/forbidden" replace />;
  }

  return <>{children}</>;
}
