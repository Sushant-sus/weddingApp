import { Router } from 'express';
import { guestRouter } from '../features/guests/guest.routes.js';
import { giftRouter } from '../features/gifts/gift.routes.js';
import { itineraryRouter } from '../features/itinerary/itinerary.routes.js';
import { costRouter } from '../features/costs/cost.routes.js';
import { authRouter } from '../features/auth/auth.routes.js';
import { adminRouter } from '../features/admin/admin.routes.js';

// The API v1 router. To add a new feature: build its router under
// src/features/<feature>/ and register one line here — nothing else changes.
export const apiRouter = Router();

apiRouter.get('/health', (_req, res) =>
  res.json({ success: true, data: { status: 'ok', time: new Date().toISOString() } }),
);

apiRouter.use('/auth', authRouter);
apiRouter.use('/admin', adminRouter);

apiRouter.use('/guests', guestRouter);
apiRouter.use('/', giftRouter); // owns /gifts and /guests/:id/gifts
apiRouter.use('/itinerary', itineraryRouter);
apiRouter.use('/costs', costRouter);
