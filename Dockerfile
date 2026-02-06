# Use Node.js 18 LTS for stability with older dependencies
# Node 18: Stable since April 2023, maintained until April 2025
# Better compatibility with 3-year-old codebase
FROM node:18-alpine

# Install runtime dependencies
# bash: Required for start.sh script
# curl: Useful for health checks and debugging
# dumb-init: Proper init system for signal handling
# su-exec: Allows running commands as different user (like gosu)
RUN apk add --no-cache bash curl dumb-init su-exec

# Create app directory
WORKDIR /app

# Copy package files first for better layer caching
# Only re-install dependencies when package files change
COPY package.json package-lock.json ./

# Install dependencies
# npm ci: Faster, more reliable, and deterministic than npm install
# --only=production: Skip devDependencies in production
# Clean cache to reduce image size
RUN npm ci --only=production && \
    npm cache clean --force

# Copy docker entrypoint script first
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy application code
COPY . .

# Create non-root user for security
# Running as root is a security risk
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app && \
    chmod +x /app/start.sh && \
    mkdir -p /app/public/images && \
    chown -R nodejs:nodejs /app/public/images

# Note: We stay as root user here so the entrypoint can fix volume permissions
# The entrypoint script will drop to nodejs user after fixing permissions

# Expose application port
EXPOSE 3000

# Set production environment
ENV NODE_ENV=production

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Use dumb-init with our entrypoint script
# The entrypoint runs as root to fix permissions, then drops to nodejs user
ENTRYPOINT ["dumb-init", "--", "docker-entrypoint.sh"]

# Run the application
CMD ["./start.sh"]
