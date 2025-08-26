#!/usr/bin/env bash
set -Eeuo pipefail

REGISTRY="${REGISTRY:-localhost:5000}"
TAG="${TAG:-dev}"
NS="${NAMESPACE:-guestbook}"

echo "Build & push images (tag: $TAG) to $REGISTRY"
docker build -t "$REGISTRY/python-guestbook-frontend:$TAG" ./src/frontend
docker push  "$REGISTRY/python-guestbook-frontend:$TAG"
docker build -t "$REGISTRY/python-guestbook-backend:$TAG"  ./src/backend
docker push  "$REGISTRY/python-guestbook-backend:$TAG"

echo "Create namespace"
kubectl create ns "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "Apply Services and DB"
kubectl -n "$NS" apply -f src/frontend/kubernetes-manifests/guestbook-frontend.service.yaml
kubectl -n "$NS" apply -f src/backend/kubernetes-manifests/guestbook-backend.service.yaml
kubectl -n "$NS" apply -f src/backend/kubernetes-manifests/guestbook-mongodb.service.yaml
kubectl -n "$NS" apply -f src/backend/kubernetes-manifests/guestbook-mongodb.deployment.yaml

echo "Apply Deployments"
kubectl -n "$NS" apply -f src/frontend/kubernetes-manifests/guestbook-frontend.deployment.yaml
kubectl -n "$NS" apply -f src/backend/kubernetes-manifests/guestbook-backend.deployment.yaml

echo "images at local registry"
kubectl -n "$NS" set image deploy/python-guestbook-frontend frontend="$REGISTRY/python-guestbook-frontend:$TAG"
kubectl -n "$NS" set image deploy/python-guestbook-backend  backend="$REGISTRY/python-guestbook-backend:$TAG"

echo "Ingress"
kubectl -n "$NS" apply -f src/frontend/kubernetes-manifests/guestbook-frontend-ingress.yaml

echo "Wait for rollouts"
kubectl -n "$NS" rollout status deploy/python-guestbook-frontend
kubectl -n "$NS" rollout status deploy/python-guestbook-backend

echo "Done. Open http://localhost/"