---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Suppress An Alert With A Matching Silence

Verify real Alertmanager routing and matching suppression.

## Starting state

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-01-03)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-01-03" || exit 1
node_name="astro-ats-051-lab-030-01-03-control-plane"
worker_name="astro-ats-051-lab-030-01-03-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Required result

Configure the warning route and a real webhook receiver. Submit a fixture alert directly to Alertmanager, then inspect receiver observations. Create a ten-minute silence matching alertname=ProbeErrors and verify silencedBy on the live alert. This exercises Alertmanager independently; Prometheus rule evaluation is covered by the other labs.

## Verify The Result

The grader checks the required object fields and actual observations. Wait for controller convergence before submitting. Preserve the task's namespace, workload names and unrelated components.
