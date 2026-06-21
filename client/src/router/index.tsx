import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout';
import { ForbiddenPage } from '@/components/layout/ForbiddenPage';
import { ProtectedRoute } from './ProtectedRoute';

import { LoginPage } from '@/features/auth/pages/LoginPage';
import { RegisterPage } from '@/features/auth/pages/RegisterPage';
import { VerifyEmailPage } from '@/features/auth/pages/VerifyEmailPage';
import { ForgotPasswordPage } from '@/features/auth/pages/ForgotPasswordPage';
import { ResetPasswordPage } from '@/features/auth/pages/ResetPasswordPage';

import { EventListPage } from '@/features/events/pages/EventListPage';
import { EventCreatePage } from '@/features/events/pages/EventCreatePage';
import { EventDetailPage } from '@/features/events/pages/EventDetailPage';
import { InviteResponsePage } from '@/features/events/pages/InviteResponsePage';
import { AdminUsersPage } from '@/features/admin/pages/AdminUsersPage';

export const router = createBrowserRouter([
  // Public auth routes
  { path: '/login', element: <LoginPage /> },
  { path: '/register', element: <RegisterPage /> },
  { path: '/verify-email', element: <VerifyEmailPage /> },
  { path: '/forgot-password', element: <ForgotPasswordPage /> },
  { path: '/reset-password', element: <ResetPasswordPage /> },
  // Invite links from email (require login to attribute the action to a user)
  {
    path: '/invite/:action',
    element: (
      <ProtectedRoute>
        <InviteResponsePage />
      </ProtectedRoute>
    ),
  },

  // Authenticated app
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <AppLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/events" replace /> },
      { path: 'events', element: <EventListPage /> },
      { path: 'events/new', element: <EventCreatePage /> },
      { path: 'events/:eventId', element: <EventDetailPage /> },
      {
        path: 'admin/users',
        element: (
          <ProtectedRoute allowedRoles={['SUPERADMIN', 'ADMIN']}>
            <AdminUsersPage />
          </ProtectedRoute>
        ),
      },
      { path: 'forbidden', element: <ForbiddenPage /> },
    ],
  },

  { path: '*', element: <Navigate to="/events" replace /> },
]);
