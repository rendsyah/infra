#!/usr/bin/env bash

set -euo pipefail

# =========================================
# PostgreSQL Restore Script (Dynamic)
# =========================================

# Check if database name is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <database_name> [backup_filename]"
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

# Logging
LOG_FILE="/var/log/infra/postgres-restore.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Resolve backup file
if [[ $# -ge 2 ]]; then
    BACKUP_FILE="${BACKUP_DIR}/$2"
else
    BACKUP_FILE=$(ls -1t "${BACKUP_DIR}/postgres-backup-${POSTGRES_DB}-"*.sql.gz 2>/dev/null | head -n 1 || true)
fi

log "========================================="
log " PostgreSQL Restore Started: ${POSTGRES_DB}"
log "========================================="

# --- Validate backup file ---
if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    log "[ERROR] Backup file not found for ${POSTGRES_DB}"
    exit 1
fi

# --- Validate container ---
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    log "[ERROR] Container '${POSTGRES_CONTAINER}' is not running"
    exit 1
fi

log "[INFO] Restoring from: ${BACKUP_FILE}"

# --- Terminate active connections ---
log "[INFO] Terminating active connections..."
docker exec -e PGPASSWORD="${PGPASSWORD}" "${POSTGRES_CONTAINER}" \
    psql -U "${POSTGRES_USER}" -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${POSTGRES_DB}';" \
    2>/dev/null || true

# --- Drop & recreate database ---
log "[INFO] Dropping and recreating database..."
docker exec -e PGPASSWORD="${PGPASSWORD}" "${POSTGRES_CONTAINER}" \
    psql -U "${POSTGRES_USER}" -d postgres \
    -c "DROP DATABASE IF EXISTS ${POSTGRES_DB}; CREATE DATABASE ${POSTGRES_DB};"

# --- Restore ---
log "[INFO] Restoring data..."
gunzip -c "${BACKUP_FILE}" \
    | docker exec -i -e PGPASSWORD="${PGPASSWORD}" "${POSTGRES_CONTAINER}" \
        psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"

log "[SUCCESS] Database restored: ${POSTGRES_DB}"
log "========================================="
log " PostgreSQL Restore Finished"
log "========================================="
