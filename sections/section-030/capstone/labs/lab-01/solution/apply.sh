#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-030-cap-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/configmap-alertmanager-config.yaml"
kubectl -n starfleet rollout restart deployment/alertmanager
kubectl -n starfleet rollout status deployment/alertmanager --timeout=180s
sleep 3
