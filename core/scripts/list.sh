#!/usr/bin/env bash
set -euo pipefail

DETAIL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --detail)
      DETAIL=true
      shift
      ;;
    *)
      echo "ERROR: argument inattendu pour list: $1" >&2
      exit 1
      ;;
  esac
done

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

if [[ "${DETAIL}" == "false" ]]; then
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
fi

for instance_file in "${INSTANCE_FILES[@]}"; do
  unset \
    PLATFORM_BOOTSTRAP_NAME \
    KIND_CLUSTER \
    KIND_HTTP_PORT \
    KIND_HTTPS_PORT \
    REGISTRY_NAME \
    REGISTRY_HOST \
    REGISTRY_PORT

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
  instance_state_dir="$(dirname "${instance_file}")"

  if [[ "${DETAIL}" == "false" ]]; then
    printf "%-28s %-28s %-10s %-52s %-10s %s\n" \
      "${PLATFORM_BOOTSTRAP_NAME}" \
      "${KIND_CLUSTER}" \
      "${kind_status}" \
      "${registry_url}" \
      "${registry_status}" \
      "${ports}"

    continue
  fi

  crossplane_status="unknown"

  if [[ "${kind_status}" == "present" ]] && command -v kubectl >/dev/null 2>&1; then
    if kubectl \
      --context "kind-${KIND_CLUSTER}" \
      get namespace crossplane-system \
      >/dev/null 2>&1; then

      if kubectl \
        --context "kind-${KIND_CLUSTER}" \
        -n crossplane-system \
        get deployment crossplane \
        >/dev/null 2>&1; then
        crossplane_status="installed"
      else
        crossplane_status="not-ready"
      fi
    else
      crossplane_status="absent"
    fi
  fi

  echo "Instance       : ${PLATFORM_BOOTSTRAP_NAME}"
  echo "Kind cluster   : ${KIND_CLUSTER}"
  echo "Kind context   : kind-${KIND_CLUSTER}"
  echo "Kind status    : ${kind_status}"
  echo "Registry name  : ${REGISTRY_NAME}"
  echo "Registry URL   : ${registry_url}"
  echo "Registry state : ${registry_status}"
  echo "HTTP port      : ${KIND_HTTP_PORT}"
  echo "HTTPS port     : ${KIND_HTTPS_PORT}"
  echo "State          : ${instance_state_dir}"
  echo "Crossplane     : ${crossplane_status}"
  echo
done