---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Configuring Alerting Rules Capstone

The team wants one rule group that records a reusable request rate and alerts on the error ratio built from it.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-020-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-020-cap-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment serves the counter `lab_requests_total` with the labels `service` and `status`. Prometheus reads its rules from the ConfigMap `prometheus-rules`, which holds an empty rule list.

## Required result

Write one rule group named `lab` with an evaluation interval of 2 seconds and two rules, in this order:

1. A recording rule named `service:lab_requests:rate10s`. Its expression is the per-second rate of `lab_requests_total` over 10 seconds, summed by `service` and `status`.
2. An alerting rule named `ProbeErrorRatioHigh`. It reads only the recorded series, not the raw counter. It computes the sum of the recorded series with `status="500"` divided by the sum of all recorded series, and fires when the result is above 0.05. The `for` duration is 10 seconds or less. The `severity` label is `critical`. It has a `summary` annotation.

Restart the Prometheus Deployment so that it loads the new rule file, then wait until the alert fires.

## Verify the result

The grader reads the rules from the Prometheus HTTP API. It checks both expressions, the rule order, the health of both rules, the recorded series and the state of the alert.
