---
draft: true
exam_objectives:
- Dashboarding basics
---
# Dashboarding Basics Capstone

The team is building the overview dashboard for the `probe` service. The dashboard needs four panels: traffic, errors, duration and saturation. Each panel needs a query, a title and a unit.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-010-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-010-cap-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment exposes the counter `lab_requests_total` (label `status`), the histogram `lab_request_duration_seconds` and the gauge `lab_queue_depth`. A `traffic` Deployment sends it requests. Prometheus scrapes the probe every two seconds and is reachable from the `shuttle` pod as `http://prometheus:9090`.

## Required result

Write four PromQL expressions, one for each panel, and run each against the Prometheus HTTP API:

- Traffic: the request rate per second, split by `status`, over a 30 second window. Unit `requests/s`.
- Errors: the share of requests that fail, that is the rate of `status="500"` requests divided by the rate of all requests, over a 30 second window. Unit `ratio`.
- Duration: the 95th percentile request duration from the histogram buckets, over a 30 second window, aggregated by `le` only. Unit `seconds`.
- Saturation: the current queue depth. Unit `items`.

Save the results in the ConfigMap `evidence` in the `starfleet` namespace. The ConfigMap needs one key, `report.json`, with a JSON object that has one field, `panels`: a list of four objects. Each object has `title`, `unit`, `expression`, `evaluated_at` (the Unix timestamp you sent to the API) and `data` (the `data` object of the API response).

Wait at least 30 seconds after the environment starts. Submit within five minutes of recording the evidence.

## Verify the result

The grader reads the ConfigMap and runs every expression again at its recorded time. It compares the results, the expressions and the units.
