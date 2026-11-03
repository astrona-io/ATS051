---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Alerting Basics Capstone

Build the alert rule set for the `probe` service: one alert that proves the alerting pipeline works, one symptom alert on the error budget and one alert for a failing scrape. Every alert that pages a person needs a runbook.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-040-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-040-cap-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment serves the counter `lab_requests_total` with a `status` label. Prometheus scrapes it as job `probe` and reads its rules from the ConfigMap `prometheus-rules`, which holds an empty rule list. The success objective is 99.9 percent, so the error budget is 0.001.

## Required result

Add one rule group named `lab` with an evaluation interval of 2 seconds and three alerting rules:

- `Watchdog`: the expression `vector(1)`, so that it always fires. Label `severity="none"` and a `summary` annotation.
- `ErrorBudgetFastBurn`: the error ratio over a 30 second window and over a 10 second window must both be above 14.4 times the budget (14.4 * 0.001), joined with `and`.
- `ProbeDown`: fires when no scrape of job `probe` succeeds. Use `absent()` on `up{job="probe"} == 1`.

`ErrorBudgetFastBurn` and `ProbeDown` have `severity="page"`, a `summary` annotation, a `runbook_url` annotation that starts with `https://`, and a `for` duration of 10 seconds or less.

Restart the Prometheus Deployment so that it loads the new rule file, then wait until the alerts reach their expected states.

## Verify the result

The grader reads the rules from the Prometheus HTTP API. It expects `Watchdog` and `ErrorBudgetFastBurn` to be firing and `ProbeDown` to be inactive, because the probe is scraped successfully.
