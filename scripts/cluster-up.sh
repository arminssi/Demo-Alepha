#!/usr/bin/env bash
set -Eeuo pipefail

./start-local.sh

# wait so Ingress is usable immediately for http://localhost
kubectl wait -n ingress-nginx \
  --for=condition=Available deploy/ingress-nginx-controller --timeout=180s || true

# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "[ok] cluster ready"