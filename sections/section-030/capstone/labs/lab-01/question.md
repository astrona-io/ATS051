---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Alertmanager Capstone

Configure Alertmanager so that critical alerts page a dedicated receiver as one grouped notification, warnings go to the default receiver, and warnings are muted while a critical alert fires for the same service.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-cap-01" || exit 1
```

In the `starfleet` namespace Alertmanager runs as the `alertmanager` Deployment. It reads the ConfigMap `alertmanager-config`, which has one route and one receiver, `default`, that posts to the webhook `http://probe:8080/hooks`. Alerts carry the labels `alertname`, `severity`, `service` and `instance`.

## Required result

Edit the Alertmanager configuration:

- The root route sends to `default` and groups by `alertname` and `service`. Set `group_wait` to `0s` and `group_interval` to `2s` so that notifications leave quickly.
- A child route matches `severity="critical"` and sends to a new receiver named `pager`. The `pager` receiver is a webhook receiver for `http://probe:8080/hooks`.
- An inhibition rule lets `severity="critical"` alerts mute `severity="warning"` alerts that have the same `service`.

Restart the Alertmanager Deployment so that it loads the new file.

## Verify the result

The grader sends four alerts: two critical `ProbeDown` alerts for service `probe` (instances `a` and `b`), a warning `ProbeSlow` for service `probe` and a warning `ProbeSlow` for service `other`. It then reads the webhook notifications. It expects one `pager` notification with both critical alerts, no notification for the warning of service `probe`, and a `default` notification for the warning of service `other`.
