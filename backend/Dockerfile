# Use Node 20 LTS Alpine base image
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package descriptors
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application source code
COPY . .

# Compile TypeScript to JavaScript
RUN npm run build

# --- Production Stage ---
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

COPY package*.json ./
RUN npm install --only=production

# Copy compiled JavaScript and public static assets
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

EXPOSE 5000

# Start compiled Node server
CMD ["node", "dist/server.js"]
