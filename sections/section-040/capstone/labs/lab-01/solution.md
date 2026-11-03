---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Alerting Basics Capstone Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-040-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-040-cap-01" || exit 1
```

## Choose the three alerts

The Watchdog alert always fires. If Alertmanager or a receiver stops delivering it, a separate system notices that the signal is missing, so the whole pipeline is covered. The `ErrorBudgetFastBurn` alert is a symptom alert: it measures what users see (failed requests) and not a cause. The `ProbeDown` alert covers a different failure: when Prometheus cannot scrape the probe, no error ratio exists and the burn rate alert would stay silent. `absent()` returns a value only when its argument has no series, so it fires when no scrape of the probe is up.

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
      - alert: Watchdog
        expr: vector(1)
        labels:
          severity: none
        annotations:
          summary: The alerting pipeline is alive. This alert always fires.
      - alert: ErrorBudgetFastBurn
        expr: (sum(rate(lab_requests_total{status="500"}[30s])) / sum(rate(lab_requests_total[30s])) > 14.4 * 0.001) and (sum(rate(lab_requests_total{status="500"}[10s])) / sum(rate(lab_requests_total[10s])) > 14.4 * 0.001)
        for: 4s
        labels:
          severity: page
        annotations:
          summary: The probe burns its error budget 14.4 times too fast
          runbook_url: https://runbooks.example.com/probe-error-budget
      - alert: ProbeDown
        expr: absent(up{job="probe"} == 1)
        for: 10s
        labels:
          severity: page
        annotations:
          summary: Prometheus cannot scrape the probe
          runbook_url: https://runbooks.example.com/probe-down
```

Apply it and restart Prometheus:

```sh
kubectl apply -f configmap-prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
```

## Check the result

Wait about 40 seconds, then read the rules from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/rules').read().decode())"
```

`Watchdog` and `ErrorBudgetFastBurn` are `firing`. `ProbeDown` is `inactive`.

## Common pitfalls

> [!WARNING]
> `absent(up{job="probe"})` without `== 1` stays silent while the target exists but is down (the series `up` has the value 0). A rule without a runbook leaves the person who is paged without next steps.
