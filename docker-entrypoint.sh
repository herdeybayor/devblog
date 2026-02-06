#!/bin/bash
set -e

# This script runs as root to fix volume permissions
# then drops privileges to run the app as nodejs user

# Fix permissions for the images volume
# This is necessary because Docker volumes are created as root
if [ -d "/app/public/images" ]; then
    echo "Fixing permissions for /app/public/images..."
    chown -R nodejs:nodejs /app/public/images
    chmod -R 755 /app/public/images
fi

# Switch to nodejs user and execute the command
echo "Starting application as nodejs user..."
exec su-exec nodejs "$@"
