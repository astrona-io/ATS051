---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Evaluate A Recording Rule

Create a recording series from live request counters.

## Starting state

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-01-02)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-01-02" || exit 1
node_name="astro-ats-051-lab-020-01-02-control-plane"
worker_name="astro-ats-051-lab-020-01-02-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Required result

Create lab:request_rate and verify it is emitted by the rules engine, rather than submitting an unevaluated expression.

## Verify The Result

The grader checks the required object fields and actual observations. Wait for controller convergence before submitting. Preserve the task's namespace, workload names and unrelated components.
