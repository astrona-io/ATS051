---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Make An Alert Pending Then Firing Solution

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-01-01" || exit 1
node_name="astro-ats-051-lab-020-01-01-control-plane"
worker_name="astro-ats-051-lab-020-01-01-worker"
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

After recording your result, remove the independent lab with `astrona destroy ats-051-lab-020-01-01`.

## Common pitfalls

> [!WARNING]
> Confirm the private context and exact node names before a change. Check the stated scope and live result. Do not change unrelated components to hide the original fault.
