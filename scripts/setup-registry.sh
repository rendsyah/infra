#!/usr/bin/env bash

set -euo pipefail

# =========================================
# Private Registry HTPASSWD Setup Script
# =========================================

# Config
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTH_DIR="${ROOT_DIR}/registry/auth"
HTPASSWD_FILE="${AUTH_DIR}/htpasswd"

# Load .env file
[ -f "${ROOT_DIR}/.env" ] && source "${ROOT_DIR}/.env"

echo "========================================="
echo " Docker Registry Auth Setup"
echo "========================================="

# Use env vars if available, otherwise prompt
REGISTRY_USER="${REGISTRY_USER:-}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-}"

if [ -z "$REGISTRY_USER" ] || [ -z "$REGISTRY_PASSWORD" ]; then
    echo "[INFO] Environment variables not set. Proceeding with interactive input..."
    read -p "Enter registry username: " REGISTRY_USER
    read -s -p "Enter registry password: " REGISTRY_PASSWORD
    echo
fi

if [ -z "$REGISTRY_USER" ] || [ -z "$REGISTRY_PASSWORD" ]; then
    echo "[ERROR] Username/Password cannot be empty"
    exit 1
fi

# Create auth directory
mkdir -p "${AUTH_DIR}"

echo "[INFO] Generating/Updating htpasswd file..."

# Overwrite with new user
echo "${REGISTRY_PASSWORD}" | docker run --rm -i \
  --entrypoint htpasswd httpd:2 \
  -Bbin "${REGISTRY_USER}" \
  > "${HTPASSWD_FILE}"

chmod 600 "${HTPASSWD_FILE}"

echo "[SUCCESS] htpasswd created/updated at: ${HTPASSWD_FILE}"
echo "[DONE]"
