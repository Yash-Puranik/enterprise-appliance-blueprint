FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY package.json server.js ./
ENV NODE_ENV=production
USER node
EXPOSE 3000
CMD ["node","server.js"]
