#start

This repo spins up a local kind cluster with the Guestbook app (frontend + backend + Mongo), plus monitoring, logging, and alerting.  

#Prereqs
- Docker
- kind
- helm

#Kick off the cluster
```bash
./start-local.sh

-----------
#This builds the frontend + backend images, pushes them into the local registry, and applies all manifests,

2. Build + deploy the app

TAG=$(date +%s) REGISTRY=localhost:5000 bash scripts/deploy.sh

#Give it a few seconds and then hit: http://localhost

---------------------------------
3. Monitoring

#Prometheus
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090
http://localhost:9090


#Grafana
kubectl -n monitoring port-forward svc/kps-grafana 3000:80
http://localhost:3000

---------------------------------
4. Logging

bash scripts/logging-up.sh

#This drops in Loki + Promtail and wires Grafana to it.
#Open Grafana → Explore → Loki and run
{namespace="guestbook"}

---------------------------------

5. Alerts to PagerDuty
#export PD_ROUTING_KEY=<your_key> ( key needs to be generated from the portal)
bash scripts/alertmanager-pagerduty.sh


#Trigger a test alert:

kubectl -n guestbook scale deploy/python-guestbook-backend --replicas=0
while true; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; sleep 2; done

#After a few minutes, you should see an incident in PagerDuty.
#Scale back when done:
kubectl -n guestbook scale deploy/python-guestbook-backend --replicas=1
