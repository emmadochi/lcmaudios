# ─── Stage 1: Builder ────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package descriptors and prisma schema first (layer caching)
COPY package*.json ./
COPY prisma ./prisma/

# Install ALL dependencies (incl. devDeps for tsc + prisma generate)
RUN npm install

# Generate Prisma client from schema
RUN npx prisma generate

# Copy remaining source
COPY . .

# Compile TypeScript → dist/
RUN npm run build

# ─── Stage 2: Production runner ───────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# Copy package descriptors and prisma schema
COPY package*.json ./
COPY prisma ./prisma/

# Production-only install + regenerate Prisma client for Alpine target
RUN npm install --omit=dev
RUN npx prisma generate

# Copy compiled JS output
COPY --from=builder /app/dist ./dist

# Copy static admin panel files
COPY --from=builder /app/public ./public

# Create upload directories (populated at runtime via Render disk or volume)
RUN mkdir -p uploads/audio uploads/artwork uploads/hls

EXPOSE 5000

# Startup: run DB migrations (idempotent & safe on every deploy), then start server.
# The "|| true" ensures the container boots even if DATABASE_URL is temporarily
# unavailable (e.g. DB still provisioning), so the healthcheck can still respond.
CMD ["sh", "-c", "npx prisma migrate deploy || echo '[Startup] Migration skipped or already applied.' && node dist/server.js"]
