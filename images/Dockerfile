# Build GPT Researcher Next.js frontend
FROM node:20 AS builder
WORKDIR /src
RUN git clone --depth 1 https://github.com/assafelovic/gpt-researcher.git .
WORKDIR /src/frontend/nextjs
ARG NEXT_PUBLIC_GPTR_API_URL=https://researcher-api.oremuslabs.app
ENV NEXT_PUBLIC_GPTR_API_URL=${NEXT_PUBLIC_GPTR_API_URL}
RUN npm install --legacy-peer-deps
RUN npm run build

FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /src/frontend/nextjs/package.json ./package.json
COPY --from=builder /src/frontend/nextjs/package-lock.json ./package-lock.json
COPY --from=builder /src/frontend/nextjs/node_modules ./node_modules
COPY --from=builder /src/frontend/nextjs/.next ./.next
COPY --from=builder /src/frontend/nextjs/public ./public
EXPOSE 3000
CMD ["npm","run","start"]
