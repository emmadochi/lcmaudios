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

# Production-only install + regenerate Prisma client
RUN npm install --omit=dev
RUN npx prisma generate

# Copy compiled JS, static assets
COPY --from=builder /app/dist ./dist

# Create upload directories (populated at runtime)
RUN mkdir -p uploads/audio uploads/artwork uploads/hls

EXPOSE 5000

# Startup: run pending DB migrations then start server
# prisma migrate deploy is idempotent — safe on every container start
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
