#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PLATFORM_BOOTSTRAP_INSTALL_PREFIX:-${HOME}/.local}"

INSTALL_DIR="${PREFIX}/lib/platform-bootstrap"
BIN_FILE="${PREFIX}/bin/platform-bootstrap"
UNINSTALL_BIN="${PREFIX}/bin/platform-bootstrap-uninstall"
COMPLETION_FILE="${PREFIX}/share/bash-completion/completions/platform-bootstrap"

echo "==> Désinstallation de platform-bootstrap"

rm -f "${BIN_FILE}"
rm -f "${UNINSTALL_BIN}"
rm -f "${COMPLETION_FILE}"
rm -rf "${INSTALL_DIR}"

echo
echo "[OK] platform-bootstrap désinstallé."