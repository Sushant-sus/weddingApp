import type { ReactNode } from 'react';
import { useEventContext } from '@/context/EventContext';
import type { EventRole } from '../event.types';

// Renders children only if the current user's event role grants access
// (rank-based: having a higher role satisfies a lower required role).
export function EventRoleGuard({
  allowedRoles,
  children,
  fallback = null,
}: {
  allowedRoles: EventRole[];
  children: ReactNode;
  fallback?: ReactNode;
}) {
  const { hasEventAccess } = useEventContext();
  return <>{hasEventAccess(allowedRoles) ? children : fallback}</>;
}
