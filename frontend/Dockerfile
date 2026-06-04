# --- Stage 1: Build ---
FROM node:20-alpine AS build
WORKDIR /app

# Copy package descriptors and lockfile
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build production bundle
RUN npm run build

# --- Stage 2: Serve ---
FROM nginx:alpine

# Copy built SPA files to Nginx public folder
COPY --from=build /app/dist/frontend/browser /usr/share/nginx/html

# Copy Nginx custom configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
