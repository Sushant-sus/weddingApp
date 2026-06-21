import type { Request, Response } from 'express';
import { sendError } from '../utils/response.js';

export const notFound = (req: Request, res: Response) =>
  sendError(res, 404, 'ROUTE_NOT_FOUND', `Route ${req.method} ${req.originalUrl} not found`);
