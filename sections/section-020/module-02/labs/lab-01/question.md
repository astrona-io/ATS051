---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Repair An Alert Rule That Never Fires

An alert rule named `ProbeErrorRatioHigh` was written to warn about failing requests. It has been loaded for a while and has never fired, although about one request in ten fails.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-02-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment serves the counter `lab_requests_total` with a `status` label. Prometheus runs as the `prometheus` Deployment and reads its rules from the ConfigMap `prometheus-rules`. The rule group `lab` holds the rule `ProbeErrorRatioHigh`.

## Required result

Repair the rule in the ConfigMap so that it works as intended:

- Keep the name `ProbeErrorRatioHigh` and the error ratio idea: failing requests divided by all requests, over 10 seconds, compared with 0.05.
- The alert must reach the `firing` state within a few seconds of the condition being true. The `for` duration must be 10 seconds or less.
- The `severity` label must be `critical`.
- The rule needs a `summary` annotation and a `description` annotation. The description must print the current value with the template variable `$value`.

Prometheus reads the ConfigMap as a mounted file. Restart the Prometheus Deployment so that it loads the new file, then wait until the alert fires.

## Verify the result

The grader reads the rules and alerts from the Prometheus HTTP API. It checks that the rule is healthy, that it is firing, and that the description template was expanded.
