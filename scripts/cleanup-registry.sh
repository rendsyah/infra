#!/usr/bin/env bash

set -euo pipefail

# =========================================
# Docker Registry Cleanup Script (Dynamic)
# =========================================

# Config
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"

# Registry credentials
AUTH=""
if [ -n "${REGISTRY_USER:-}" ] && [ -n "${REGISTRY_PASSWORD:-}" ]; then
    AUTH="-u ${REGISTRY_USER}:${REGISTRY_PASSWORD}"
fi

REGISTRY_URL="http://localhost:5000"
REGISTRY_CONTAINER="private-registry-container"
KEEP_TAGS=1

LOG_FILE="/var/log/infra/cleanup-registry.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "========================================="
log " Docker Registry Cleanup Started"
log "========================================="

# Check required commands
for cmd in curl jq docker; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "[ERROR] Required command not found: $cmd"
        exit 1
    fi
done

log "[INFO] Fetching repositories from registry..."

# Get all repositories
REPOSITORIES=$(curl -fsS $AUTH "${REGISTRY_URL}/v2/_catalog" | jq -r '.repositories[]' || echo "")

if [ -z "${REPOSITORIES}" ]; then
    log "[INFO] No repositories found. Exiting."
    exit 0
fi

for IMAGE in ${REPOSITORIES}; do
    echo
    log "[INFO] Processing image: ${IMAGE}"

    # Get all tags
    TAGS=$(curl -fsS $AUTH "${REGISTRY_URL}/v2/${IMAGE}/tags/list" \
        | jq -r '.tags[]?' \
        | sort -V)

    TOTAL_TAGS=$(echo "${TAGS}" | sed '/^$/d' | wc -l)

    if [ "${TOTAL_TAGS}" -le "${KEEP_TAGS}" ]; then
        log "[INFO] Skipping ${IMAGE} (only ${TOTAL_TAGS} tag(s))"
        continue
    fi

    log "[INFO] Total tags: ${TOTAL_TAGS}. Keeping latest ${KEEP_TAGS}."

    TAGS_TO_DELETE=$(echo "${TAGS}" | head -n $((TOTAL_TAGS - KEEP_TAGS)))

    for TAG in ${TAGS_TO_DELETE}; do
        log "[INFO] Resolving digest for ${IMAGE}:${TAG}"

        DIGEST=$(
            curl -fsSI $AUTH \
                -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                "${REGISTRY_URL}/v2/${IMAGE}/manifests/${TAG}" \
                | grep "Docker-Content-Digest" \
                | awk '{print $2}' \
                | tr -d '\r'
        )

        if [ -z "${DIGEST}" ]; then
            log "[WARNING] Digest not found for ${IMAGE}:${TAG}, skipping"
            continue
        fi

        log "[INFO] Deleting ${IMAGE}:${TAG} (${DIGEST})"

        if curl -fsS $AUTH -X DELETE "${REGISTRY_URL}/v2/${IMAGE}/manifests/${DIGEST}" >/dev/null; then
            log "[SUCCESS] Deleted ${IMAGE}:${TAG}"
        else
            log "[ERROR] Failed to delete ${IMAGE}:${TAG}"
        fi
    done
done

log "[INFO] Running registry garbage collection..."

docker exec "${REGISTRY_CONTAINER}" \
    /bin/registry garbage-collect \
    --delete-untagged \
    /etc/docker/registry/config.yml || log "[WARNING] GC failed or nothing to collect"

log "========================================="
log " Docker Registry Cleanup Finished"
log "========================================="
