import { PrismaClient } from '@prisma/client';

/**
 * Global singleton PrismaClient.
 * Using a global variable in development prevents exhausting
 * the database connection pool on hot-reloads (ts-node / nodemon).
 */
const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'warn', 'error'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
