#!/usr/bin/env bash

set -euo pipefail

# =========================================
# PostgreSQL Backup Script (Dynamic)
# =========================================

# Check if database name is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <database_name>"
  exit 1
fi

POSTGRES_DB="$1"
POSTGRES_CONTAINER="postgres-container"

# Load .env file
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"

# Password from .env
export PGPASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_USER="postgres"

# Backup path
BACKUP_DIR="${ROOT_DIR}/backups/postgres"
KEEP_BACKUPS=7

# Logging
LOG_FILE="/var/log/infra/postgres-backup.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

DATE=$(date +%F_%H-%M-%S)
FILENAME="postgres-backup-${POSTGRES_DB}-${DATE}.sql.gz"

log "========================================="
log " PostgreSQL Backup Started: ${POSTGRES_DB}"
log "========================================="

mkdir -p "${BACKUP_DIR}"

log "[INFO] Creating PostgreSQL backup for ${POSTGRES_DB}..."

docker exec -e PGPASSWORD="${PGPASSWORD}" "${POSTGRES_CONTAINER}" \
    pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" \
    | gzip > "${BACKUP_DIR}/${FILENAME}"

log "[SUCCESS] Backup created: ${BACKUP_DIR}/${FILENAME}"

log "[INFO] Cleaning old backups for ${POSTGRES_DB}..."

ls -1t "${BACKUP_DIR}/postgres-backup-${POSTGRES_DB}-"*.sql.gz 2>/dev/null \
    | tail -n +$((KEEP_BACKUPS + 1)) \
    | xargs -r rm -f

log "[SUCCESS] Old backups cleaned"
log "========================================="
log " PostgreSQL Backup Finished"
log "========================================="
