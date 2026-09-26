#!/usr/bin/env bash

set -euo pipefail

# Go directly to the root of the project to find env file. Teleports this file anywhere into this dir.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
ENV_FILE_LOC="${PROJECT_DIR}/.env"

mkdir -p "$BACKUP_DIR"

if [! -f "$ENV_FILE_LOC" ]; then
    echo "[-] Error: .env configuration file not found at $ENV_FILE_LOC">&2
    exit 1
fi

# if env file exists, then go ahead with this
# | operator shifts the output of grep and prints the entire line in env file
export $(grep -v '^#' "$ENV_FILE_LOC" | xargs -d '\n')

# Uses names as per env file else uses default(:-)
DB_USER="${POSTGRES_USER:-appliance_user}"
DB_NAME="${DB_NAME:-appliance_prod}"

# Connecting docker with database container(as 'db' in compose) in docker compose file. 

DB_CONTAINER="db"
# We keep the data for 7 days then automatically delete backup files older than 7 days.
RETENTION_DAYS=7 

# generate timestamp e.g: 20260926_220056
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# In the directory of env file, data will be stored in file named <filename>.sql.gz
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

#Checks if docker daemon is responding or not(also gives out all the running container)

DOCKER_STATUS=$(docker ps -a)

# dev/null 2>&1 prints error(if any) alongside output
if ! docker ps -a >dev/null 2>&1; then
    echo "[-] Docker daemon is not running"
    exit 1
fi

#Checks the health of db container

CONTAINER_HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$DB_CONTAINER" 2>/dev/null || true)

if [ "$CONTAINER_HEALTH_STATUS" != "healthy"]; then
    echo -e "[-]container $DB_CONTAINER is not healthy\n$DB_CONTAINER status: $CONTAINER_HEALTH_STATUS"
    exit 1
fi

# not using -t flag as it generates unnecessary hidden variables in db
docker exec -i "$DB_CONTAINER" \

# In pg_dump, where there are no files created, user and container are connected with. 
  pg_dump -U "$DB_USER" -d "$DB_NAME" --clean --if-exists --no-owner --no-privileges

#compressing the .gz file to maximum extent
  | gzip -9 > $BACKUP_FILE


#Check if backup file size using -s flag and if it is greater than 0; also outputs error if any. 
#Also remove the backup file in case file is empty but size is greater than 0
if [ ! -s "$BACKUP_FILE"]; then
    echo "[-] Error: Backup failed. Generated file is empty.">&2
    rm -rf "$BACKUP_FILE"
    exit 1
fi

#Create older backup files, but keep recent ones for disaster recovery

echo "Pruning backups older than $RETENTION_DAYS days..."

find "$BACKUP_DIR" type -f "{$DB_NAME}_*.sql.gz" -mtime +"$RETENTION_DAYS" -exec rm -f {} +

echo "[+] Backup successfully completed: $BACKUP_FILE"
