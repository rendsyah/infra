#!/usr/bin/env bash

set -euo pipefail

# =========================================
# MariaDB Backup Script (Dynamic)
# =========================================

# Check if database name is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <database_name>"
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
KEEP_BACKUPS=7

# Logging
LOG_FILE="/var/log/infra/mariadb-backup.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

DATE=$(date +%F_%H-%M-%S)
FILENAME="mariadb-backup-${MARIADB_DB}-${DATE}.sql.gz"

log "========================================="
log " MariaDB Backup Started: ${MARIADB_DB}"
log "========================================="

mkdir -p "${BACKUP_DIR}"

log "[INFO] Creating MariaDB backup for ${MARIADB_DB}..."

docker exec -e MYSQL_PWD="${MARIADB_PASSWORD}" "${MARIADB_CONTAINER}" \
    mysqldump \
    -u"${MARIADB_USER}" \
    --single-transaction \
    --quick \
    "${MARIADB_DB}" \
    | gzip > "${BACKUP_DIR}/${FILENAME}"

log "[SUCCESS] Backup created: ${BACKUP_DIR}/${FILENAME}"

log "[INFO] Cleaning old backups for ${MARIADB_DB}..."

ls -1t "${BACKUP_DIR}/mariadb-backup-${MARIADB_DB}-"*.sql.gz 2>/dev/null \
    | tail -n +$((KEEP_BACKUPS + 1)) \
    | xargs -r rm -f

log "[SUCCESS] Old backups cleaned"
log "========================================="
log " MariaDB Backup Finished"
log "========================================="
