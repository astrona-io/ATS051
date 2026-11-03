---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Repair An Alert Rule That Never Fires Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-02-01" || exit 1
```

## Find the fault

Read the rule as Prometheus sees it. The rules API lists every rule with its health, its query and its state.

```sh
kubectl -n starfleet get configmap prometheus-rules -o jsonpath='{.data.rules\.yaml}'
```

The expression selects `status="5xx"`. The probe only exposes the values `200` and `500`, so the selector matches no series. The numerator is empty, the whole expression is empty and the condition is never true. The rule is healthy because an empty result is not an error. The `for: 1h` setting would also keep the alert in the pending state for an hour even after the selector is fixed.

## Fix the rule

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
      - alert: ProbeErrorRatioHigh
        expr: sum(rate(lab_requests_total{status="500"}[10s])) / sum(rate(lab_requests_total[10s])) > 0.05
        for: 4s
        labels:
          severity: critical
        annotations:
          summary: Probe error ratio is high
          description: 'Error ratio is {{ $value | humanizePercentage }} over 10 seconds'
```

Apply it and restart Prometheus so that it reads the new file:

```sh
kubectl apply -f configmap-prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
```

## Check the result

Wait about 20 seconds, then read the rule state from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/alerts').read().decode())"
```

The alert `ProbeErrorRatioHigh` has the state `firing`, and its description shows a percentage instead of the text `{{ $value }}`.

## Common pitfalls

> [!WARNING]
> Prometheus does not re-read a mounted ConfigMap file until it reloads. Restart the Deployment, or the old rule stays loaded. A long `for` duration hides a correct expression for that whole time.
