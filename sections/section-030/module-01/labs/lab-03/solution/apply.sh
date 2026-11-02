#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-030-01-03" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
lab_directory="$(cd "$(dirname "$0")/.." && pwd)"
solution_directory="$lab_directory/solution"
node_name="astro-ats-051-lab-030-01-03-control-plane"
worker_name="astro-ats-051-lab-030-01-03-worker"

kubectl apply -f "$solution_directory/configmap-alertmanager-config.yaml"
kubectl -n starfleet rollout status deployment/alertmanager --timeout=180s
python3 "$solution_directory/send-alert.py"
sleep 6
python3 "$solution_directory/silence.py"
sleep 4
