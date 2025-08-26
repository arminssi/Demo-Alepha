#!/usr/bin/env bash
set -Eeuo pipefail

######## grab charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# install/upgrade Prometheus + Alertmanager + Grafana
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f monitoring/kps-values.yaml

## first install? CRDs need few secnds
echo "Waiting for monitoring CRDs to become available..."
for crd in servicemonitors.monitoring.coreos.com prometheusrules.monitoring.coreos.com; do
  until kubectl get crd "$crd" >/dev/null 2>&1; do
    sleep 2
  done
done

# tell Prometheus about our app + alerts
kubectl apply -f monitoring/servicemonitors.yaml
kubectl apply -f monitoring/alerting-rules.yaml


# wait for pods so they dont confused
kubectl -n monitoring rollout status statefulset/kps-prometheus --timeout=5m || true
kubectl -n monitoring rollout status statefulset/kps-alertmanager --timeout=5m || true
kubectl -n monitoring rollout status deployment/kps-grafana --timeout=5m || true

echo "monitoring is up (Prometheus/Alertmanager/Grafana"