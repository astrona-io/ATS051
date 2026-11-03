---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Guided Practice: Make An Alert Pending Then Firing

Use a host shell with the private kubeconfig for this module playground. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-020-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-playground-020-01" || exit 1
node_name="astro-ats-051-playground-020-01-control-plane"
worker_name="astro-ats-051-playground-020-01-worker"
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
  rules.yaml: "groups:\n- interval: 2s\n  name: lab\n  rules:\n  - alert: ProbeErrors\n\
    \    annotations:\n      summary: Probe requests are failing\n    expr: sum(rate(lab_requests_total{status=\"\
    500\"}[10s])) > 0\n    for: 4s\n    labels:\n      severity: warning\n"
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

Create a real alert rule and observe the transition to firing. The commands above deliberately target one environment. Keep its remaining components available so an unrelated failure cannot stand in for the required denial or correction. No example command output is presented as evidence of a completed run. A matching field alone does not establish that a process used it or that a controller reconciled it.


## Common pitfalls

> [!WARNING]
> Confirm the private context and exact node names before a change. Check the stated scope and live result. Do not change unrelated components to hide the original fault.

## Read The Result

After the Prometheus Deployment has restarted, read what Prometheus loaded and what it decided, in three separate reads. Each read answers a different question.

The rules API answers whether the rule was loaded and whether it evaluates. Look at the `health` field of the rule. A value of `ok` means the last evaluation finished without an error. The `lastError` field is empty on a healthy rule. The `evaluationTime` field is the duration of the last evaluation.

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/rules').read().decode())"
```

The alerts API answers what state the instance is in. During the first seconds after the condition becomes true, `state` is `pending`. After the `for` duration has passed without interruption it is `firing`. The `activeAt` field is the time the condition first became true, and it does not move while the instance stays continuously active.

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus:9090/api/v1/alerts').read().decode())"
```

The `ALERTS` series answers the same question from the query side. Querying `ALERTS{alertname="ProbeErrors"}` returns one series per instance with an `alertstate` label of `pending` or `firing`. Query it again after a few seconds to see the label change.

Compare three facts to decide whether the practice succeeded.

- The rule is present in the rules API with the name `ProbeErrors`.
- The `health` of the rule is `ok`.
- The alert is in the alerts API with `state` equal to `firing`.

If the rule is missing, the ConfigMap was not applied or Prometheus was not restarted. If the rule is present with a non-empty `lastError`, the expression failed to evaluate. If the rule is healthy but no alert exists, the expression returned an empty result, so check the selector against the metric labels. If the alert stays `pending`, the condition keeps stopping before the `for` duration ends.
