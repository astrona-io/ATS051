---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Guided Practice: Alert On Error Budget Consumption

Use a host shell with the private kubeconfig for this module playground. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-040-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-playground-040-01" || exit 1
node_name="astro-ats-051-playground-040-01-control-plane"
worker_name="astro-ats-051-playground-040-01-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Inspect And Explain

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Inspect the current objects before changing them:

```sh
kubectl -n starfleet get pods -o wide
kubectl get nodes -o wide
```

Replace the empty rule group with the declared rule. Restart Prometheus to consume the projected ConfigMap, then inspect the rules API. A syntactically correct rule must also evaluate successfully; an alert must finish its pending period.

Save this as `configmap-prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: "groups:\n- interval: 2s\n  name: lab\n  rules:\n  - alert: ErrorBudgetBurn\n\
    \    annotations:\n      summary: Failure ratio exceeds the one percent budget\n\
    \    expr: sum(rate(lab_requests_total{status=\"500\"}[10s])) / sum(rate(lab_requests_total[10s]))\n\
    \      > 0.01\n    for: 4s\n    labels:\n      severity: page\n"
```

Apply the scoped correction:

```sh
kubectl apply -f configmap-prometheus-rules.yaml
kubectl -n starfleet rollout restart deployment/prometheus
```

## Verify The Result

Observe the actual result. A denied request returns a nonzero status when the denial works, so run it separately from a shell sequence that stops on error. Status convergence and a successful request establish different parts of the result.

```sh
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
sleep 20
```

Create an actionable alert from the stated population and success objective. The commands above deliberately target one environment. Keep its remaining components available so an unrelated failure cannot stand in for the required denial or correction. No example command output is presented as evidence of a completed run. A matching field alone does not establish that a process used it or that a controller reconciled it.


## Common pitfalls

> [!WARNING]
> Confirm the private context and exact node names before a change. Check the stated scope and live result. Do not change unrelated components to hide the original fault.

## Read The Result

After the restart finishes, wait for at least two evaluation intervals and read the rule state from the Prometheus HTTP API. The `shuttle` pod can reach the Prometheus Service:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus.starfleet.svc:9090/api/v1/rules').read().decode())"
```

Find the rule `ErrorBudgetBurn` in the JSON. Read three fields: `health`, which must be `ok` for a rule that evaluates without error; `state`, which is `pending` while the condition has held for less than the `for` duration and `firing` afterwards; and `labels`, which must include `severity` with the value `page`.

If `health` is not `ok`, the field `lastError` holds the reason. If the rule is missing, the ConfigMap was not loaded: check that the Prometheus pod restarted after the apply. The traffic generator fails every tenth request, so the error ratio stays near 0.1 and the rule should reach `firing`.

Now state, in your own words, the symptom, the population, the owner and the expected action for this alert. If you cannot name the action, the alert is not ready to page.

## Check The Burn Rate By Hand

Query the error ratio once more and divide it by the budget of 0.001. The result is the current burn rate. The rule threshold is 0.01, which is a burn rate of 10. Compare the two numbers: the ratio produced by the traffic generator should be well above the threshold, which is why the alert fires.

Then think about what would change if the SLO target were 99 percent. The budget would be 0.01, the same ratio would give a burn rate of about 10 instead of about 100, and the threshold of 0.01 would mean a burn rate of 1. The same expression would then describe a much milder situation. This is why a threshold is written from the SLO, not copied between services.
