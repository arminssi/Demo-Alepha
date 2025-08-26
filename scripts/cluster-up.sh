#!/usr/bin/env bash
set -Eeuo pipefail

#start-local.sh to bring up kind + local registry + nginx ingress
./start-local.sh

#wait so Ingress is usable immediately for http://localhost
kubectl wait -n ingress-nginx \
  --for=condition=Available deploy/ingress-nginx-controller --timeout=180s || true
##
echo "[ok] cluster ready"