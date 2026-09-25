#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Access denied: Please run as root user"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "Error: Docker Compose plugin is not installed."
    exit 1
fi

if ! test -f .env; then
    echo "Error: .env file not found.Creating a new one."
    DB_PASSWORD=$(openssl rand -hex 16)
    cat <<EOF > .env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_DB=appliance
EXPOSE=3000
NODE_ENV=production
EOF
    echo ".env file created successfully."
else
    echo ".env already exists. Preserving current secrets."
fi

echo "Initializing storage directories..."
mkdir -p ./backups
chmod 750 ./backups
echo "Storage directories initialized."

echo "Starting Docker Compose services..."
docker compose up -d --build --remove-orphans
echo "Docker Compose services started."

RETRY_COUNT=0
MAX_RETRIES=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    
    RETRY_COUNT=$((RETRY_COUNT+1))
    DOCKER_HEALTH_CHECK=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' appliance-db 2>/dev/null || echo "not_found")
    
    ERR_HEALTH_WORD=("starting" "unhealthy" "none" "not_found")
    if [ "$DOCKER_HEALTH_CHECK" = "healthy" ]; then
        echo "Database is ready and healthy."
        break
    fi
    for word in "${ERR_HEALTH_WORD[@]}";do
        if [ "$DOCKER_HEALTH_CHECK" = "$word" ]; then
            echo "Database is still starting. Retrying in 5 seconds..."
            sleep 5
            break
        fi
    done
done

if [ "$DOCKER_HEALTH_CHECK" != "healthy" ]; then
    echo "The database container did not become healthy within the expected time. Please check the container logs for more information."
    docker compose logs --tail=20
    exit 1

fi 