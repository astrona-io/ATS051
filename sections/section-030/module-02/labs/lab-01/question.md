---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Inhibit Warnings While A Critical Alert Fires

When a service is down, the on-call engineer gets a critical page and also a warning about slow requests for the same service. The warning adds noise. Configure Alertmanager so that a critical alert for a service silences the warnings of that service, and no other warnings.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-02-01" || exit 1
```

In the `starfleet` namespace Alertmanager runs as the `alertmanager` Deployment. It reads the ConfigMap `alertmanager-config`, which has one route and one receiver, `default`, that posts to the webhook `http://probe:8080/hooks`. Every alert carries the labels `alertname`, `severity` and `service`.

## Required result

Add an inhibition rule to the Alertmanager configuration. An alert with `severity="critical"` must inhibit alerts with `severity="warning"` that have the same value of the `service` label. Warnings of other services must stay active. Keep the existing route and receiver. Restart the Alertmanager Deployment so that it loads the new file.

## Verify the result

The grader sends three alerts to Alertmanager: a critical alert for service `probe`, a warning for service `probe` and a warning for service `other`. It then reads the alert states from the Alertmanager API. The warning for `probe` must be suppressed, and the other two must be active.
