# Infrastructure Engineer Challenge – Guestbook

Local Kubernetes stack with:
- Guestbook app (frontend, backend, MongoDB)
- Observability: Prometheus, Grafana, Alertmanager
- Logging: Loki + Promtail (logs in Grafana)
- Alerting: Prometheus rules → Alertmanager → PagerDuty (scripted)

This repo spins up a local kind cluster with the Guestbook app (frontend + backend + Mongo), plus monitoring, logging, and alerting.

---

## Prereqs
- Docker
- kind
- Helm v3
- kubectl configured

---

## 1) Kick off the cluster
```bash
./start-local.sh
# This creates the kind cluster, local registry, and ingress.

2) Build & deploy the app

TAG=$(date +%s) REGISTRY=localhost:5000 bash scripts/deploy.sh

Give it a few seconds, then open: http://localhost

⸻

3) Monitoring

Prometheus

kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090
# http://localhost:9090

Grafana

kubectl -n monitoring port-forward svc/kps-grafana 3000:80
# http://localhost:3000  (login: admin / prom-operator)


⸻

4) Logging

bash scripts/logging-up.sh
# Installs Loki + Promtail and wires Grafana to it.
# In Grafana → Explore → select "Loki" and run:

{namespace="guestbook"}


⸻

5) Alerts to PagerDuty

export PD_ROUTING_KEY=<your_key>   # generate this in the PagerDuty portal
bash scripts/alertmanager-pagerduty.sh

Trigger a test alert:

kubectl -n guestbook scale deploy/python-guestbook-backend --replicas=0
while true; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; sleep 2; done
# After a few minutes, you should see an incident in PagerDuty.
kubectl -n guestbook scale deploy/python-guestbook-backend --replicas=1


⸻

#What the scripts do

•start-local.sh
Spins up kind cluster, local registry (127.0.0.1:5000), connects them, and installs ingress-nginx (ports 80/443).

•scripts/deploy.sh
Builds frontend & backend images, tags to localhost:5000, pushes to local registry, applies k8s manifests (Deployments, Services, Ingress).

•scripts/monitoring-up.sh
Installs kube-prometheus-stack (Prometheus, Grafana, Alertmanager). Applies ServiceMonitors and PrometheusRules, and labels them so Prometheus scrapes them (release: kps).

•scripts/logging-up.sh
Installs Loki + Promtail and registers Loki as a Grafana datasource (via ConfigMap). Restarts Grafana so it picks up the datasource.

•scripts/alertmanager-pagerduty.sh
Creates/updates Alertmanager config (K8s Secret) with the PagerDuty Routing Key. Patches the Alertmanager CRD to use that secret and rolls Alertmanager.

•scripts/destroyall.sh
Deletes namespaces, the kind cluster, and the local registry container.

⸻

App health

kubectl -n guestbook get pods,svc,ingress
kubectl -n guestbook logs deploy/python-guestbook-frontend --tail=50
kubectl -n guestbook logs deploy/python-guestbook-backend  --tail=50

Port-forwards

# Prometheus / Grafana / Alertmanager
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090
kubectl -n monitoring port-forward svc/kps-grafana 3000:80
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-alertmanager 9093:9093


⸻

Making changes & redeploying

TAG=$(date +%s) REGISTRY=localhost:5000 bash scripts/deploy.sh
kubectl -n guestbook rollout status deploy/python-guestbook-frontend
kubectl -n guestbook rollout status deploy/python-guestbook-backend

