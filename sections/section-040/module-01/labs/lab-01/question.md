---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Alert On Error Budget Consumption

Create an actionable alert from the stated population and success objective.

## Starting state

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-040-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-040-01-01" || exit 1
node_name="astro-ats-051-lab-040-01-01-control-plane"
worker_name="astro-ats-051-lab-040-01-01-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Required result

Replace the empty rule group with the declared rule. Restart Prometheus to consume the projected ConfigMap, then inspect the rules API. A syntactically correct rule must also evaluate successfully; an alert must finish its pending period.

## Verify The Result

The grader checks the required object fields and actual observations. Wait for controller convergence before submitting. Preserve the task's namespace, workload names and unrelated components.
