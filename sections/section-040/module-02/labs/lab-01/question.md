---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Write A Multi-Window Burn Rate Alert

The `probe` service has a success objective of 99.9 percent, so its error budget is 0.001 of all requests. The team wants a page when the service burns that budget 14.4 times faster than allowed, and not for a short blip.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-040-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-040-02-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment serves the counter `lab_requests_total` with a `status` label. Prometheus reads its rules from the ConfigMap `prometheus-rules`, which holds an empty rule list.

## Required result

Add a rule group named `lab` with an evaluation interval of 2 seconds. It holds one alerting rule named `ErrorBudgetFastBurn`:

- The expression compares the error ratio (rate of `status="500"` requests divided by the rate of all requests) with 14.4 times the budget, that is 14.4 * 0.001.
- It checks two windows and joins them with `and`: a long window of 30 seconds and a short window of 10 seconds. Both ratios must be above the threshold.
- The `for` duration is 10 seconds or less.
- The `severity` label is `page`.
- The annotations are `summary` and `runbook_url`. The runbook address starts with `https://`.

Restart the Prometheus Deployment so that it loads the new rule file, then wait until the alert fires.

## Verify the result

The grader reads the rule from the Prometheus HTTP API. It checks the windows, the `and`, the threshold, the labels, the annotations and the `firing` state.
