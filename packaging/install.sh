#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/Makefile" && -d "${SCRIPT_DIR}/core" ]]; then
  # Package distribué : install.sh est à la racine.
  PROJECT_ROOT="${SCRIPT_DIR}"
else
  # Repository de développement : install.sh est dans packaging/.
  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ -f "${PROJECT_ROOT}/uninstall.sh" ]]; then
  # Package distribué.
  UNINSTALL_SOURCE="${PROJECT_ROOT}/uninstall.sh"
else
  # Repository de développement.
  UNINSTALL_SOURCE="${PROJECT_ROOT}/packaging/uninstall.sh"
fi

PREFIX="${PLATFORM_BOOTSTRAP_INSTALL_PREFIX:-${HOME}/.local}"

INSTALL_DIR="${PREFIX}/lib/platform-bootstrap"
BIN_DIR="${PREFIX}/bin"
COMPLETION_DIR="${PREFIX}/share/bash-completion/completions"

echo "==> Installation de platform-bootstrap"
echo "    Prefix : ${PREFIX}"

mkdir -p \
  "${INSTALL_DIR}" \
  "${BIN_DIR}" \
  "${COMPLETION_DIR}"

echo "==> Installation des fichiers"

rm -rf "${INSTALL_DIR:?}/"*

cp "${PROJECT_ROOT}/Makefile" "${INSTALL_DIR}/"
cp "${PROJECT_ROOT}/README.md" "${INSTALL_DIR}/"

cp -R "${PROJECT_ROOT}/bin" "${INSTALL_DIR}/"
cp -R "${PROJECT_ROOT}/core" "${INSTALL_DIR}/"
cp -R "${PROJECT_ROOT}/ai" "${INSTALL_DIR}/"
cp -R "${PROJECT_ROOT}/completion" "${INSTALL_DIR}/"
cp -R "${PROJECT_ROOT}/docs" "${INSTALL_DIR}/"

cp "${UNINSTALL_SOURCE}" "${INSTALL_DIR}/uninstall.sh"
chmod +x "${INSTALL_DIR}/uninstall.sh"

echo "==> Installation de la commande"

rm -f "${BIN_DIR}/platform-bootstrap"

cat > "${BIN_DIR}/platform-bootstrap" <<EOF
#!/usr/bin/env bash
exec "${INSTALL_DIR}/bin/platform-bootstrap" "\$@"
EOF

chmod +x "${BIN_DIR}/platform-bootstrap"
chmod +x "${INSTALL_DIR}/bin/platform-bootstrap"

echo "==> Installation de la commande de désinstallation"

rm -f "${BIN_DIR}/platform-bootstrap-uninstall"

cat > "${BIN_DIR}/platform-bootstrap-uninstall" <<EOF
#!/usr/bin/env bash
exec "${INSTALL_DIR}/uninstall.sh" "\$@"
EOF

chmod +x "${BIN_DIR}/platform-bootstrap-uninstall"

echo "==> Installation de l'autocomplétion Bash"

cp \
  "${PROJECT_ROOT}/completion/platform-bootstrap.bash" \
  "${COMPLETION_DIR}/platform-bootstrap"

echo
echo "[OK] platform-bootstrap installé."
echo
echo "Commande :"
echo "  ${BIN_DIR}/platform-bootstrap"
echo
echo "Vérification :"
echo "  platform-bootstrap --help"
echo
echo "Désinstallation :"
echo "  platform-bootstrap-uninstall"