# Use Node 20 LTS Alpine base image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package descriptors
COPY package*.json ./
COPY prisma ./prisma/

# Install all dependencies
RUN npm ci

# Copy application source code
COPY . .

# Generate Prisma Client & Compile TypeScript
RUN npx prisma generate
RUN npm run build

# --- Production Stage ---
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

COPY package*.json ./
RUN npm ci --only=production

# Copy compiled JavaScript from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

# Copy static frontend assets (Flutter Web & Admin Panel if present)
COPY --from=builder /app/../admin ./admin
COPY --from=builder /app/../lcm_audios_app/build/web ./lcm_audios_app/build/web

EXPOSE 5000

# Start server
CMD ["node", "dist/server.ts"]
