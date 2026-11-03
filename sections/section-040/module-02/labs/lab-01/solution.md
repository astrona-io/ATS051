---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Write A Multi-Window Burn Rate Alert Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-040-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-040-02-01" || exit 1
```

## Work out the threshold

A success objective of 99.9 percent allows 0.1 percent failing requests, so the error budget is 0.001. A burn rate is the observed error ratio divided by the budget. A burn rate of 14.4 means the ratio is 14.4 times 0.001, that is 0.0144. The probe fails about 10 percent of its requests, so its burn rate is about 100 and the alert condition is true.

The long window (30 seconds) shows that the burn is sustained. The short window (10 seconds) shows that it is still happening now. The alert fires only when both are above the threshold, so it stops soon after the errors stop.

## Write the rule

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
      - alert: ErrorBudgetFastBurn
        expr: (sum(rate(lab_requests_total{status="500"}[30s])) / sum(rate(lab_requests_total[30s])) > 14.4 * 0.001) and (sum(rate(lab_requests_total{status="500"}[10s])) / sum(rate(lab_requests_total[10s])) > 14.4 * 0.001)
        for: 4s
        labels:
          severity: page
        annotations:
          summary: The probe burns its error budget 14.4 times too fast
          runbook_url: https://runbooks.example.com/probe-error-budget
```

Apply it and restart Prometheus:

```sh
kubectl apply -f configmap-prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
```

## Check the result

Wait about 40 seconds, then read the alerts from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/alerts').read().decode())"
```

The alert `ErrorBudgetFastBurn` has the state `firing` and carries the label `severity="page"` and the `runbook_url` annotation.

## Common pitfalls

> [!WARNING]
> Use the same threshold on both windows. Parentheses around each comparison make the condition easier to read, although `and` already binds less tightly than a comparison. A budget of 0.01 instead of 0.001 makes the threshold ten times too high.
