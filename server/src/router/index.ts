import { Router } from 'express';
import { authRouter } from '../features/auth/auth.routes.js';
import { adminRouter } from '../features/admin/admin.routes.js';
import { eventRouter } from '../features/events/event.routes.js';
import { providerRouter } from '../features/providers/provider.routes.js';
import { requestRouter } from '../features/requests/request.routes.js';

// API v1 router.
//
// Architecture (v2): authentication + multi-event collaboration.
//   /auth   — public auth endpoints (register/login/OTP/refresh/...)
//   /admin  — global SUPERADMIN/ADMIN user & role management
//   /events — everything else, scoped to a wedding event the user belongs to:
//             /events/:eventId/{guests,gifts,itinerary,costs} guarded by event role.
//
// To add a new feature: build its router under src/features/<feature>/ and
// register one line here (or under the event-scoped router for per-event data).
export const apiRouter = Router();

apiRouter.get('/health', (_req, res) =>
  res.json({ success: true, data: { status: 'ok', time: new Date().toISOString() } }),
);

apiRouter.use('/auth', authRouter);
apiRouter.use('/admin', adminRouter);
apiRouter.use('/events', eventRouter);

// Utsav service marketplace (additive): provider directory + the caller's own
// provider profile, plus request-/pitch-scoped actions. Event-scoped request
// creation/listing lives on the event-scoped router (see event.dataRoutes.ts).
apiRouter.use(providerRouter);
apiRouter.use(requestRouter);
