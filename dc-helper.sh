#!/bin/bash

# DevBlog Docker Compose Helper Script
# Author: DevOps Mentorship C2
# Purpose: Simplify common Docker Compose operations

# Function to display help message
show_help() {
    cat << 'EOF'
DevBlog Docker Compose Helper
=============================

Usage: ./dc-helper.sh <command> [service]

Commands:
  up [service]          Start all services, or a specific service
  down [service]        Stop all services, or a specific service
  build [service]       Build all services, or a specific service
  restart [service]     Restart all services, or a specific service
  logs [service]        View logs (all or specific). Use -f to follow
  status [service]      Show status of all or a specific container
  seed                  Create admin user (run seeding script)
  shell <service>       Open a shell inside a container (e.g., web, mongo)
  clean                 Stop containers and remove volumes (DESTRUCTIVE)
  help                  Show this help message

Services:
  web                   Node.js application (port 3000)
  mongo                 MongoDB database (port 27017)
  mongo-express         MongoDB web UI (port 8081)

Examples:
  ./dc-helper.sh up                 # Start all services
  ./dc-helper.sh up mongo           # Start only MongoDB
  ./dc-helper.sh down web           # Stop only web service
  ./dc-helper.sh logs -f            # Follow all logs
  ./dc-helper.sh logs web           # View only web service logs
  ./dc-helper.sh build web          # Rebuild only web service
  ./dc-helper.sh restart mongo      # Restart only MongoDB
  ./dc-helper.sh status             # Check all container statuses
  ./dc-helper.sh shell web          # Open shell in web container
  ./dc-helper.sh shell mongo        # Open MongoDB shell
  ./dc-helper.sh seed               # Seed database with admin user
  ./dc-helper.sh clean              # Full cleanup (removes data!)
EOF
}

# Command: up [service]
# Start services in detached mode
cmd_up() {
    if [ -z "$1" ]; then
        echo "Starting all services..."
        docker compose up -d
    else
        echo "Starting $1 service..."
        docker compose up -d "$1"
    fi
}

# Command: down [service]
# Stop services (all or specific)
cmd_down() {
    if [ -z "$1" ]; then
        echo "Stopping all services..."
        docker compose down
    else
        echo "Stopping $1 service..."
        docker compose stop "$1"
        docker compose rm -f "$1"
    fi
}

# Command: build [service]
# Build or rebuild service images
cmd_build() {
    if [ -z "$1" ]; then
        echo "Building all services..."
        docker compose build
    else
        echo "Building $1 service..."
        docker compose build "$1"
    fi
}

# Command: restart [service]
# Restart services
cmd_restart() {
    if [ -z "$1" ]; then
        echo "Restarting all services..."
        docker compose restart
    else
        echo "Restarting $1 service..."
        docker compose restart "$1"
    fi
}

# Command: logs [service|-f]
# View logs with optional follow flag
cmd_logs() {
    # Check if first argument is -f flag
    if [ "$1" = "-f" ]; then
        if [ -z "$2" ]; then
            echo "Following all logs (Ctrl+C to stop)..."
            docker compose logs -f
        else
            echo "Following $2 logs (Ctrl+C to stop)..."
            docker compose logs -f "$2"
        fi
    else
        if [ -z "$1" ]; then
            echo "Showing all logs..."
            docker compose logs
        else
            echo "Showing $1 logs..."
            docker compose logs "$1"
        fi
    fi
}

# Command: status [service]
# Show container status
cmd_status() {
    if [ -z "$1" ]; then
        echo "Showing status of all services..."
        docker compose ps
    else
        echo "Showing status of $1 service..."
        docker compose ps "$1"
    fi
}

# Command: seed
# Run seeding script inside web container
cmd_seed() {
    echo "Running seeding script..."
    docker compose exec -it web node create-user-cli.js
}

# Command: shell <service>
# Open shell in container (service-specific)
cmd_shell() {
    if [ -z "$1" ]; then
        echo "Error: service required for shell command"
        echo "Available services: web, mongo, mongo-express"
        exit 1
    fi

    case $1 in
        web)
            echo "Opening bash shell in web container..."
            docker compose exec -it web /bin/bash
            ;;
        mongo)
            echo "Opening MongoDB shell..."
            docker compose exec -it mongo mongo
            ;;
        mongo-express)
            echo "Opening shell in mongo-express container..."
            docker compose exec -it mongo-express /bin/sh
            ;;
        *)
            echo "Error: invalid service '$1'"
            echo "Available services: web, mongo, mongo-express"
            exit 1
            ;;
    esac
}

# Command: clean
# Stop containers and remove volumes (DESTRUCTIVE)
cmd_clean() {
    echo "WARNING: This will stop all containers and DELETE ALL VOLUMES"
    echo "This includes:"
    echo "  - All database data"
    echo "  - All uploaded images"
    echo "  - Any other persisted data"
    echo ""
    echo -n "Type 'yes' to confirm: "
    read confirmation

    if [ "$confirmation" = "yes" ]; then
        echo "Cleaning up containers and volumes..."
        docker compose down -v
        echo "Cleanup complete!"
    else
        echo "Cleanup cancelled."
    fi
}

# Main script execution
COMMAND=$1
SERVICE=$2

case $COMMAND in
    up)
        cmd_up "$SERVICE"
        ;;
    down)
        cmd_down "$SERVICE"
        ;;
    build)
        cmd_build "$SERVICE"
        ;;
    restart)
        cmd_restart "$SERVICE"
        ;;
    logs)
        shift  # Remove first argument
        cmd_logs "$@"  # Pass all remaining arguments
        ;;
    status)
        cmd_status "$SERVICE"
        ;;
    seed)
        cmd_seed
        ;;
    shell)
        cmd_shell "$SERVICE"
        ;;
    clean)
        cmd_clean
        ;;
    help|"")
        show_help
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo ""
        show_help
        exit 1
        ;;
esac
