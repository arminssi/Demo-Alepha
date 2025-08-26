#!/usr/bin/env bash
set -Eeuo pipefail

kubectl delete ns guestbook --ignore-not-found
kubectl delete ns monitoring --ignore-not-found

kind delete cluster || true

if docker ps -a --format '{{.Names}}' | grep -q '^kind-registry$'; then
  echo "removing local registry container..."
  docker rm -f kind-registry
fi