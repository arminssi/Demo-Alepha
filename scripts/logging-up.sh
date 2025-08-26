#!/usr/bin/env bash
set -Eeuo pipefail

##### add grafana repo
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

#### Loki / Promtail 
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring --create-namespace \
  --set grafana.enabled=false \
  --set promtail.enabled=true

# add Loki as a Grafana datasource
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-datasource
  namespace: monitoring
  labels:
    grafana_datasource: "1"
data:
  loki-datasource.yaml: |
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      access: proxy
      url: http://loki:3100
      isDefault: false
      jsonData:
        maxLines: 1000
YAML

# wait for pods
kubectl -n monitoring rollout status daemonset/loki-promtail --timeout=3m || true
kubectl -n monitoring rollout status statefulset/loki --timeout=3m || true

# restart grafana to pick datasource
kubectl -n monitoring rollout restart deploy kps-grafana

echo "logging ready."