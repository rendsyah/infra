#!/usr/bin/env bash

set -euo pipefail

# =========================================
# MariaDB Restore Script (Dynamic)
# =========================================

# Check if database name is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <database_name> [backup_filename]"
  exit 1
fi

MARIADB_DB="$1"
MARIADB_CONTAINER="mariadb-container"

# Load .env file
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"

# Use password from .env
MARIADB_PASSWORD="${MARIADB_ROOT_PASSWORD}"
MARIADB_USER="root"

# Backup path
BACKUP_DIR="${ROOT_DIR}/backups/mariadb"

# Logging
LOG_FILE="/var/log/infra/mariadb-restore.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Resolve backup file
if [[ $# -ge 2 ]]; then
    BACKUP_FILE="${BACKUP_DIR}/$2"
else
    BACKUP_FILE=$(ls -1t "${BACKUP_DIR}/mariadb-backup-${MARIADB_DB}-"*.sql.gz 2>/dev/null | head -n 1 || true)
fi

log "========================================="
log " MariaDB Restore Started: ${MARIADB_DB}"
log "========================================="

# --- Validate backup file ---
if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    log "[ERROR] Backup file not found for ${MARIADB_DB}"
    exit 1
fi

# --- Validate container ---
if ! docker ps --format '{{.Names}}' | grep -q "^${MARIADB_CONTAINER}$"; then
    log "[ERROR] Container '${MARIADB_CONTAINER}' is not running"
    exit 1
fi

log "[INFO] Restoring from: ${BACKUP_FILE}"

# --- Drop & recreate database ---
log "[INFO] Dropping and recreating database: ${MARIADB_DB}..."
docker exec -e MYSQL_PWD="${MARIADB_PASSWORD}" "${MARIADB_CONTAINER}" \
    mysql -u"${MARIADB_USER}" \
    -e "DROP DATABASE IF EXISTS \`${MARIADB_DB}\`; CREATE DATABASE \`${MARIADB_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# --- Restore ---
log "[INFO] Restoring data..."
gunzip -c "${BACKUP_FILE}" \
    | docker exec -i -e MYSQL_PWD="${MARIADB_PASSWORD}" "${MARIADB_CONTAINER}" \
        mysql -u"${MARIADB_USER}" "${MARIADB_DB}"

log "[SUCCESS] Database restored: ${MARIADB_DB}"
log "========================================="
log " MariaDB Restore Finished"
log "========================================="
