#!/usr/bin/env bash
set -euo pipefail

STATE_ROOT="${PLATFORM_BOOTSTRAP_STATE_ROOT:-${XDG_STATE_HOME:-${HOME}/.local/state}/platform-bootstrap}"

if [[ ! -d "${STATE_ROOT}" ]]; then
  echo "Aucune instance connue."
  exit 0
fi

INSTANCE_FILES=()

while IFS= read -r file; do
  INSTANCE_FILES+=("${file}")
done < <(
  find "${STATE_ROOT}" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    -name instance.env \
    -print | sort
)

if [[ ${#INSTANCE_FILES[@]} -eq 0 ]]; then
  echo "Aucune instance connue."
  exit 0
fi

KIND_AVAILABLE=false
KIND_CLUSTERS=""

if command -v kind >/dev/null 2>&1; then
  if KIND_CLUSTERS="$(kind get clusters 2>/dev/null)"; then
    KIND_AVAILABLE=true
  fi
fi

DOCKER_AVAILABLE=false

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  DOCKER_AVAILABLE=true
fi

printf "%-28s %-28s %-10s %-52s %-10s %s\n" \
  "INSTANCE" \
  "KIND CLUSTER" \
  "KIND" \
  "OCI REGISTRY" \
  "REGISTRY" \
  "HTTP/HTTPS"

printf "%-28s %-28s %-10s %-52s %-10s %s\n" \
  "----------------------------" \
  "----------------------------" \
  "----------" \
  "----------------------------------------------------" \
  "----------" \
  "----------"

for instance_file in "${INSTANCE_FILES[@]}"; do
  unset \
    PLATFORM_BOOTSTRAP_NAME \
    KIND_CLUSTER \
    KIND_HTTP_PORT \
    KIND_HTTPS_PORT \
    REGISTRY_NAME \
    REGISTRY_HOST \
    REGISTRY_PORT

  # Fichier généré et géré par platform-bootstrap.
  source "${instance_file}"

  kind_status="unknown"

  if [[ "${KIND_AVAILABLE}" == "true" ]]; then
    if grep -Fxq "${KIND_CLUSTER}" <<< "${KIND_CLUSTERS}"; then
      kind_status="present"
    else
      kind_status="absent"
    fi
  fi

  registry_status="unknown"

  if [[ "${DOCKER_AVAILABLE}" == "true" ]]; then
    if docker inspect "${REGISTRY_NAME}" >/dev/null 2>&1; then
      if [[ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}")" == "true" ]]; then
        registry_status="running"
      else
        registry_status="stopped"
      fi
    else
      registry_status="absent"
    fi
  fi

  registry_url="https://${REGISTRY_HOST}:${REGISTRY_PORT}"
  ports="${KIND_HTTP_PORT}/${KIND_HTTPS_PORT}"

  printf "%-28s %-28s %-10s %-52s %-10s %s\n" \
    "${PLATFORM_BOOTSTRAP_NAME}" \
    "${KIND_CLUSTER}" \
    "${kind_status}" \
    "${registry_url}" \
    "${registry_status}" \
    "${ports}"
done