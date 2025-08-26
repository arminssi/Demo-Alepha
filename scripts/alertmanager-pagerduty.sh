#!/usr/bin/env bash
set -Eeuo pipefail
: "${PD_ROUTING_KEY:?set PD_ROUTING_KEY=<key>}"

cat > /tmp/alertmanager.yaml <<YAML
route:
  receiver: "pagerduty"
receivers:
- name: "pagerduty"
  pagerduty_configs:
  - routing_key: "${PD_ROUTING_KEY}"
    severity: '{{ if .CommonLabels.severity }}{{ .CommonLabels.severity }}{{ else }}critical{{ end }}'
inhibit_rules:
- source_matchers: [severity="critical"]
  target_matchers: [severity="warning"]
  equal: ["alertname","namespace","job"]
YAML

kubectl -n monitoring create secret generic kps-alertmanager-config \
  --from-file=alertmanager.yaml=/tmp/alertmanager.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n monitoring patch alertmanager kps-kube-prometheus-stack-alertmanager \
  --type merge -p '{"spec":{"configSecret":"kps-alertmanager-config"}}'

kubectl -n monitoring rollout status statefulset/alertmanager-kps-kube-prometheus-stack-alertmanager --timeout=2m
echo "Hey Armin, PagerDuty integration is ready!"