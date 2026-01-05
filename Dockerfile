# syntax=docker/dockerfile:1

# Build stage
FROM node:20-alpine AS build
WORKDIR /app

# Install build tools (some deps may require native build tools)
RUN apk add --no-cache python3 make g++

# Copy package manifests first to leverage Docker cache
COPY package.json package-lock.json* ./

# Install dependencies including devDependencies required for build
RUN npm install --include=dev

# Copy source and build
COPY . .
RUN npm run build

# Runtime stage - serve static files with nginx
FROM nginx:stable-alpine AS runtime

# Remove default nginx content and copy built files
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- --timeout=2 http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
