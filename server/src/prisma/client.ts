import { PrismaClient } from '@prisma/client';
import { env } from '../config/env.js';

// Prisma client singleton. NOTE: In this architecture Prisma is used ONLY as a
// query runner ($queryRaw / $executeRaw) that calls PostgreSQL stored
// procedures in the `wedding` schema. We never call prisma.model.* methods.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: env.isProd ? ['error'] : ['error', 'warn'],
  });

if (!env.isProd) globalForPrisma.prisma = prisma;
