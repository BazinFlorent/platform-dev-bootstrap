#!/usr/bin/env bash
set -euo pipefail

echo "WARNING: this removes the Crossplane Helm release."
echo "It does not attempt to delete platform XRs/XRDs first."

helm_cmd uninstall crossplane \
  --namespace crossplane-system
