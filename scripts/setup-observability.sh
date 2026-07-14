#!/usr/bin/env bash

set -euo pipefail

# =========================================
# Observability Stack Setup Script
# =========================================

# Config
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAFANA_DIR="${ROOT_DIR}/observability/grafana/data"
LOKI_DIR="${ROOT_DIR}/observability/loki/data"
FLUENT_BIT_DIR="${ROOT_DIR}/observability/fluent-bit/db"
FLUENT_BIT_STORAGE_DIR="${ROOT_DIR}/observability/fluent-bit/storage"

GRAFANA_UID=472
LOKI_UID=10001

echo "========================================="
echo " Observability Stack Setup"
echo "========================================="

# Create directories
echo "[INFO] Creating data directories..."
mkdir -p "${GRAFANA_DIR}" "${LOKI_DIR}" "${FLUENT_BIT_DIR}" "${FLUENT_BIT_STORAGE_DIR}"

# Fix permissions
echo "[INFO] Setting permissions..."

# Use sudo only if not root
SUDO_CMD=""
if [[ $EUID -ne 0 ]]; then
   SUDO_CMD="sudo"
fi

$SUDO_CMD chown -R "${GRAFANA_UID}:${GRAFANA_UID}" "${GRAFANA_DIR}"
echo "[SUCCESS] Grafana → UID ${GRAFANA_UID}"

$SUDO_CMD chown -R "${LOKI_UID}:${LOKI_UID}" "${LOKI_DIR}"
echo "[SUCCESS] Loki → UID ${LOKI_UID}"

echo "[SUCCESS] Directories ready."
echo "[DONE]"
