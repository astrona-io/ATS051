---
draft: true
exam_objectives:
- Dashboarding basics
---
# Build A Latency Panel Query

The on-call team needs a latency panel for the `probe` service. The panel must show the 95th percentile request duration in seconds, across all replicas.

## Starting state

The environment is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. Select its private kubeconfig first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-010-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-010-02-01" || exit 1
```

In the `starfleet` namespace the `probe` Deployment exposes the histogram `lab_request_duration_seconds`. A `traffic` Deployment sends requests to it. Prometheus scrapes the probe every two seconds and is reachable from the `shuttle` pod as `http://prometheus:9090`.

## Required result

Write one PromQL expression that returns the 95th percentile of `lab_request_duration_seconds`. Use the per-second rate of the histogram buckets over a 30 second window. Aggregate with `sum by (le)` so that only the `le` label remains.

Run the expression against the Prometheus HTTP API and save the result in the ConfigMap `evidence` in the `starfleet` namespace. The ConfigMap needs one key, `report.json`, with a JSON object that has these fields:

- `title`: a short panel title.
- `unit`: the unit of the value. Use `seconds`.
- `expression`: the PromQL expression you ran.
- `evaluated_at`: the evaluation time you sent to the API, as a Unix timestamp.
- `data`: the `data` object of the API response, not only the printed value.

Wait at least 30 seconds after the environment starts so that the 30 second window holds data. Submit within five minutes of recording the evidence.

## Verify the result

The grader reads the ConfigMap, runs your expression again at your `evaluated_at` time and compares the two results. It also checks the expression and the unit.
