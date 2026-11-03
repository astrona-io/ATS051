---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Configuring Alerting Rules Capstone Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-cap-01" || exit 1
```

## Design the group

Prometheus evaluates the rules of a group one after another, in file order. The alert reads the series that the recording rule writes, so the recording rule must come first. Otherwise the alert would read the value of the previous evaluation cycle. The name `service:lab_requests:rate10s` follows the convention level, metric and operations, separated by colons: the aggregation level is `service`, the metric is `lab_requests` and the operation is `rate10s`.

## Write the rules

Save this as `configmap-prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab
      interval: 2s
      rules:
      - record: service:lab_requests:rate10s
        expr: sum by (service, status) (rate(lab_requests_total[10s]))
      - alert: ProbeErrorRatioHigh
        expr: sum(service:lab_requests:rate10s{status="500"}) / sum(service:lab_requests:rate10s) > 0.05
        for: 4s
        labels:
          severity: critical
        annotations:
          summary: Probe error ratio is high
          description: 'Error ratio is {{ $value | humanizePercentage }} over 10 seconds'
```

Apply it and restart Prometheus:

```sh
kubectl apply -f configmap-prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
```

## Check the result

Wait about 25 seconds. Read the rules and the recorded series from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/rules').read().decode())"
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/query?query=service:lab_requests:rate10s').read().decode())"
```

Both rules report `"health":"ok"`, the series `service:lab_requests:rate10s` has one sample per `status` value, and the alert is `firing`.

## Common pitfalls

> [!WARNING]
> If the alert rule comes before the recording rule, it reads stale data. If the alert still reads `lab_requests_total`, it does not depend on the recorded series. Restart Prometheus after every change to the ConfigMap.
